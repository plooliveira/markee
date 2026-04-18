import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:markee/src/markdown/editable_region.dart';
import 'package:markee/src/markdown/inline_preview_parser.dart';
import 'package:markee/src/markdown/markdown_document.dart';
import 'package:markee/src/markdown/span_builder.dart';
import 'package:url_launcher/url_launcher.dart';

typedef MarkdownLinkOpener = Future<bool> Function(Uri uri);

class MarkdownEditingController extends TextEditingController {
  MarkdownEditingController({
    super.text,
    MarkdownLinkOpener? onOpenLink,
  }) : _onOpenLink = onOpenLink ?? _defaultOpenLink {
    _document = MarkdownDocument.fromText(text);
    _previewLinksEnabled = _computePreviewLinksEnabled();
    HardwareKeyboard.instance.addHandler(_handleHardwareKeyEvent);
  }

  final MarkdownInlinePreviewParser _previewParser = const MarkdownInlinePreviewParser();
  final MarkdownSpanBuilder _spanBuilder = const MarkdownSpanBuilder();
  final Map<int, _CachedPreviewLine> _previewCache = {};
  final Map<String, TapGestureRecognizer> _linkRecognizers = {};
  final MarkdownLinkOpener _onOpenLink;

  late MarkdownDocument _document;
  int _debugPreviewParseCount = 0;
  bool _previewLinksEnabled = false;

  @visibleForTesting
  int get debugPreviewParseCount => _debugPreviewParseCount;

  @visibleForTesting
  bool get debugPreviewLinksEnabled => _previewLinksEnabled;

  @visibleForTesting
  void debugSetPreviewLinksEnabled(bool enabled) {
    _setPreviewLinksEnabled(enabled);
  }

  @override
  set value(TextEditingValue newValue) {
    final previousValue = value;
    super.value = newValue;

    if (previousValue.text == newValue.text) {
      return;
    }

    _invalidateForTextChange(previousValue.text, newValue.text);
    _document = MarkdownDocument.fromText(newValue.text);
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (_document.text != value.text) {
      _document = MarkdownDocument.fromText(value.text);
      _previewCache.clear();
    }

    final effectiveStyle = style ?? const TextStyle();
    final editableRegion = EditableRegionResolver.resolve(
      document: _document,
      selection: value.selection,
      composing: withComposing ? value.composing : null,
    );

    if (_document.lines.length == 1 && _document.lines.first.rawText.isEmpty) {
      return TextSpan(style: effectiveStyle, text: '');
    }

    return TextSpan(
      style: effectiveStyle,
      children: _document.lines.map((line) {
        final parsedLine = _parsedLineFor(line);
        if (editableRegion.containsLine(line.index) ||
            _shouldRevealWholeLine(line: line, parsedLine: parsedLine)) {
          return TextSpan(text: line.rawText, style: effectiveStyle);
        }
        return _buildPreviewLine(
          line: line,
          parsedLine: parsedLine,
          baseStyle: effectiveStyle,
        );
      }).toList(growable: false),
    );
  }

  TextSpan _buildPreviewLine({
    required MarkdownLine line,
    required MarkdownPreviewLine parsedLine,
    required TextStyle baseStyle,
  }) {
    final revealedChunk = _revealedInlineChunkFor(
      line: line,
      parsedLine: parsedLine,
    );
    final span = _spanBuilder.buildLine(
      line: parsedLine,
      baseStyle: baseStyle,
      linksEnabled: _previewLinksEnabled,
      revealedChunk: revealedChunk,
      linkRecognizerBuilder: _linkRecognizerForUrl,
    );
    return span;
  }

  MarkdownPreviewLine _parsedLineFor(MarkdownLine line) {
    final cacheKey = line.index;
    final fingerprint =
        '${line.rawText}|${line.codeBlock?.startLine ?? -1}|${line.codeBlock?.endLine ?? -1}|${line.isFence}';
    final cachedLine = _previewCache[cacheKey];
    if (cachedLine != null && cachedLine.fingerprint == fingerprint) {
      return cachedLine.parsedLine;
    }

    final parsedLine = _previewParser.parseLine(line);
    _previewCache[cacheKey] = _CachedPreviewLine(
      fingerprint: fingerprint,
      parsedLine: parsedLine,
    );
    _debugPreviewParseCount++;
    return parsedLine;
  }

  bool _shouldRevealWholeLine({
    required MarkdownLine line,
    required MarkdownPreviewLine parsedLine,
  }) {
    if (!value.selection.isCollapsed) {
      return false;
    }

    final currentLineIndex = _document.lineIndexForOffset(value.selection.extentOffset);
    if (currentLineIndex != line.index) {
      return false;
    }

    return parsedLine.type == MarkdownLineType.heading;
  }

  MarkdownPreviewChunk? _revealedInlineChunkFor({
    required MarkdownLine line,
    required MarkdownPreviewLine parsedLine,
  }) {
    if (!value.selection.isCollapsed) {
      return null;
    }

    final currentLineIndex = _document.lineIndexForOffset(value.selection.extentOffset);
    if (currentLineIndex != line.index) {
      return null;
    }

    if (parsedLine.type == MarkdownLineType.heading) {
      return null;
    }

    final localOffset =
        (value.selection.extentOffset - line.startOffset).clamp(0, line.content.length);

    for (final chunk in parsedLine.chunks) {
      if (chunk.isEditable && chunk.containsOffset(localOffset)) {
        return chunk;
      }
    }

    return null;
  }

  void _invalidateForTextChange(String oldText, String newText) {
    final oldDocument = MarkdownDocument.fromText(oldText);
    final newDocument = MarkdownDocument.fromText(newText);
    final prefixLength = _commonPrefixLineCount(oldDocument, newDocument);
    final suffixLength = _commonSuffixLineCount(
      oldDocument,
      newDocument,
      prefixLength: prefixLength,
    );

    final oldChangedCount = oldDocument.lineCount - prefixLength - suffixLength;
    final newChangedCount = newDocument.lineCount - prefixLength - suffixLength;

    if (oldChangedCount > 0 || newChangedCount > 0) {
      for (var lineIndex = prefixLength;
          lineIndex < newDocument.lineCount - suffixLength;
          lineIndex++) {
        _previewCache.remove(lineIndex);
      }
    }

    if (oldDocument.lineCount != newDocument.lineCount) {
      for (var lineIndex = prefixLength; lineIndex < oldDocument.lineCount; lineIndex++) {
        _previewCache.remove(lineIndex);
      }
      return;
    }

    final comparableCount = oldDocument.lineCount;
    for (var lineIndex = 0; lineIndex < comparableCount; lineIndex++) {
      final oldLine = oldDocument.lineAt(lineIndex);
      final newLine = newDocument.lineAt(lineIndex);
      final oldBlock = oldLine.codeBlock;
      final newBlock = newLine.codeBlock;
      if (oldBlock?.startLine != newBlock?.startLine ||
          oldBlock?.endLine != newBlock?.endLine ||
          oldLine.isFence != newLine.isFence) {
        _previewCache.remove(lineIndex);
      }
    }
  }

  int _commonPrefixLineCount(MarkdownDocument oldDocument, MarkdownDocument newDocument) {
    final limit = oldDocument.lineCount < newDocument.lineCount
        ? oldDocument.lineCount
        : newDocument.lineCount;
    var index = 0;
    while (index < limit) {
      if (oldDocument.lineAt(index).rawText != newDocument.lineAt(index).rawText) {
        break;
      }
      index++;
    }
    return index;
  }

  int _commonSuffixLineCount(
    MarkdownDocument oldDocument,
    MarkdownDocument newDocument, {
    required int prefixLength,
  }) {
    final oldRemaining = oldDocument.lineCount - prefixLength;
    final newRemaining = newDocument.lineCount - prefixLength;
    final limit = oldRemaining < newRemaining ? oldRemaining : newRemaining;
    var index = 0;

    while (index < limit) {
      final oldLine = oldDocument.lineAt(oldDocument.lineCount - index - 1);
      final newLine = newDocument.lineAt(newDocument.lineCount - index - 1);
      if (oldLine.rawText != newLine.rawText) {
        break;
      }
      index++;
    }

    return index;
  }

  TapGestureRecognizer _linkRecognizerForUrl(String url) {
    return _linkRecognizers.putIfAbsent(url, () {
      return TapGestureRecognizer()
        ..onTap = () {
          final uri = Uri.tryParse(url);
          if (uri == null) {
            return;
          }
          unawaited(_onOpenLink(uri));
        };
    });
  }

  static Future<bool> _defaultOpenLink(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  bool _handleHardwareKeyEvent(KeyEvent event) {
    _setPreviewLinksEnabled(_computePreviewLinksEnabled());
    return false;
  }

  bool _computePreviewLinksEnabled() {
    final hardwareKeyboard = HardwareKeyboard.instance;
    return hardwareKeyboard.isControlPressed || hardwareKeyboard.isMetaPressed;
  }

  void _setPreviewLinksEnabled(bool enabled) {
    if (_previewLinksEnabled == enabled) {
      return;
    }
    _previewLinksEnabled = enabled;
    _previewCache.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleHardwareKeyEvent);
    for (final recognizer in _linkRecognizers.values) {
      recognizer.dispose();
    }
    _linkRecognizers.clear();
    super.dispose();
  }
}

class _CachedPreviewLine {
  const _CachedPreviewLine({
    required this.fingerprint,
    required this.parsedLine,
  });

  final String fingerprint;
  final MarkdownPreviewLine parsedLine;
}
