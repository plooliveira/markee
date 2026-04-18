import 'package:flutter_test/flutter_test.dart';
import 'package:markee/src/markdown/inline_preview_parser.dart';
import 'package:markee/src/markdown/markdown_document.dart';

void main() {
  group('MarkdownInlinePreviewParser', () {
    const parser = MarkdownInlinePreviewParser();

    test('parses headings with hidden syntax and styled content', () {
      final line = MarkdownDocument.fromText('# Heading **bold**').lineAt(0);
      final preview = parser.parseLine(line);

      expect(preview.type, MarkdownLineType.heading);
      expect(preview.headingLevel, 1);
      expect(preview.chunks, hasLength(2));
      expect(preview.chunks[0].previewSegments.single.style, MarkdownSegmentStyle.hiddenSyntax);
      expect(preview.chunks[1].previewSegments.single.style, MarkdownSegmentStyle.headingText);
      expect(preview.chunks[1].previewSegments.single.text, 'Heading **bold**');
    });

    test('parses inline emphasis, links and images', () {
      final line = MarkdownDocument.fromText(
        '**bold** *it* [link](https://example.com) ![alt](/img.png)',
      ).lineAt(0);
      final preview = parser.parseLine(line);
      final styles = preview.segments.map((segment) => segment.style).toList();
      final linkTextSegment = preview.segments.firstWhere(
        (segment) => segment.style == MarkdownSegmentStyle.linkText,
      );
      final linkDestinationSegment = preview.segments.firstWhere(
        (segment) =>
            segment.text == 'https://example.com' &&
            segment.style == MarkdownSegmentStyle.hiddenSyntax,
      );

      expect(styles, contains(MarkdownSegmentStyle.strong));
      expect(styles, contains(MarkdownSegmentStyle.emphasis));
      expect(styles, contains(MarkdownSegmentStyle.linkText));
      expect(styles, contains(MarkdownSegmentStyle.imageAlt));
      expect(styles, contains(MarkdownSegmentStyle.imageSource));
      expect(linkTextSegment.linkUrl, 'https://example.com');
      expect(linkDestinationSegment.style, MarkdownSegmentStyle.hiddenSyntax);
    });

    test('parses code block lines separately from regular paragraphs', () {
      final document = MarkdownDocument.fromText('```\nfinal x = 1;\n```');

      expect(parser.parseLine(document.lineAt(0)).type, MarkdownLineType.codeFence);
      expect(parser.parseLine(document.lineAt(1)).type, MarkdownLineType.codeBlock);
    });
  });
}
