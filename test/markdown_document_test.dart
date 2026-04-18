import 'package:flutter_test/flutter_test.dart';
import 'package:markee/src/markdown/markdown_document.dart';

void main() {
  group('MarkdownDocument', () {
    test('indexes lines and detects fenced code blocks', () {
      final document = MarkdownDocument.fromText('one\n```\ncode\n```\ntwo');

      expect(document.lineCount, 5);
      expect(document.lineIndexForOffset(0), 0);
      expect(document.lineIndexForOffset(4), 1);
      expect(document.lineAt(1).isFence, isTrue);
      expect(document.lineAt(2).isInsideCodeBlock, isTrue);
      expect(document.lineAt(3).isFence, isTrue);
      expect(document.lineAt(2).codeBlock?.startLine, 1);
      expect(document.lineAt(2).codeBlock?.endLine, 3);
    });

    test('creates a single empty line for empty text', () {
      final document = MarkdownDocument.fromText('');

      expect(document.lineCount, 1);
      expect(document.lineAt(0).rawText, isEmpty);
      expect(document.lineAt(0).content, isEmpty);
    });
  });
}
