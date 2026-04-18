import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markee/src/markdown/markdown_formatter.dart';

void main() {
  group('MarkdownFormatter', () {
    test('wraps selected text in bold markers', () {
      final value = const TextEditingValue(
        text: 'hello',
        selection: TextSelection(baseOffset: 0, extentOffset: 5),
      );

      final nextValue = MarkdownFormatter.formatToolbarOption(
        markdownToolbarOption: MarkdownToolbarOption.bold,
        value: value,
      );

      expect(nextValue.text, '**hello**');
      expect(nextValue.selection.baseOffset, 2);
      expect(nextValue.selection.extentOffset, 7);
    });

    test('formats multi-line unordered lists', () {
      final value = const TextEditingValue(
        text: 'one\ntwo',
        selection: TextSelection(baseOffset: 0, extentOffset: 7),
      );

      final nextValue = MarkdownFormatter.formatToolbarOption(
        markdownToolbarOption: MarkdownToolbarOption.unorderedList,
        value: value,
      );

      expect(nextValue.text, '- one\n- two');
    });

    test('inserts a link placeholder for collapsed selections', () {
      final value = const TextEditingValue(
        text: 'hello',
        selection: TextSelection.collapsed(offset: 5),
      );

      final nextValue = MarkdownFormatter.formatToolbarOption(
        markdownToolbarOption: MarkdownToolbarOption.link,
        value: value,
      );

      expect(nextValue.text, 'hello[My Link text](https://example.com)');
      expect(nextValue.selection.baseOffset, greaterThan(5));
      expect(nextValue.selection.extentOffset, greaterThan(nextValue.selection.baseOffset));
    });
  });
}
