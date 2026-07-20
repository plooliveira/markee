import 'package:flutter/widgets.dart';
import 'package:markee/src/markdown/editable_region.dart';
import 'package:markee/src/markdown/inline_preview_parser.dart';
import 'package:markee/src/markdown/markdown_document.dart';

enum MarkdownEditPolicy {
  preservePreview,
  revealWholeLine,
  revealActiveInlineChunk,
  revealWholeBlock,
}

class MarkdownLineEditDecision {
  const MarkdownLineEditDecision({
    required this.policy,
    this.revealedChunk,
  });

  final MarkdownEditPolicy policy;
  final MarkdownPreviewChunk? revealedChunk;
}

class MarkdownEditPolicyResolver {
  const MarkdownEditPolicyResolver();

  MarkdownLineEditDecision resolveLineDecision({
    required MarkdownDocument document,
    required MarkdownLine line,
    required MarkdownPreviewLine parsedLine,
    required TextSelection selection,
    TextRange? composing,
  }) {
    final editableRegion = EditableRegionResolver.resolve(
      document: document,
      selection: selection,
      composing: composing,
    );

    if (editableRegion.containsLine(line.index)) {
      return MarkdownLineEditDecision(
        policy: line.isInsideCodeBlock
            ? MarkdownEditPolicy.revealWholeBlock
            : MarkdownEditPolicy.revealWholeLine,
      );
    }

    if (!selection.isCollapsed) {
      return const MarkdownLineEditDecision(
        policy: MarkdownEditPolicy.preservePreview,
      );
    }

    final currentLineIndex = document.lineIndexForOffset(selection.extentOffset);
    if (currentLineIndex != line.index) {
      return const MarkdownLineEditDecision(
        policy: MarkdownEditPolicy.preservePreview,
      );
    }

    if (parsedLine.type == MarkdownLineType.heading) {
      return const MarkdownLineEditDecision(
        policy: MarkdownEditPolicy.revealWholeLine,
      );
    }

    final revealedChunk = activeInlineChunkForLine(
      document: document,
      line: line,
      parsedLine: parsedLine,
      selection: selection,
    );
    if (revealedChunk != null) {
      return MarkdownLineEditDecision(
        policy: MarkdownEditPolicy.revealActiveInlineChunk,
        revealedChunk: revealedChunk,
      );
    }

    return const MarkdownLineEditDecision(
      policy: MarkdownEditPolicy.preservePreview,
    );
  }

  MarkdownPreviewChunk? activeInlineChunkForLine({
    required MarkdownDocument document,
    required MarkdownLine line,
    required MarkdownPreviewLine parsedLine,
    required TextSelection selection,
  }) {
    if (!selection.isCollapsed || line.isInsideCodeBlock) {
      return null;
    }

    final currentLineIndex = document.lineIndexForOffset(selection.extentOffset);
    if (currentLineIndex != line.index || parsedLine.type == MarkdownLineType.heading) {
      return null;
    }

    final localOffset =
        (selection.extentOffset - line.startOffset).clamp(0, line.content.length);

    for (final chunk in parsedLine.chunks) {
      if (chunk.isEditable && chunk.containsOffset(localOffset)) {
        return chunk;
      }
    }

    return null;
  }
}
