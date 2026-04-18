import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:markee/src/markdown/markdown_formatter.dart';
import 'package:markee/src/shortcuts/intents.dart';

class MarkdownShortcutMap {
  const MarkdownShortcutMap(this.shortcuts);

  final Map<ShortcutActivator, Intent> shortcuts;

  factory MarkdownShortcutMap.defaultForPlatform(TargetPlatform platform) {
    final isMacOS = platform == TargetPlatform.macOS;

    SingleActivator activator(
      LogicalKeyboardKey trigger, {
      bool shift = false,
      bool alt = false,
    }) {
      return SingleActivator(
        trigger,
        control: !isMacOS,
        meta: isMacOS,
        shift: shift,
        alt: alt,
      );
    }

    return MarkdownShortcutMap({
      const SingleActivator(LogicalKeyboardKey.tab): const TabIntent(),
      activator(LogicalKeyboardKey.keyB):
          const MarkdownShortcutIntent(MarkdownToolbarOption.bold),
      activator(LogicalKeyboardKey.keyI):
          const MarkdownShortcutIntent(MarkdownToolbarOption.italic),
      activator(LogicalKeyboardKey.keyX, shift: true):
          const MarkdownShortcutIntent(MarkdownToolbarOption.strikethrough),
      activator(LogicalKeyboardKey.keyK):
          const MarkdownShortcutIntent(MarkdownToolbarOption.link),
      activator(LogicalKeyboardKey.digit1, alt: true):
          const MarkdownShortcutIntent(MarkdownToolbarOption.heading, option: 0),
      activator(LogicalKeyboardKey.digit2, alt: true):
          const MarkdownShortcutIntent(MarkdownToolbarOption.heading, option: 1),
      activator(LogicalKeyboardKey.digit3, alt: true):
          const MarkdownShortcutIntent(MarkdownToolbarOption.heading, option: 2),
      activator(LogicalKeyboardKey.digit4, alt: true):
          const MarkdownShortcutIntent(MarkdownToolbarOption.heading, option: 3),
      activator(LogicalKeyboardKey.digit5, alt: true):
          const MarkdownShortcutIntent(MarkdownToolbarOption.heading, option: 4),
      activator(LogicalKeyboardKey.digit6, alt: true):
          const MarkdownShortcutIntent(MarkdownToolbarOption.heading, option: 5),
      activator(LogicalKeyboardKey.keyC, alt: true):
          const MarkdownShortcutIntent(MarkdownToolbarOption.code),
      activator(LogicalKeyboardKey.keyI, alt: true):
          const MarkdownShortcutIntent(MarkdownToolbarOption.image),
      activator(LogicalKeyboardKey.keyU, alt: true):
          const MarkdownShortcutIntent(MarkdownToolbarOption.unorderedList),
      activator(LogicalKeyboardKey.keyO, alt: true):
          const MarkdownShortcutIntent(MarkdownToolbarOption.orderedList),
      activator(LogicalKeyboardKey.keyX, alt: true):
          const MarkdownShortcutIntent(MarkdownToolbarOption.checkbox),
      activator(LogicalKeyboardKey.keyQ, alt: true):
          const MarkdownShortcutIntent(MarkdownToolbarOption.quote),
      activator(LogicalKeyboardKey.keyH, alt: true):
          const MarkdownShortcutIntent(MarkdownToolbarOption.horizontalRule),
    });
  }
}
