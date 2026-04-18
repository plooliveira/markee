import 'package:flutter/widgets.dart';
import 'package:markee/src/markdown/editable_region.dart';
import 'package:markee/src/markdown/inline_preview_parser.dart';
import 'package:markee/src/markdown/markdown_document.dart';
import 'package:markee/src/markdown/span_builder.dart';

class MarkdownEditingController extends TextEditingController {
  MarkdownEditingController({super.text}) {
    _document = MarkdownDocument.fromText(text);
  }

  final MarkdownInlinePreviewParser _previewParser = const MarkdownInlinePreviewParser();
  final MarkdownSpanBuilder _spanBuilder = const MarkdownSpanBuilder();
  final Map<int, _CachedPreviewLine> _previewCache = {};

  late MarkdownDocument _document;
  int _debugPreviewParseCount = 0;

  @visibleForTesting
  int get debugPreviewParseCount => _debugPreviewParseCount;

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
        if (editableRegion.containsLine(line.index)) {
          return TextSpan(text: line.rawText, style: effectiveStyle);
        }
        return _buildPreviewLine(line: line, baseStyle: effectiveStyle);
      }).toList(growable: false),
    );
  }

  TextSpan _buildPreviewLine({
    required MarkdownLine line,
    required TextStyle baseStyle,
  }) {
    final cacheKey = line.index;
    final fingerprint =
        '${line.rawText}|${line.codeBlock?.startLine ?? -1}|${line.codeBlock?.endLine ?? -1}|${line.isFence}';
    final cachedLine = _previewCache[cacheKey];
    if (cachedLine != null && cachedLine.fingerprint == fingerprint) {
      return cachedLine.span;
    }

    final parsedLine = _previewParser.parseLine(line);
    final span = _spanBuilder.buildLine(line: parsedLine, baseStyle: baseStyle);
    _previewCache[cacheKey] = _CachedPreviewLine(
      fingerprint: fingerprint,
      span: span,
    );
    _debugPreviewParseCount++;
    return span;
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
}

class _CachedPreviewLine {
  const _CachedPreviewLine({
    required this.fingerprint,
    required this.span,
  });

  final String fingerprint;
  final TextSpan span;
}
