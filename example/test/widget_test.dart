import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markee/markee.dart';
import 'package:markee_example/main.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(1280, 800)]) {
    testWidgets('edits and formats Markdown at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MarkeeExampleApp());
      await tester.pumpAndSettle();

      final editor = tester.widget<MarkdownEditor>(find.byType(MarkdownEditor));
      final controller = editor.controller!;
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller, same(controller));
      expect(controller.text, contains('# Olá, Markee!'));

      await tester.enterText(find.byType(TextField), 'Meu texto');
      expect(controller.text, 'Meu texto');

      controller.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 9,
      );
      await tester.pump();
      await tester.tap(find.byTooltip('Bold'));
      await tester.pump();

      expect(controller.text, '**Meu texto**');
      expect(tester.takeException(), isNull);
    });
  }
}
