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
        return _heading(value);
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

  static TextEditingValue _heading(TextEditingValue value) {
    final lines = value.text.split('\n').asMap();
    final List<String> newLines = [];
    final selectedLines = _selectedLines(value);

    print(value.selection.textBefore(value.text));
    print(selectedLines);

    for (final line in selectedLines) {
      final lineText = lines[line];
      final trimedLine = lineText?.trim();
      if (trimedLine != "" && lineText?[0] != "-") {
        newLines.add("#$lineText");
      } else {
        newLines.add("$lineText");
      }
    }

    print(newLines);

    return TextEditingValue(
      text: value.selection.textBefore(value.text) + newLines.join('\n'),
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
