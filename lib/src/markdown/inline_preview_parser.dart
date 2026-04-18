import 'package:markee/src/markdown/markdown_document.dart';

enum MarkdownLineType {
  paragraph,
  heading,
  unorderedList,
  orderedList,
  checkbox,
  quote,
  horizontalRule,
  codeFence,
  codeBlock,
}

enum MarkdownSegmentStyle {
  plain,
  hiddenSyntax,
  headingText,
  listMarker,
  quoteMarker,
  strong,
  emphasis,
  strikethrough,
  inlineCode,
  linkText,
  linkDestination,
  imageAlt,
  imageSource,
  horizontalRule,
  code,
  codeFence,
}

class MarkdownPreviewLine {
  const MarkdownPreviewLine({
    required this.type,
    required this.chunks,
    this.headingLevel,
  });

  final MarkdownLineType type;
  final List<MarkdownPreviewChunk> chunks;
  final int? headingLevel;

  List<MarkdownSegment> get segments {
    return [
      for (final chunk in chunks) ...chunk.previewSegments,
    ];
  }
}

class MarkdownPreviewChunk {
  const MarkdownPreviewChunk({
    required this.rawText,
    required this.previewSegments,
    required this.rawStart,
    required this.rawEnd,
    this.isEditable = false,
  });

  final String rawText;
  final List<MarkdownSegment> previewSegments;
  final int rawStart;
  final int rawEnd;
  final bool isEditable;

  bool containsOffset(int offset) {
    if (rawStart == rawEnd) {
      return false;
    }
    return offset >= rawStart && offset <= rawEnd;
  }

  int get leadingHiddenTextLength {
    var length = 0;
    for (final segment in previewSegments) {
      if (segment.style != MarkdownSegmentStyle.hiddenSyntax) {
        break;
      }
      length += segment.text.length;
    }
    return length;
  }
}

class MarkdownSegment {
  const MarkdownSegment({
    required this.text,
    required this.style,
    this.linkUrl,
  });

  final String text;
  final MarkdownSegmentStyle style;
  final String? linkUrl;
}

class MarkdownInlinePreviewParser {
  const MarkdownInlinePreviewParser();

  MarkdownPreviewLine parseLine(MarkdownLine line) {
    final chunks = <MarkdownPreviewChunk>[];

    if (line.isInsideCodeBlock) {
      chunks.add(
        MarkdownPreviewChunk(
          rawText: line.content,
          previewSegments: [
            MarkdownSegment(
              text: line.content,
              style: line.isFence
                  ? MarkdownSegmentStyle.codeFence
                  : MarkdownSegmentStyle.code,
            ),
          ],
          rawStart: 0,
          rawEnd: line.content.length,
          isEditable: true,
        ),
      );
      _appendNewLine(chunks, line);
      return MarkdownPreviewLine(
        type: line.isFence ? MarkdownLineType.codeFence : MarkdownLineType.codeBlock,
        chunks: chunks,
      );
    }

    final content = line.content;
    final headingMatch = RegExp(r'^(#{1,6}\s+)(.*)$').firstMatch(content);
    if (headingMatch != null) {
      final prefix = headingMatch.group(1)!;
      final title = headingMatch.group(2)!;
      chunks.add(
        MarkdownPreviewChunk(
          rawText: prefix,
          previewSegments: const [
            MarkdownSegment(text: '', style: MarkdownSegmentStyle.hiddenSyntax),
          ],
          rawStart: 0,
          rawEnd: prefix.length,
        ),
      );
      chunks.add(
        MarkdownPreviewChunk(
          rawText: title,
          previewSegments: [
            MarkdownSegment(text: title, style: MarkdownSegmentStyle.headingText),
          ],
          rawStart: prefix.length,
          rawEnd: content.length,
        ),
      );
      _appendNewLine(chunks, line);
      return MarkdownPreviewLine(
        type: MarkdownLineType.heading,
        chunks: chunks,
        headingLevel: prefix.trim().length,
      );
    }

    final checkboxMatch = RegExp(r'^([-*]\s+\[(?: |x|X)\]\s+)(.*)$').firstMatch(content);
    if (checkboxMatch != null) {
      final prefix = checkboxMatch.group(1)!;
      chunks.add(
        MarkdownPreviewChunk(
          rawText: prefix,
          previewSegments: [
            MarkdownSegment(text: prefix, style: MarkdownSegmentStyle.listMarker),
          ],
          rawStart: 0,
          rawEnd: prefix.length,
        ),
      );
      chunks.addAll(
        _parseInline(
          checkboxMatch.group(2)!,
          startOffset: prefix.length,
        ),
      );
      _appendNewLine(chunks, line);
      return MarkdownPreviewLine(
        type: MarkdownLineType.checkbox,
        chunks: chunks,
      );
    }

    final orderedListMatch = RegExp(r'^(\d+\.\s+)(.*)$').firstMatch(content);
    if (orderedListMatch != null) {
      final prefix = orderedListMatch.group(1)!;
      chunks.add(
        MarkdownPreviewChunk(
          rawText: prefix,
          previewSegments: [
            MarkdownSegment(text: prefix, style: MarkdownSegmentStyle.listMarker),
          ],
          rawStart: 0,
          rawEnd: prefix.length,
        ),
      );
      chunks.addAll(
        _parseInline(
          orderedListMatch.group(2)!,
          startOffset: prefix.length,
        ),
      );
      _appendNewLine(chunks, line);
      return MarkdownPreviewLine(
        type: MarkdownLineType.orderedList,
        chunks: chunks,
      );
    }

    final unorderedListMatch = RegExp(r'^([-*+]\s+)(.*)$').firstMatch(content);
    if (unorderedListMatch != null) {
      final prefix = unorderedListMatch.group(1)!;
      chunks.add(
        MarkdownPreviewChunk(
          rawText: prefix,
          previewSegments: [
            MarkdownSegment(text: prefix, style: MarkdownSegmentStyle.listMarker),
          ],
          rawStart: 0,
          rawEnd: prefix.length,
        ),
      );
      chunks.addAll(
        _parseInline(
          unorderedListMatch.group(2)!,
          startOffset: prefix.length,
        ),
      );
      _appendNewLine(chunks, line);
      return MarkdownPreviewLine(
        type: MarkdownLineType.unorderedList,
        chunks: chunks,
      );
    }

    final quoteMatch = RegExp(r'^(>\s?)(.*)$').firstMatch(content);
    if (quoteMatch != null) {
      final prefix = quoteMatch.group(1)!;
      chunks.add(
        MarkdownPreviewChunk(
          rawText: prefix,
          previewSegments: [
            MarkdownSegment(text: prefix, style: MarkdownSegmentStyle.quoteMarker),
          ],
          rawStart: 0,
          rawEnd: prefix.length,
        ),
      );
      chunks.addAll(
        _parseInline(
          quoteMatch.group(2)!,
          startOffset: prefix.length,
        ),
      );
      _appendNewLine(chunks, line);
      return MarkdownPreviewLine(
        type: MarkdownLineType.quote,
        chunks: chunks,
      );
    }

    if (RegExp(r'^\s*([-*_])(?:\s*\1){2,}\s*$').hasMatch(content)) {
      chunks.add(
        MarkdownPreviewChunk(
          rawText: content,
          previewSegments: [
            MarkdownSegment(
              text: content,
              style: MarkdownSegmentStyle.horizontalRule,
            ),
          ],
          rawStart: 0,
          rawEnd: content.length,
        ),
      );
      _appendNewLine(chunks, line);
      return MarkdownPreviewLine(
        type: MarkdownLineType.horizontalRule,
        chunks: chunks,
      );
    }

    chunks.addAll(_parseInline(content));
    _appendNewLine(chunks, line);
    return MarkdownPreviewLine(type: MarkdownLineType.paragraph, chunks: chunks);
  }

  void _appendNewLine(List<MarkdownPreviewChunk> chunks, MarkdownLine line) {
    if (!line.hasTrailingNewline) {
      return;
    }

    chunks.add(
      MarkdownPreviewChunk(
        rawText: '\n',
        previewSegments: const [
          MarkdownSegment(text: '\n', style: MarkdownSegmentStyle.plain),
        ],
        rawStart: line.content.length,
        rawEnd: line.content.length,
      ),
    );
  }

  List<MarkdownPreviewChunk> _parseInline(
    String text, {
    MarkdownSegmentStyle defaultStyle = MarkdownSegmentStyle.plain,
    int startOffset = 0,
  }) {
    final chunks = <MarkdownPreviewChunk>[];
    var offset = 0;

    while (offset < text.length) {
      final imageToken = _parseImage(text, offset, startOffset);
      if (imageToken != null) {
        chunks.add(imageToken.chunk);
        offset = imageToken.nextOffset;
        continue;
      }

      final linkToken = _parseLink(text, offset, startOffset);
      if (linkToken != null) {
        chunks.add(linkToken.chunk);
        offset = linkToken.nextOffset;
        continue;
      }

      final codeToken = _parseDelimitedToken(
        text: text,
        offset: offset,
        startOffset: startOffset,
        delimiter: '`',
        innerStyle: MarkdownSegmentStyle.inlineCode,
      );
      if (codeToken != null) {
        chunks.add(codeToken.chunk);
        offset = codeToken.nextOffset;
        continue;
      }

      final strongToken = _parseDelimitedToken(
        text: text,
        offset: offset,
        startOffset: startOffset,
        delimiter: '**',
        innerStyle: MarkdownSegmentStyle.strong,
      );
      if (strongToken != null) {
        chunks.add(strongToken.chunk);
        offset = strongToken.nextOffset;
        continue;
      }

      final strikethroughToken = _parseDelimitedToken(
        text: text,
        offset: offset,
        startOffset: startOffset,
        delimiter: '~~',
        innerStyle: MarkdownSegmentStyle.strikethrough,
      );
      if (strikethroughToken != null) {
        chunks.add(strikethroughToken.chunk);
        offset = strikethroughToken.nextOffset;
        continue;
      }

      final emphasisToken = _parseDelimitedToken(
        text: text,
        offset: offset,
        startOffset: startOffset,
        delimiter: '*',
        innerStyle: MarkdownSegmentStyle.emphasis,
      );
      if (emphasisToken != null) {
        chunks.add(emphasisToken.chunk);
        offset = emphasisToken.nextOffset;
        continue;
      }

      final nextMarker = _nextMarkerOffset(text, offset);
      final nextOffset = nextMarker == -1 ? text.length : nextMarker;
      final plainText = text.substring(offset, nextOffset);
      chunks.add(
        MarkdownPreviewChunk(
          rawText: plainText,
          previewSegments: [
            MarkdownSegment(text: plainText, style: defaultStyle),
          ],
          rawStart: startOffset + offset,
          rawEnd: startOffset + nextOffset,
        ),
      );
      offset = nextOffset;
    }

    if (chunks.isEmpty) {
      chunks.add(
        MarkdownPreviewChunk(
          rawText: '',
          previewSegments: const [],
          rawStart: startOffset,
          rawEnd: startOffset,
        ),
      );
    }

    return chunks;
  }

  _ParsedToken? _parseImage(String text, int offset, int startOffset) {
    if (!text.startsWith('![', offset)) {
      return null;
    }

    final closeBracket = text.indexOf(']', offset + 2);
    final openParen = closeBracket == -1 ? -1 : text.indexOf('(', closeBracket);
    final closeParen = openParen == -1 ? -1 : text.indexOf(')', openParen);
    if (closeBracket == -1 || openParen == -1 || closeParen == -1) {
      return null;
    }

    final rawText = text.substring(offset, closeParen + 1);
    return _ParsedToken(
      nextOffset: closeParen + 1,
      chunk: MarkdownPreviewChunk(
        rawText: rawText,
        rawStart: startOffset + offset,
        rawEnd: startOffset + closeParen + 1,
        isEditable: true,
        previewSegments: [
          const MarkdownSegment(text: '![', style: MarkdownSegmentStyle.hiddenSyntax),
          MarkdownSegment(
            text: text.substring(offset + 2, closeBracket),
            style: MarkdownSegmentStyle.imageAlt,
          ),
          const MarkdownSegment(text: '](', style: MarkdownSegmentStyle.hiddenSyntax),
          MarkdownSegment(
            text: text.substring(openParen + 1, closeParen),
            style: MarkdownSegmentStyle.imageSource,
          ),
          const MarkdownSegment(text: ')', style: MarkdownSegmentStyle.hiddenSyntax),
        ],
      ),
    );
  }

  _ParsedToken? _parseLink(String text, int offset, int startOffset) {
    if (!text.startsWith('[', offset)) {
      return null;
    }

    final closeBracket = text.indexOf(']', offset + 1);
    final openParen = closeBracket == -1 ? -1 : text.indexOf('(', closeBracket);
    final closeParen = openParen == -1 ? -1 : text.indexOf(')', openParen);
    if (closeBracket == -1 || openParen == -1 || closeParen == -1) {
      return null;
    }

    final rawText = text.substring(offset, closeParen + 1);
    final url = text.substring(openParen + 1, closeParen);
    return _ParsedToken(
      nextOffset: closeParen + 1,
      chunk: MarkdownPreviewChunk(
        rawText: rawText,
        rawStart: startOffset + offset,
        rawEnd: startOffset + closeParen + 1,
        isEditable: true,
        previewSegments: [
          const MarkdownSegment(text: '[', style: MarkdownSegmentStyle.hiddenSyntax),
          MarkdownSegment(
            text: text.substring(offset + 1, closeBracket),
            style: MarkdownSegmentStyle.linkText,
            linkUrl: url,
          ),
          const MarkdownSegment(text: '](', style: MarkdownSegmentStyle.hiddenSyntax),
          MarkdownSegment(text: url, style: MarkdownSegmentStyle.hiddenSyntax),
          const MarkdownSegment(text: ')', style: MarkdownSegmentStyle.hiddenSyntax),
        ],
      ),
    );
  }

  _ParsedToken? _parseDelimitedToken({
    required String text,
    required int offset,
    required int startOffset,
    required String delimiter,
    required MarkdownSegmentStyle innerStyle,
  }) {
    if (!text.startsWith(delimiter, offset)) {
      return null;
    }

    final closeOffset = text.indexOf(delimiter, offset + delimiter.length);
    if (closeOffset == -1) {
      return null;
    }

    final rawText = text.substring(offset, closeOffset + delimiter.length);
    return _ParsedToken(
      nextOffset: closeOffset + delimiter.length,
      chunk: MarkdownPreviewChunk(
        rawText: rawText,
        rawStart: startOffset + offset,
        rawEnd: startOffset + closeOffset + delimiter.length,
        isEditable: true,
        previewSegments: [
          MarkdownSegment(text: delimiter, style: MarkdownSegmentStyle.hiddenSyntax),
          MarkdownSegment(
            text: text.substring(offset + delimiter.length, closeOffset),
            style: innerStyle,
          ),
          MarkdownSegment(text: delimiter, style: MarkdownSegmentStyle.hiddenSyntax),
        ],
      ),
    );
  }

  int _nextMarkerOffset(String text, int offset) {
    const markers = ['![', '[', '`', '**', '~~', '*'];
    var nextOffset = -1;
    for (final marker in markers) {
      final markerOffset = text.indexOf(marker, offset);
      if (markerOffset == -1) {
        continue;
      }
      if (nextOffset == -1 || markerOffset < nextOffset) {
        nextOffset = markerOffset;
      }
    }
    return nextOffset;
  }
}

class _ParsedToken {
  const _ParsedToken({
    required this.nextOffset,
    required this.chunk,
  });

  final int nextOffset;
  final MarkdownPreviewChunk chunk;
}
