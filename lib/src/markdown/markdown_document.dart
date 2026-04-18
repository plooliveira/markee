class MarkdownDocument {
  MarkdownDocument._({required this.text, required this.lines});

  factory MarkdownDocument.fromText(String text) {
    final lines = <MarkdownLine>[];
    var offset = 0;
    var index = 0;

    if (text.isEmpty) {
      lines.add(
        MarkdownLine(
          index: 0,
          startOffset: 0,
          endOffset: 0,
          rawText: '',
          content: '',
          hasTrailingNewline: false,
        ),
      );
      return MarkdownDocument._(text: text, lines: lines);
    }

    var lineStart = 0;
    for (var i = 0; i < text.length; i++) {
      if (text.codeUnitAt(i) != 10) {
        continue;
      }

      final rawText = text.substring(lineStart, i + 1);
      lines.add(
        MarkdownLine(
          index: index,
          startOffset: offset,
          endOffset: offset + rawText.length,
          rawText: rawText,
          content: rawText.substring(0, rawText.length - 1),
          hasTrailingNewline: true,
        ),
      );
      offset += rawText.length;
      lineStart = i + 1;
      index++;
    }

    if (lineStart <= text.length - 1) {
      final rawText = text.substring(lineStart);
      lines.add(
        MarkdownLine(
          index: index,
          startOffset: offset,
          endOffset: offset + rawText.length,
          rawText: rawText,
          content: rawText,
          hasTrailingNewline: false,
        ),
      );
    } else {
      lines.add(
        MarkdownLine(
          index: index,
          startOffset: offset,
          endOffset: offset,
          rawText: '',
          content: '',
          hasTrailingNewline: false,
        ),
      );
    }

    _assignCodeBlocks(lines);
    return MarkdownDocument._(text: text, lines: lines);
  }

  final String text;
  final List<MarkdownLine> lines;

  MarkdownLine lineAt(int index) => lines[index];

  int get lineCount => lines.length;

  int lineIndexForOffset(int offset) {
    if (lines.isEmpty) {
      return 0;
    }

    final clampedOffset = offset.clamp(0, text.length);
    for (final line in lines) {
      if (clampedOffset < line.endOffset) {
        return line.index;
      }
    }
    return lines.last.index;
  }

  static void _assignCodeBlocks(List<MarkdownLine> lines) {
    MarkdownCodeBlock? currentBlock;
    var nextCodeBlockId = 0;

    for (final line in lines) {
      if (_isFence(line.content)) {
        if (currentBlock == null) {
          currentBlock = MarkdownCodeBlock(
            id: nextCodeBlockId++,
            startLine: line.index,
            endLine: line.index,
          );
          line.codeBlock = currentBlock;
          line.isFence = true;
          continue;
        }

        currentBlock = currentBlock.copyWith(endLine: line.index);
        line.codeBlock = currentBlock;
        line.isFence = true;
        for (var i = currentBlock.startLine; i <= currentBlock.endLine; i++) {
          lines[i].codeBlock = currentBlock;
        }
        currentBlock = null;
        continue;
      }

      if (currentBlock != null) {
        line.codeBlock = currentBlock;
      }
    }

    if (currentBlock != null) {
      for (var i = currentBlock.startLine; i < lines.length; i++) {
        final line = lines[i];
        line.codeBlock = currentBlock.copyWith(endLine: lines.length - 1);
      }
    }
  }

  static bool _isFence(String content) => content.trimLeft().startsWith('```');
}

class MarkdownLine {
  MarkdownLine({
    required this.index,
    required this.startOffset,
    required this.endOffset,
    required this.rawText,
    required this.content,
    required this.hasTrailingNewline,
  });

  final int index;
  final int startOffset;
  final int endOffset;
  final String rawText;
  final String content;
  final bool hasTrailingNewline;
  bool isFence = false;
  MarkdownCodeBlock? codeBlock;

  bool get isInsideCodeBlock => codeBlock != null;

  String get lineBreak => hasTrailingNewline ? '\n' : '';
}

class MarkdownCodeBlock {
  const MarkdownCodeBlock({
    required this.id,
    required this.startLine,
    required this.endLine,
  });

  final int id;
  final int startLine;
  final int endLine;

  MarkdownCodeBlock copyWith({int? startLine, int? endLine}) {
    return MarkdownCodeBlock(
      id: id,
      startLine: startLine ?? this.startLine,
      endLine: endLine ?? this.endLine,
    );
  }
}
