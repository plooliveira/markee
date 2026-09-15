import 'package:flutter/material.dart';
import 'package:markee/markee.dart';

void main() {
  runApp(const MarkeeExampleApp());
}

class MarkeeExampleApp extends StatelessWidget {
  const MarkeeExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Markee',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const EditorPage(),
    );
  }
}

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final _controller = TextEditingController(
    text: '''# Olá, Markee!

Escreva seu Markdown aqui e use a barra de ferramentas para formatar o texto.

Experimente **negrito**, *itálico* e `código`.

- Um editor simples
- Feito com Flutter
''',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Markee — Editor Markdown')),
      body: SafeArea(child: MarkdownEditor(controller: _controller)),
    );
  }
}
