import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:markee/src/markdown/inline_preview_parser.dart';
import 'package:markee/src/markdown/markdown_document.dart';
import 'package:markee/src/markdown/markdown_edit_policy.dart';
import 'package:markee/src/markdown/span_builder.dart';

class MarkdownPreviewEngine {
  MarkdownPreviewEngine({
    MarkdownInlinePreviewParser parser = const MarkdownInlinePreviewParser(),
    MarkdownSpanBuilder spanBuilder = const MarkdownSpanBuilder(),
    MarkdownEditPolicyResolver policyResolver = const MarkdownEditPolicyResolver(),
  }) : _parser = parser,
       _spanBuilder = spanBuilder,
       _policyResolver = policyResolver;

  final MarkdownInlinePreviewParser _parser;
  final MarkdownSpanBuilder _spanBuilder;
  final MarkdownEditPolicyResolver _policyResolver;
  final Map<int, _CachedPreviewLine> _previewCache = {};

  int _debugPreviewParseCount = 0;

  int get debugPreviewParseCount => _debugPreviewParseCount;

  TextSpan buildTextSpan({
    required MarkdownDocument document,
    required TextEditingValue value,
    required TextStyle baseStyle,
    required bool withComposing,
    required bool linksEnabled,
    GestureRecognizer? Function(String url)? linkRecognizerBuilder,
  }) {
    if (document.lines.length == 1 && document.lines.first.rawText.isEmpty) {
      return TextSpan(style: baseStyle, text: '');
    }

    final composing = withComposing ? value.composing : null;
    return TextSpan(
      style: baseStyle,
      children: document.lines.map((line) {
        final parsedLine = parsedLineFor(line);
        final decision = _policyResolver.resolveLineDecision(
          document: document,
          line: line,
          parsedLine: parsedLine,
          selection: value.selection,
          composing: composing,
        );

        if (decision.policy == MarkdownEditPolicy.revealWholeLine ||
            decision.policy == MarkdownEditPolicy.revealWholeBlock) {
          return TextSpan(text: line.rawText, style: baseStyle);
        }

        return _spanBuilder.buildLine(
          line: parsedLine,
          baseStyle: baseStyle,
          linksEnabled: linksEnabled,
          revealedChunk: decision.revealedChunk,
          linkRecognizerBuilder: linkRecognizerBuilder,
        );
      }).toList(growable: false),
    );
  }

  MarkdownPreviewLine parsedLineFor(MarkdownLine line) {
    final cacheKey = line.index;
    final fingerprint = MarkdownParsedLineCacheKey(
      rawText: line.rawText,
      codeBlockStartLine: line.codeBlock?.startLine,
      codeBlockEndLine: line.codeBlock?.endLine,
      isFence: line.isFence,
    );
    final cachedLine = _previewCache[cacheKey];
    if (cachedLine != null && cachedLine.fingerprint == fingerprint) {
      return cachedLine.parsedLine;
    }

    final parsedLine = _parser.parseLine(line);
    _previewCache[cacheKey] = _CachedPreviewLine(
      fingerprint: fingerprint,
      parsedLine: parsedLine,
    );
    _debugPreviewParseCount++;
    return parsedLine;
  }

  void invalidateForTextChange(String oldText, String newText) {
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

  void clearCache() {
    _previewCache.clear();
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

class MarkdownParsedLineCacheKey {
  const MarkdownParsedLineCacheKey({
    required this.rawText,
    required this.codeBlockStartLine,
    required this.codeBlockEndLine,
    required this.isFence,
  });

  final String rawText;
  final int? codeBlockStartLine;
  final int? codeBlockEndLine;
  final bool isFence;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is MarkdownParsedLineCacheKey &&
        other.rawText == rawText &&
        other.codeBlockStartLine == codeBlockStartLine &&
        other.codeBlockEndLine == codeBlockEndLine &&
        other.isFence == isFence;
  }

  @override
  int get hashCode => Object.hash(
    rawText,
    codeBlockStartLine,
    codeBlockEndLine,
    isFence,
  );
}

class _CachedPreviewLine {
  const _CachedPreviewLine({
    required this.fingerprint,
    required this.parsedLine,
  });

  final MarkdownParsedLineCacheKey fingerprint;
  final MarkdownPreviewLine parsedLine;
}
