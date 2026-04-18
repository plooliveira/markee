import 'package:flutter/widgets.dart';
import 'package:markee/src/markdown/markdown_formatter.dart';

class TabIntent extends Intent {
  const TabIntent();
}

class MarkdownShortcutIntent extends Intent {
  const MarkdownShortcutIntent(this.action, {this.option});

  final MarkdownToolbarOption action;
  final int? option;
}
