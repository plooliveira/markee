import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markee/src/markdown/markdown_editing_controller.dart';

void main() {
  group('MarkdownEditingController', () {
    testWidgets('renders only the active line in raw mode', (tester) async {
      final controller = MarkdownEditingController(text: '# Title\n**bold**');
      controller.selection = const TextSelection.collapsed(offset: 0);
      late BuildContext context;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (capturedContext) {
              context = capturedContext;
              return const SizedBox();
            },
          ),
        ),
      );

      final span = controller.buildTextSpan(
        context: context,
        style: const TextStyle(fontSize: 16),
        withComposing: false,
      );

      expect(span.children, hasLength(2));

      final firstLine = span.children![0] as TextSpan;
      final secondLine = span.children![1] as TextSpan;
      final secondLineChildren = secondLine.children!;
      final boldSegment = secondLineChildren[1] as TextSpan;

      expect(firstLine.text, '# Title\n');
      expect(secondLine.text, isNull);
      expect(boldSegment.text, 'bold');
      expect(boldSegment.style?.fontWeight, FontWeight.w700);
    });

    testWidgets('expands raw editing to the whole code block', (tester) async {
      final text = 'before\n```\ncode\n```\nafter';
      final controller = MarkdownEditingController(text: text);
      controller.selection = TextSelection.collapsed(
        offset: text.indexOf('code') + 1,
      );
      late BuildContext context;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (capturedContext) {
              context = capturedContext;
              return const SizedBox();
            },
          ),
        ),
      );

      final span = controller.buildTextSpan(
        context: context,
        style: const TextStyle(fontSize: 16),
        withComposing: false,
      );

      expect((span.children![1] as TextSpan).text, '```\n');
      expect((span.children![2] as TextSpan).text, 'code\n');
      expect((span.children![3] as TextSpan).text, '```\n');
    });

    testWidgets('reuses cached preview lines for unchanged lines', (
      tester,
    ) async {
      final controller = MarkdownEditingController(
        text: 'alpha\n**beta**\ngamma',
      );
      controller.selection = const TextSelection.collapsed(offset: 0);
      late BuildContext context;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (capturedContext) {
              context = capturedContext;
              return const SizedBox();
            },
          ),
        ),
      );

      controller.buildTextSpan(
        context: context,
        style: const TextStyle(fontSize: 16),
        withComposing: false,
      );
      final firstParseCount = controller.debugPreviewParseCount;

      controller.buildTextSpan(
        context: context,
        style: const TextStyle(fontSize: 16),
        withComposing: false,
      );
      expect(controller.debugPreviewParseCount, firstParseCount);

      controller.value = controller.value.copyWith(
        text: 'alpha!\n**beta**\ngamma',
        selection: const TextSelection.collapsed(offset: 0),
      );
      controller.buildTextSpan(
        context: context,
        style: const TextStyle(fontSize: 16),
        withComposing: false,
      );
      expect(controller.debugPreviewParseCount, firstParseCount);

      controller.value = controller.value.copyWith(
        text: 'alpha!\n**beta**\ngamma!',
        selection: const TextSelection.collapsed(offset: 0),
      );
      controller.buildTextSpan(
        context: context,
        style: const TextStyle(fontSize: 16),
        withComposing: false,
      );
      expect(controller.debugPreviewParseCount, firstParseCount + 1);
    });

    testWidgets(
      'formats previous line immediately after enter creates a new line',
      (tester) async {
        final controller = MarkdownEditingController(text: '**bold**\n');
        controller.selection = const TextSelection.collapsed(offset: 9);
        late BuildContext context;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(
              builder: (capturedContext) {
                context = capturedContext;
                return const SizedBox();
              },
            ),
          ),
        );

        final span = controller.buildTextSpan(
          context: context,
          style: const TextStyle(fontSize: 16),
          withComposing: false,
        );

        expect(span.children, hasLength(2));
        final formattedPreviousLine = span.children![0] as TextSpan;
        final currentEmptyLine = span.children![1] as TextSpan;
        final previousLineBoldSegment =
            (formattedPreviousLine.children![1] as TextSpan);

        expect(formattedPreviousLine.text, isNull);
        expect(previousLineBoldSegment.text, 'bold');
        expect(currentEmptyLine.text, isEmpty);
      },
    );

    testWidgets('renders preview link as clickable text only with modifier', (
      tester,
    ) async {
      Uri? openedUri;
      final controller = MarkdownEditingController(
        text: '[My Link text](https://example.com)\n',
        onOpenLink: (uri) async {
          openedUri = uri;
          return true;
        },
      );
      controller.selection = TextSelection.collapsed(offset: controller.text.length);
      late BuildContext context;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (capturedContext) {
              context = capturedContext;
              return const SizedBox();
            },
          ),
        ),
      );

      final span = controller.buildTextSpan(
        context: context,
        style: const TextStyle(fontSize: 16),
        withComposing: false,
      );

      final lineSpan = span.children!.first as TextSpan;
      final linkTextSpanWithoutModifier = lineSpan.children!
          .whereType<TextSpan>()
          .firstWhere((child) => child.text == 'My Link text');
      final hiddenUrlSpan = lineSpan.children!
          .whereType<TextSpan>()
          .firstWhere((child) => child.text == 'https://example.com');

      expect(linkTextSpanWithoutModifier.recognizer, isNull);
      expect(hiddenUrlSpan.style?.color, Colors.transparent);

      controller.debugSetPreviewLinksEnabled(true);
      final interactiveSpan = controller.buildTextSpan(
        context: context,
        style: const TextStyle(fontSize: 16),
        withComposing: false,
      );
      final interactiveLineSpan = interactiveSpan.children!.first as TextSpan;
      final linkTextSpanWithModifier = interactiveLineSpan.children!
          .whereType<TextSpan>()
          .firstWhere((child) => child.text == 'My Link text');

      expect(linkTextSpanWithModifier.recognizer, isA<TapGestureRecognizer>());

      final recognizer =
          linkTextSpanWithModifier.recognizer! as TapGestureRecognizer;
      recognizer.onTap?.call();
      await tester.pump();

      expect(openedUri, Uri.parse('https://example.com'));
    });
  });
}
