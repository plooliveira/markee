import 'package:flutter/widgets.dart';

enum MarkdownToolbarOption {
  bold,
  italic,
  strikethrough,
  heading,
  link,
  image,
  code,
  unorderedList,
  orderedList,
  checkbox,
  quote,
  horizontalRule,
}

class MarkdownFormatter {
  static TextEditingValue formatToolbarOption({
    required MarkdownToolbarOption markdownToolbarOption,
    required TextEditingValue value,
    int? option,
    String? customBoldCharacter,
    String? customItalicCharacter,
    String? customCodeCharacter,
    String? customBulletedListCharacter,
    String? customHorizontalRuleCharacter,
  }) {
    switch (markdownToolbarOption) {
      case MarkdownToolbarOption.bold:
        return value;
      case MarkdownToolbarOption.italic:
        return value;
      case MarkdownToolbarOption.strikethrough:
        return value;
      case MarkdownToolbarOption.code:
        return value;
      case MarkdownToolbarOption.heading:
        return _heading(value, option!);
      case MarkdownToolbarOption.link:
        return value;
      case MarkdownToolbarOption.image:
        return value;
      case MarkdownToolbarOption.unorderedList:
        return value;
      case MarkdownToolbarOption.orderedList:
        return value;
      case MarkdownToolbarOption.checkbox:
        return value;
      case MarkdownToolbarOption.horizontalRule:
        return value;
      case MarkdownToolbarOption.quote:
        return value;
    }
  }

  static TextEditingValue _heading(TextEditingValue value, int option) {
    final lines = value.text.split('\n').asMap();
    final newLines = lines.values.toList();
    final selectedLines = _selectedLines(value);
    int baseOffsetAdd = 0;
    int extentOffsetAdd = 0;

    for (final line in selectedLines) {
      final lineText = lines[line];

      if (lineText?.trim() != '') {
        newLines[line] = '${"#" * (option + 1)} $lineText';
        if (value.selection.baseOffset < value.selection.extentOffset) {
          baseOffsetAdd = option + 2;
          extentOffsetAdd = (baseOffsetAdd * 2);
        } else {
          extentOffsetAdd = option + 2;
          baseOffsetAdd = (extentOffsetAdd * 2);
        }
        continue;
      }

      newLines[line] = lineText!;
    }

    return value.copyWith(
      text: newLines.join('\n'),
      selection: value.selection.copyWith(
        baseOffset: value.selection.baseOffset + baseOffsetAdd,
        extentOffset: value.selection.extentOffset + extentOffsetAdd,
      ),
      composing: TextRange.empty,
    );
  }

  static List<int> _selectedLines(TextEditingValue value) {
    final selection = value.selection;
    final text = value.text;

    if (!selection.isValid || selection.end > text.length) {
      return [];
    }

    int lineAt(int offset) => '\n'.allMatches(text.substring(0, offset)).length;

    final firstLine = lineAt(selection.start);

    // O fim da seleção é exclusivo.
    final lastOffset = selection.isCollapsed
        ? selection.end
        : selection.end - 1;

    final lastLine = lineAt(lastOffset);

    return List.generate(
      lastLine - firstLine + 1,
      (index) => firstLine + index,
    );
  }
}
