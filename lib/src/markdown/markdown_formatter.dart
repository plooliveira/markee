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

enum _FormatOption { formatStartEnd, formatStart, formatList, formatAddNew }

enum _TextApplyOption {
  selectionHasCharacter,
  outsideSelectionHasCharacter,
  noneAddNew,
}

class MarkdownFormatter {
  const MarkdownFormatter._();

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
        return _SelectionFormatter(
          formatOption: _FormatOption.formatStartEnd,
          value: value,
          character: customBoldCharacter ?? '**',
          placeholder: 'Bold',
        ).format();
      case MarkdownToolbarOption.italic:
        return _SelectionFormatter(
          formatOption: _FormatOption.formatStartEnd,
          value: value,
          character: customItalicCharacter ?? '*',
          placeholder: 'Italic',
        ).format();
      case MarkdownToolbarOption.strikethrough:
        return _SelectionFormatter(
          formatOption: _FormatOption.formatStartEnd,
          value: value,
          character: '~~',
          placeholder: 'Strikethrough',
        ).format();
      case MarkdownToolbarOption.code:
        return _SelectionFormatter(
          formatOption: _FormatOption.formatStartEnd,
          value: value,
          character: customCodeCharacter ?? '```',
          placeholder: 'Code',
          newLine: true,
        ).format();
      case MarkdownToolbarOption.heading:
        return _SelectionFormatter(
          formatOption: _FormatOption.formatStart,
          value: value,
          multipleCharacters: const [
            '# ',
            '## ',
            '### ',
            '#### ',
            '##### ',
            '###### ',
          ],
          multipleCharactersOption: option,
          newLine: true,
          placeholder: 'Heading',
        ).format();
      case MarkdownToolbarOption.link:
        return _formatTextLink(value: value);
      case MarkdownToolbarOption.image:
        return _formatImage(value: value);
      case MarkdownToolbarOption.unorderedList:
        return _SelectionFormatter(
          formatOption: _FormatOption.formatList,
          value: value,
          character: customBulletedListCharacter != null
              ? '$customBulletedListCharacter '
              : '- ',
          placeholder: 'Bulleted list',
        ).format();
      case MarkdownToolbarOption.orderedList:
        return _SelectionFormatter(
          formatOption: _FormatOption.formatList,
          value: value,
          orderedList: true,
          placeholder: 'Numbered list',
        ).format();
      case MarkdownToolbarOption.checkbox:
        return _SelectionFormatter(
          formatOption: _FormatOption.formatList,
          value: value,
          placeholder: 'Checkbox',
          multipleCharacters: const ['- [ ] ', '- [x] '],
          multipleCharactersOption: option,
        ).format();
      case MarkdownToolbarOption.horizontalRule:
        return _SelectionFormatter(
          formatOption: _FormatOption.formatAddNew,
          value: value,
          character: customHorizontalRuleCharacter ?? '---',
        ).format();
      case MarkdownToolbarOption.quote:
        return _SelectionFormatter(
          formatOption: _FormatOption.formatStart,
          value: value,
          character: '> ',
          newLine: true,
          placeholder: 'Quote',
        ).format();
    }
  }

  static TextEditingValue _formatTextLink({required TextEditingValue value}) {
    final selection = value.selection;
    final text = value.text;
    final selectionText = text.substring(selection.start, selection.end);
    const placeholder = 'My Link text';
    const placeholderEnd = 'https://example.com';

    if (text.isNotEmpty && selectionText.isNotEmpty) {
      final beforeText = text.substring(0, selection.start);
      final afterText = text.substring(selection.end);
      final newText = '$beforeText[$selectionText]($placeholderEnd)$afterText';

      return value.copyWith(
        text: newText,
        selection: TextSelection(
          baseOffset:
              selection.start + 3 + selectionText.length + 'https://'.length,
          extentOffset: selection.end + placeholderEnd.length + 3,
        ),
      );
    }

    final beforeText = text.substring(0, selection.start);
    final afterText = text.substring(selection.end);

    return value.copyWith(
      text: '$beforeText[$placeholder]($placeholderEnd)$afterText',
      selection: TextSelection(
        baseOffset: selection.start + 3 + placeholder.length + 'https://'.length,
        extentOffset:
            selection.end + placeholder.length + 3 + placeholderEnd.length,
      ),
    );
  }

  static TextEditingValue _formatImage({required TextEditingValue value}) {
    const altPlaceholder = 'Alt text';
    const linkPlaceholder = '/link/to/picture.jpg';

    final selection = value.selection;
    final text = value.text;
    final beforeText = text.substring(0, selection.start);
    final afterText = text.substring(selection.end);
    final newText = '$beforeText![$altPlaceholder]($linkPlaceholder)$afterText';

    return value.copyWith(
      text: newText,
      selection: TextSelection(
        baseOffset: selection.start + 4 + altPlaceholder.length,
        extentOffset:
            selection.start + altPlaceholder.length + 4 + linkPlaceholder.length,
      ),
    );
  }
}

class _SelectionFormatter {
  _SelectionFormatter({
    required this.formatOption,
    required this.value,
    this.character,
    this.newLine,
    this.placeholder = 'Text',
    this.multipleCharacters,
    this.multipleCharactersOption,
    this.orderedList,
  });

  final _FormatOption formatOption;
  final TextEditingValue value;
  String? character;
  final bool? newLine;
  final String placeholder;
  final List<String>? multipleCharacters;
  final int? multipleCharactersOption;
  final bool? orderedList;
  late String newText;
  late String beforeText;
  late String afterText;
  late String reversedBeforeText;
  late String reversedAfterText;
  late _TextApplyOption textApplyOption;

  TextEditingValue format() {
    final selection = value.selection;
    final text = value.text;
    final selectionText = text.substring(selection.start, selection.end);

    beforeText = text.substring(0, selection.start);
    afterText = text.substring(selection.end);
    reversedBeforeText = String.fromCharCodes(beforeText.runes.toList().reversed);
    reversedAfterText = String.fromCharCodes(afterText.runes.toList().reversed);

    character = multipleCharacters != null
        ? multipleCharacters![multipleCharactersOption ?? 0]
        : character ?? '';

    if (text.isNotEmpty && selectionText.isNotEmpty) {
      newText = selectionText;

      if (_selectionCharacterBool(selectionText: selectionText)) {
        _selectionHasCharacter();
      } else if (_outsideSelectionHasCharacterBool()) {
        _outsideHasCharacter();
      } else {
        _add();
      }

      return _apply();
    }

    return _emptyAddNew();
  }

  bool _selectionCharacterBool({required String selectionText}) {
    switch (formatOption) {
      case _FormatOption.formatStartEnd:
        return selectionText.contains(character!, 0) &&
            selectionText.contains(character!, 1);
      case _FormatOption.formatStart:
        if (multipleCharacters != null) {
          for (final item in multipleCharacters!) {
            if (selectionText.contains(item)) {
              return true;
            }
          }
        }
        return selectionText.contains(character!);
      case _FormatOption.formatList:
        final exp = RegExp(r'[0-9]. ');
        if (multipleCharacters != null) {
          for (final item in multipleCharacters!) {
            if (selectionText.contains(item)) {
              return true;
            }
          }
        }
        return selectionText.contains(orderedList == true ? exp : character!);
      case _FormatOption.formatAddNew:
        return selectionText.contains(character!);
    }
  }

  bool _outsideSelectionHasCharacterBool() {
    if (formatOption != _FormatOption.formatStartEnd) {
      return false;
    }

    return beforeText.isNotEmpty &&
        reversedBeforeText[0] != ' ' &&
        reversedBeforeText.contains(character!) &&
        afterText.isNotEmpty &&
        reversedAfterText[0] != ' ' &&
        reversedAfterText.contains(character!);
  }

  void _selectionHasCharacter() {
    textApplyOption = _TextApplyOption.selectionHasCharacter;
    final selection = value.selection;

    switch (formatOption) {
      case _FormatOption.formatStartEnd:
        newText = value.text.substring(selection.start, selection.end);
        newText = newText.replaceAll(character!, '');
        return;
      case _FormatOption.formatStart:
        newText = value.text.substring(selection.start, selection.end);
        if (multipleCharacters != null) {
          for (final item in multipleCharacters!) {
            if (newText.contains(item)) {
              newText = newText.replaceAll(character![0], '');
            } else {
              newText = newText.replaceAll(character!, '');
              break;
            }
          }
        } else {
          newText = newText.replaceAll(character!, '');
        }
        return;
      case _FormatOption.formatList:
        newText = value.text.substring(selection.start, selection.end);
        final exp = RegExp(r'[0-9]. ');

        final lines = newText.split('\n');
        var orderedIndex =
            int.tryParse(lines[0].substring(0, lines[0].indexOf(exp) + 1)) ?? 0;

        if (orderedList == true) {
          for (var i = 0; i < lines.length; i++) {
            if (lines[i].isNotEmpty) {
              lines[i] = lines[i].replaceAll('$orderedIndex. ', '');
              orderedIndex++;
            }
          }
        } else if (multipleCharacters != null) {
          for (final item in multipleCharacters!) {
            for (var j = 0; j < lines.length; j++) {
              if (lines[j].contains(item)) {
                lines[j] = lines[j].replaceAll(item, '');
              } else {
                for (var k = 0; k < lines.length; k++) {
                  lines[k] = lines[k].replaceAll(character!, '');
                }
              }
            }
          }
        } else {
          for (var i = 0; i < lines.length; i++) {
            lines[i] = lines[i].replaceAll(character!, '');
          }
        }

        newText = lines.join('\n');
        return;
      case _FormatOption.formatAddNew:
        newText = value.text.substring(selection.start, selection.end);
        newText = newText.replaceAll(character!, '');
        return;
    }
  }

  void _outsideHasCharacter() {
    textApplyOption = _TextApplyOption.outsideSelectionHasCharacter;
    reversedBeforeText = reversedBeforeText.replaceFirst(character!, '');
    beforeText = String.fromCharCodes(reversedBeforeText.runes.toList().reversed);
    afterText = afterText.replaceFirst(character!, '');
  }

  void _add() {
    textApplyOption = _TextApplyOption.noneAddNew;
    final selection = value.selection;

    switch (formatOption) {
      case _FormatOption.formatStartEnd:
        newText = value.text.substring(selection.start, selection.end);
        newText = newLine == true
            ? '\n$character\n$newText\n$character'
            : '$character$newText$character';
        return;
      case _FormatOption.formatStart:
        newText = value.text.substring(selection.start, selection.end);
        newText = '$character$newText';
        return;
      case _FormatOption.formatList:
        newText = value.text.substring(selection.start, selection.end);
        final lines = newText.split('\n');
        var orderedIndex = 0;

        for (var i = 0; i < lines.length; i++) {
          if (lines[i].isNotEmpty) {
            if (orderedList == true) {
              lines[i] = '${orderedIndex + 1}. ${lines[i]}';
              orderedIndex++;
            } else {
              lines[i] = '$character${lines[i]}';
            }
          }
        }

        newText = lines.join('\n');
        return;
      case _FormatOption.formatAddNew:
        newText = character!;
        return;
    }
  }

  TextEditingValue _apply() {
    final selection = value.selection;
    var baseOffset = 0;
    var extentOffset = 0;
    final text = '$beforeText$newText$afterText';

    switch (formatOption) {
      case _FormatOption.formatStartEnd:
        if (textApplyOption == _TextApplyOption.selectionHasCharacter ||
            textApplyOption == _TextApplyOption.outsideSelectionHasCharacter) {
          baseOffset = selection.start - character!.length;
          extentOffset = selection.end - character!.length;
        } else {
          baseOffset = selection.start + character!.length;
          extentOffset = selection.end + character!.length;
          if (newLine != null) {
            baseOffset += 2;
            extentOffset += 2;
          }
        }
        break;
      case _FormatOption.formatStart:
        if (textApplyOption == _TextApplyOption.selectionHasCharacter ||
            textApplyOption == _TextApplyOption.outsideSelectionHasCharacter) {
          baseOffset = selection.start - character!.length;
          extentOffset = selection.end - character!.length;
        } else {
          baseOffset = selection.start + character!.length;
          extentOffset = selection.end + character!.length;
        }
        break;
      case _FormatOption.formatList:
        final lines = newText.split('\n');
        var index = 0;
        for (final line in lines) {
          if (line.isNotEmpty) {
            index++;
          }
        }
        if (textApplyOption == _TextApplyOption.selectionHasCharacter ||
            textApplyOption == _TextApplyOption.outsideSelectionHasCharacter) {
          if (orderedList == true) {
            baseOffset = selection.end - 3 * index;
            extentOffset = selection.end - 3 * index;
          } else {
            baseOffset = selection.end - 2 * index;
            extentOffset = selection.end - 2 * index;
          }
        } else if (orderedList == true) {
          baseOffset = selection.end + 3 * index;
          extentOffset = selection.end + 3 * index;
        } else {
          baseOffset = selection.end + 2 * index;
          extentOffset = selection.end + 2 * index;
        }
        break;
      case _FormatOption.formatAddNew:
        if (textApplyOption == _TextApplyOption.selectionHasCharacter ||
            textApplyOption == _TextApplyOption.outsideSelectionHasCharacter) {
          baseOffset = selection.start - character!.length;
          extentOffset = selection.start - character!.length;
        } else {
          baseOffset = selection.start + character!.length;
          extentOffset = selection.start + character!.length;
        }
        break;
    }

    return value.copyWith(
      text: text,
      selection: TextSelection(
        baseOffset: _clampOffset(baseOffset, text.length),
        extentOffset: _clampOffset(extentOffset, text.length),
      ),
      composing: TextRange.empty,
    );
  }

  TextEditingValue _emptyAddNew() {
    final selection = value.selection;
    final text = value.text;
    var baseOffset = 0;
    var extentOffset = 0;
    late final String nextText;

    switch (formatOption) {
      case _FormatOption.formatStartEnd:
        final beforeText = text.substring(0, selection.start);
        final afterText = text.substring(selection.end);
        nextText = '$beforeText$character$placeholder$character$afterText';
        baseOffset = selection.start + character!.length;
        extentOffset = selection.end + placeholder.length + character!.length;
        break;
      case _FormatOption.formatStart:
        final beforeText = text.substring(0, selection.start);
        final afterText = text.substring(selection.end);
        nextText = '$beforeText$character$placeholder$afterText';
        baseOffset = selection.start + character!.length;
        extentOffset = selection.end + placeholder.length + character!.length;
        break;
      case _FormatOption.formatList:
        final newText = orderedList == true ? '1. ' : character!;
        final beforeText = text.substring(0, selection.start);
        final afterText = text.substring(selection.end);
        nextText = '$beforeText$newText$placeholder$afterText';
        baseOffset = selection.start + newText.length;
        extentOffset = selection.end + placeholder.length + newText.length;
        break;
      case _FormatOption.formatAddNew:
        final beforeText = text.substring(0, selection.start);
        final afterText = text.substring(selection.end);
        nextText = '$beforeText${character!}$afterText';
        baseOffset = selection.start + character!.length;
        extentOffset = selection.start + character!.length;
        break;
    }

    return value.copyWith(
      text: nextText,
      selection: TextSelection(
        baseOffset: _clampOffset(baseOffset, nextText.length),
        extentOffset: _clampOffset(extentOffset, nextText.length),
      ),
      composing: TextRange.empty,
    );
  }

  int _clampOffset(int offset, int maxLength) {
    if (offset <= 0) {
      return 0;
    }
    if (offset >= maxLength) {
      return maxLength;
    }
    return offset;
  }
}
