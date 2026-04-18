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
    required this.segments,
    this.headingLevel,
  });

  final MarkdownLineType type;
  final List<MarkdownSegment> segments;
  final int? headingLevel;
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
    final segments = <MarkdownSegment>[];

    if (line.isInsideCodeBlock) {
      segments.add(
        MarkdownSegment(
          text: line.content,
          style: line.isFence
              ? MarkdownSegmentStyle.codeFence
              : MarkdownSegmentStyle.code,
        ),
      );
      if (line.hasTrailingNewline) {
        segments.add(
          const MarkdownSegment(text: '\n', style: MarkdownSegmentStyle.plain),
        );
      }
      return MarkdownPreviewLine(
        type: line.isFence ? MarkdownLineType.codeFence : MarkdownLineType.codeBlock,
        segments: segments,
      );
    }

    final content = line.content;
    final headingMatch = RegExp(r'^(#{1,6}\s+)(.*)$').firstMatch(content);
    if (headingMatch != null) {
      segments.add(
        MarkdownSegment(
          text: headingMatch.group(1)!,
          style: MarkdownSegmentStyle.hiddenSyntax,
        ),
      );
      segments.addAll(
        _parseInline(
          headingMatch.group(2)!,
          defaultStyle: MarkdownSegmentStyle.headingText,
        ),
      );
      _appendNewLine(segments, line);
      return MarkdownPreviewLine(
        type: MarkdownLineType.heading,
        segments: segments,
        headingLevel: headingMatch.group(1)!.trim().length,
      );
    }

    final checkboxMatch = RegExp(r'^([-*]\s+\[(?: |x|X)\]\s+)(.*)$').firstMatch(content);
    if (checkboxMatch != null) {
      segments.add(
        MarkdownSegment(
          text: checkboxMatch.group(1)!,
          style: MarkdownSegmentStyle.listMarker,
        ),
      );
      segments.addAll(_parseInline(checkboxMatch.group(2)!));
      _appendNewLine(segments, line);
      return MarkdownPreviewLine(
        type: MarkdownLineType.checkbox,
        segments: segments,
      );
    }

    final orderedListMatch = RegExp(r'^(\d+\.\s+)(.*)$').firstMatch(content);
    if (orderedListMatch != null) {
      segments.add(
        MarkdownSegment(
          text: orderedListMatch.group(1)!,
          style: MarkdownSegmentStyle.listMarker,
        ),
      );
      segments.addAll(_parseInline(orderedListMatch.group(2)!));
      _appendNewLine(segments, line);
      return MarkdownPreviewLine(
        type: MarkdownLineType.orderedList,
        segments: segments,
      );
    }

    final unorderedListMatch = RegExp(r'^([-*+]\s+)(.*)$').firstMatch(content);
    if (unorderedListMatch != null) {
      segments.add(
        MarkdownSegment(
          text: unorderedListMatch.group(1)!,
          style: MarkdownSegmentStyle.listMarker,
        ),
      );
      segments.addAll(_parseInline(unorderedListMatch.group(2)!));
      _appendNewLine(segments, line);
      return MarkdownPreviewLine(
        type: MarkdownLineType.unorderedList,
        segments: segments,
      );
    }

    final quoteMatch = RegExp(r'^(>\s?)(.*)$').firstMatch(content);
    if (quoteMatch != null) {
      segments.add(
        MarkdownSegment(
          text: quoteMatch.group(1)!,
          style: MarkdownSegmentStyle.quoteMarker,
        ),
      );
      segments.addAll(_parseInline(quoteMatch.group(2)!));
      _appendNewLine(segments, line);
      return MarkdownPreviewLine(
        type: MarkdownLineType.quote,
        segments: segments,
      );
    }

    if (RegExp(r'^\s*([-*_])(?:\s*\1){2,}\s*$').hasMatch(content)) {
      segments.add(
        MarkdownSegment(
          text: content,
          style: MarkdownSegmentStyle.horizontalRule,
        ),
      );
      _appendNewLine(segments, line);
      return MarkdownPreviewLine(
        type: MarkdownLineType.horizontalRule,
        segments: segments,
      );
    }

    segments.addAll(_parseInline(content));
    _appendNewLine(segments, line);
    return MarkdownPreviewLine(type: MarkdownLineType.paragraph, segments: segments);
  }

  void _appendNewLine(List<MarkdownSegment> segments, MarkdownLine line) {
    if (!line.hasTrailingNewline) {
      return;
    }
    segments.add(const MarkdownSegment(text: '\n', style: MarkdownSegmentStyle.plain));
  }

  List<MarkdownSegment> _parseInline(
    String text, {
    MarkdownSegmentStyle defaultStyle = MarkdownSegmentStyle.plain,
  }) {
    final segments = <MarkdownSegment>[];
    var offset = 0;

    while (offset < text.length) {
      final imageToken = _parseImage(text, offset);
      if (imageToken != null) {
        segments.addAll(imageToken.segments);
        offset = imageToken.nextOffset;
        continue;
      }

      final linkToken = _parseLink(text, offset);
      if (linkToken != null) {
        segments.addAll(linkToken.segments);
        offset = linkToken.nextOffset;
        continue;
      }

      final codeToken = _parseDelimitedToken(
        text: text,
        offset: offset,
        delimiter: '`',
        innerStyle: MarkdownSegmentStyle.inlineCode,
      );
      if (codeToken != null) {
        segments.addAll(codeToken.segments);
        offset = codeToken.nextOffset;
        continue;
      }

      final strongToken = _parseDelimitedToken(
        text: text,
        offset: offset,
        delimiter: '**',
        innerStyle: MarkdownSegmentStyle.strong,
      );
      if (strongToken != null) {
        segments.addAll(strongToken.segments);
        offset = strongToken.nextOffset;
        continue;
      }

      final strikethroughToken = _parseDelimitedToken(
        text: text,
        offset: offset,
        delimiter: '~~',
        innerStyle: MarkdownSegmentStyle.strikethrough,
      );
      if (strikethroughToken != null) {
        segments.addAll(strikethroughToken.segments);
        offset = strikethroughToken.nextOffset;
        continue;
      }

      final emphasisToken = _parseDelimitedToken(
        text: text,
        offset: offset,
        delimiter: '*',
        innerStyle: MarkdownSegmentStyle.emphasis,
      );
      if (emphasisToken != null) {
        segments.addAll(emphasisToken.segments);
        offset = emphasisToken.nextOffset;
        continue;
      }

      final nextMarker = _nextMarkerOffset(text, offset);
      final nextOffset = nextMarker == -1 ? text.length : nextMarker;
      segments.add(
        MarkdownSegment(
          text: text.substring(offset, nextOffset),
          style: defaultStyle,
        ),
      );
      offset = nextOffset;
    }

    return segments;
  }

  _ParsedToken? _parseImage(String text, int offset) {
    if (!text.startsWith('![', offset)) {
      return null;
    }

    final closeBracket = text.indexOf(']', offset + 2);
    final openParen = closeBracket == -1 ? -1 : text.indexOf('(', closeBracket);
    final closeParen = openParen == -1 ? -1 : text.indexOf(')', openParen);
    if (closeBracket == -1 || openParen == -1 || closeParen == -1) {
      return null;
    }

    return _ParsedToken(
      nextOffset: closeParen + 1,
      segments: [
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
    );
  }

  _ParsedToken? _parseLink(String text, int offset) {
    if (!text.startsWith('[', offset)) {
      return null;
    }

    final closeBracket = text.indexOf(']', offset + 1);
    final openParen = closeBracket == -1 ? -1 : text.indexOf('(', closeBracket);
    final closeParen = openParen == -1 ? -1 : text.indexOf(')', openParen);
    if (closeBracket == -1 || openParen == -1 || closeParen == -1) {
      return null;
    }

    return _ParsedToken(
      nextOffset: closeParen + 1,
      segments: [
        const MarkdownSegment(text: '[', style: MarkdownSegmentStyle.hiddenSyntax),
        MarkdownSegment(
          text: text.substring(offset + 1, closeBracket),
          style: MarkdownSegmentStyle.linkText,
          linkUrl: text.substring(openParen + 1, closeParen),
        ),
        const MarkdownSegment(text: '](', style: MarkdownSegmentStyle.hiddenSyntax),
        MarkdownSegment(
          text: text.substring(openParen + 1, closeParen),
          style: MarkdownSegmentStyle.hiddenSyntax,
        ),
        const MarkdownSegment(text: ')', style: MarkdownSegmentStyle.hiddenSyntax),
      ],
    );
  }

  _ParsedToken? _parseDelimitedToken({
    required String text,
    required int offset,
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

    return _ParsedToken(
      nextOffset: closeOffset + delimiter.length,
      segments: [
        MarkdownSegment(text: delimiter, style: MarkdownSegmentStyle.hiddenSyntax),
        MarkdownSegment(
          text: text.substring(offset + delimiter.length, closeOffset),
          style: innerStyle,
        ),
        MarkdownSegment(text: delimiter, style: MarkdownSegmentStyle.hiddenSyntax),
      ],
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
    required this.segments,
  });

  final int nextOffset;
  final List<MarkdownSegment> segments;
}
