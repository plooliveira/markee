import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:markee/src/markdown/markdown_document.dart';

class MarkdownEditableRegion {
  const MarkdownEditableRegion({
    required this.startLine,
    required this.endLine,
  });

  const MarkdownEditableRegion.empty() : startLine = 1, endLine = 0;

  final int startLine;
  final int endLine;

  bool containsLine(int lineIndex) {
    return lineIndex >= startLine && lineIndex <= endLine;
  }
}

class EditableRegionResolver {
  const EditableRegionResolver._();

  static MarkdownEditableRegion resolve({
    required MarkdownDocument document,
    required TextSelection selection,
    TextRange? composing,
  }) {
    if (document.lines.isEmpty) {
      return const MarkdownEditableRegion.empty();
    }

    final normalizedSelection = selection.isNormalized
        ? selection
        : TextSelection(
            baseOffset: math.min(selection.baseOffset, selection.extentOffset),
            extentOffset: math.max(selection.baseOffset, selection.extentOffset),
          );

    var startLine = document.lineIndexForOffset(normalizedSelection.start);
    final selectionEndOffset = normalizedSelection.isCollapsed
        ? normalizedSelection.end
        : math.max(normalizedSelection.end - 1, normalizedSelection.start);
    var endLine = document.lineIndexForOffset(selectionEndOffset);

    if (composing != null && composing.isValid && !composing.isCollapsed) {
      startLine = math.min(startLine, document.lineIndexForOffset(composing.start));
      endLine = math.max(
        endLine,
        document.lineIndexForOffset(math.max(composing.end - 1, composing.start)),
      );
    }

    for (var lineIndex = startLine; lineIndex <= endLine; lineIndex++) {
      final block = document.lineAt(lineIndex).codeBlock;
      if (block == null) {
        continue;
      }
      startLine = math.min(startLine, block.startLine);
      endLine = math.max(endLine, block.endLine);
    }

    return MarkdownEditableRegion(startLine: startLine, endLine: endLine);
  }
}
