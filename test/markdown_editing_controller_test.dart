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
      final boldSegment = _descendantTextSpans(secondLine).firstWhere(
        (child) => child.text == 'bold',
      );

      expect(firstLine.text, '# Title\n');
      expect(secondLine.text, isNull);
      expect(boldSegment.text, 'bold');
      expect(boldSegment.style?.fontWeight, FontWeight.w700);
    });

    testWidgets('reveals only the inline token under the cursor', (tester) async {
      final text = 'Every conversation has **Correspondence** and more text.';
      final controller = MarkdownEditingController(text: text);
      controller.selection = TextSelection.collapsed(
        offset: text.indexOf('Correspondence') + 3,
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

      final lineSpan = span.children!.single as TextSpan;
      final chunks = lineSpan.children!.whereType<TextSpan>().toList();

      expect(chunks.any((chunk) => chunk.text == '**Correspondence**'), isTrue);
      expect(chunks.any((chunk) => chunk.text == text), isFalse);
      expect(
        chunks
            .where((chunk) => chunk.text == '**Correspondence**')
            .single
            .style,
        const TextStyle(fontSize: 16),
      );
    });

    test('shifts cursor into revealed inline token to keep backspace aligned', () {
      final text = 'Every conversation has **Correspondence** and more text.';
      final controller = MarkdownEditingController(text: text);

      controller.selection = const TextSelection.collapsed(offset: 0);

      final previewOffset = text.indexOf('Correspondence') + 1;
      controller.selection = TextSelection.collapsed(offset: previewOffset);

      expect(
        controller.selection.extentOffset,
        previewOffset + 2,
      );
    });

    testWidgets('keeps paragraph preview when cursor is outside inline token', (
      tester,
    ) async {
      final text = 'Every conversation has **Correspondence** and more text.';
      final controller = MarkdownEditingController(text: text);
      controller.selection = const TextSelection.collapsed(offset: 5);
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

      final lineSpan = span.children!.single as TextSpan;
      final chunks = lineSpan.children!.whereType<TextSpan>().toList();

      expect(chunks.any((chunk) => chunk.text == '**Correspondence**'), isFalse);
      expect(
        chunks.expand((chunk) => chunk.children?.whereType<TextSpan>() ?? const <TextSpan>[]),
        isNotEmpty,
      );
    });

    testWidgets('reveals the entire heading line instead of inline heading tokens', (
      tester,
    ) async {
      final text = '# Heading **bold**';
      final controller = MarkdownEditingController(text: text);
      controller.selection = TextSelection.collapsed(
        offset: text.indexOf('bold') + 1,
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

      expect((span.children!.single as TextSpan).text, text);
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
      expect(controller.debugPreviewParseCount, firstParseCount + 1);

      controller.value = controller.value.copyWith(
        text: 'alpha!\n**beta**\ngamma!',
        selection: const TextSelection.collapsed(offset: 0),
      );
      controller.buildTextSpan(
        context: context,
        style: const TextStyle(fontSize: 16),
        withComposing: false,
      );
      expect(controller.debugPreviewParseCount, firstParseCount + 2);
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
        final previousLineBoldSegment = _descendantTextSpans(
          formattedPreviousLine,
        ).firstWhere((child) => child.text == 'bold');

        expect(formattedPreviousLine.text, isNull);
        expect(previousLineBoldSegment.text, 'bold');
        expect(currentEmptyLine.toPlainText(), isEmpty);
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
      final linkTextSpanWithoutModifier = _descendantTextSpans(lineSpan)
          .firstWhere((child) => child.text == 'My Link text');
      final hiddenUrlSpan = _descendantTextSpans(lineSpan)
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
      final linkTextSpanWithModifier = _descendantTextSpans(interactiveLineSpan)
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

Iterable<TextSpan> _descendantTextSpans(InlineSpan span) sync* {
  if (span is TextSpan) {
    yield span;
    final children = span.children;
    if (children != null) {
      for (final child in children) {
        yield* _descendantTextSpans(child);
      }
    }
  }
}
