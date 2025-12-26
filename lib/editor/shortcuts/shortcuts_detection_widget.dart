import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:markee/editor/shortcuts/intents.dart';

class ShortcutsDetectionWidget extends StatelessWidget {
  const ShortcutsDetectionWidget({
    super.key,
    required this.shortcutsHandler,
    required this.child,
  });

  final Function(Intent intent) shortcutsHandler;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.tab): TabIntent(),
        //if platform is macos
        if (Theme.of(context).platform == TargetPlatform.macOS) ...{
          LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyB):
              BoldIntent(),
          LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyI):
              ItalicIntent(),
          LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyU):
              StrikethroughIntent(),
        },
        //if platform is windows
        if (Theme.of(context).platform == TargetPlatform.windows ||
            Theme.of(context).platform == TargetPlatform.linux) ...{
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyB):
              BoldIntent(),
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyI):
              ItalicIntent(),
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyU):
              StrikethroughIntent(),
        },
      },
      child: Actions(
        actions: {
          TabIntent: CallbackAction(onInvoke: shortcutsHandler),
          BoldIntent: CallbackAction(onInvoke: shortcutsHandler),
          ItalicIntent: CallbackAction(onInvoke: shortcutsHandler),
          StrikethroughIntent: CallbackAction(onInvoke: shortcutsHandler),
        },
        child: child,
      ),
    );
  }
}
