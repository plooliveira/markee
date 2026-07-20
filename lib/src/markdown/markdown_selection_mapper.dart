import 'package:flutter/widgets.dart';
import 'package:markee/src/markdown/inline_preview_parser.dart';
import 'package:markee/src/markdown/markdown_document.dart';
import 'package:markee/src/markdown/markdown_edit_policy.dart';

class MarkdownSelectionMapper {
  const MarkdownSelectionMapper({
    this.policyResolver = const MarkdownEditPolicyResolver(),
  });

  final MarkdownEditPolicyResolver policyResolver;

  TextEditingValue adjustSelectionForPreviewReveal({
    required MarkdownDocument document,
    required TextEditingValue previousValue,
    required TextEditingValue nextValue,
    required MarkdownPreviewLine parsedLine,
    required MarkdownLine line,
  }) {
    if (previousValue.text != nextValue.text || !nextValue.selection.isCollapsed) {
      return nextValue;
    }

    if (previousValue.selection == nextValue.selection) {
      return nextValue;
    }

    final previousChunk = policyResolver.activeInlineChunkForLine(
      document: document,
      line: line,
      parsedLine: parsedLine,
      selection: previousValue.selection,
    );
    final nextChunk = policyResolver.activeInlineChunkForLine(
      document: document,
      line: line,
      parsedLine: parsedLine,
      selection: nextValue.selection,
    );

    if (nextChunk == null || identical(nextChunk, previousChunk)) {
      return nextValue;
    }

    final adjustedOffset = nextValue.selection.extentOffset + nextChunk.leadingHiddenTextLength;
    return nextValue.copyWith(
      selection: TextSelection.collapsed(
        offset: adjustedOffset.clamp(nextChunk.rawStart, nextChunk.rawEnd),
      ),
    );
  }
}
