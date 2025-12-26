import 'package:flutter/material.dart';
import 'package:markee/editor/shortcuts/shortcuts_detection_widget.dart';
import 'package:markee/editor/toolbar/toolbar.dart';

class MarkdownEditor extends StatefulWidget {
  const MarkdownEditor({super.key});

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();
  Function(Intent intent) shortcutsHandler = (intent) {};

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
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
            ShortcutsDetectionWidget(
              shortcutsHandler: shortcutsHandler,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                style: const TextStyle(color: Colors.black, fontSize: 16),
                cursorColor: Colors.black,
                minLines: 25,
                maxLines: null,
                decoration: InputDecoration.collapsed(hintText: null),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
