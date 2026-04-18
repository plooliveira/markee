import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markee/src/markdown/editable_region.dart';
import 'package:markee/src/markdown/markdown_document.dart';

void main() {
  group('EditableRegionResolver', () {
    test('keeps collapsed selection on the current line', () {
      final document = MarkdownDocument.fromText('one\n**two**\nthree');
      final region = EditableRegionResolver.resolve(
        document: document,
        selection: const TextSelection.collapsed(offset: 5),
      );

      expect(region.startLine, 1);
      expect(region.endLine, 1);
    });

    test('expands to the full fenced code block', () {
      final text = 'before\n```\ncode\n```\nafter';
      final document = MarkdownDocument.fromText(text);
      final region = EditableRegionResolver.resolve(
        document: document,
        selection: TextSelection.collapsed(offset: text.indexOf('code') + 1),
      );

      expect(region.startLine, 1);
      expect(region.endLine, 3);
    });

    test('expands to every selected line for multi-line selection', () {
      final document = MarkdownDocument.fromText('one\n**two**\nthree');
      final region = EditableRegionResolver.resolve(
        document: document,
        selection: const TextSelection(baseOffset: 0, extentOffset: 10),
      );

      expect(region.startLine, 0);
      expect(region.endLine, 1);
    });
  });
}
