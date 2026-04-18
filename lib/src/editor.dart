import 'package:flutter/material.dart';
import 'package:markee/src/markdown/markdown_editing_controller.dart';
import 'package:markee/src/shortcuts/shortcuts_detection_widget.dart';
import 'package:markee/src/shortcuts/markdown_shortcut_map.dart';
import 'package:markee/src/toolbar/toolbar.dart';

class MarkdownEditor extends StatefulWidget {
  const MarkdownEditor({
    super.key,
    this.controller,
    this.focusNode,
    this.shortcutMap,
  });

  final MarkdownEditingController? controller;
  final FocusNode? focusNode;
  final MarkdownShortcutMap? shortcutMap;

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  late final FocusNode _focusNode;
  late final MarkdownEditingController _controller;
  Function(Intent intent) shortcutsHandler = (intent) {};

  bool get _ownsFocusNode => widget.focusNode == null;

  bool get _ownsController => widget.controller == null;

  @override
  void initState() {
    _focusNode = widget.focusNode ?? FocusNode();
    _controller = widget.controller ?? MarkdownEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            MarkdownToolbar(
              controller: _controller,
              focusNode: _focusNode,
              useIncludedTextField: false,
              onShortcuts: (handle) {
                shortcutsHandler = handle;
              },
            ),
            SizedBox(height: 24),
            Expanded(
              child: ShortcutsDetectionWidget(
                shortcutsHandler: shortcutsHandler,
                shortcutMap: widget.shortcutMap,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: true,
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                  cursorColor: Colors.black,
                  decoration: InputDecoration.collapsed(hintText: null),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
