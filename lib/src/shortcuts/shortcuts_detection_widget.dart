import 'package:flutter/material.dart';
import 'package:markee/src/shortcuts/intents.dart';
import 'package:markee/src/shortcuts/markdown_shortcut_map.dart';

class ShortcutsDetectionWidget extends StatelessWidget {
  const ShortcutsDetectionWidget({
    super.key,
    required this.shortcutsHandler,
    required this.child,
    this.shortcutMap,
  });

  final Function(Intent intent) shortcutsHandler;
  final Widget child;
  final MarkdownShortcutMap? shortcutMap;

  @override
  Widget build(BuildContext context) {
    final resolvedShortcutMap =
        shortcutMap ?? MarkdownShortcutMap.defaultForPlatform(Theme.of(context).platform);

    return Shortcuts(
      shortcuts: resolvedShortcutMap.shortcuts,
      child: Actions(
        actions: {
          TabIntent: CallbackAction(onInvoke: shortcutsHandler),
          MarkdownShortcutIntent: CallbackAction<MarkdownShortcutIntent>(
            onInvoke: (intent) {
              shortcutsHandler(intent);
              return null;
            },
          ),
        },
        child: child,
      ),
    );
  }
}
