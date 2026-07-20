import 'package:flutter/widgets.dart';
import 'package:markee/src/markdown/markdown_document.dart';
import 'package:markee/src/markdown/markdown_link_behavior.dart';
import 'package:markee/src/markdown/markdown_preview_engine.dart';
import 'package:markee/src/markdown/markdown_selection_mapper.dart';

export 'package:markee/src/markdown/markdown_link_behavior.dart'
    show MarkdownLinkOpener;

class MarkdownEditingController extends TextEditingController {
  MarkdownEditingController({
    super.text,
    MarkdownLinkOpener? onOpenLink,
  }) {
    _linkBehavior = MarkdownLinkBehavior(
      onOpenLink: onOpenLink,
      onLinksEnabledChanged: (enabled) {
        notifyListeners();
      },
    );
    _document = MarkdownDocument.fromText(text);
    _linkBehavior.attach();
  }

  final MarkdownPreviewEngine _previewEngine = MarkdownPreviewEngine();
  final MarkdownSelectionMapper _selectionMapper = const MarkdownSelectionMapper();
  late final MarkdownLinkBehavior _linkBehavior;

  late MarkdownDocument _document;

  @visibleForTesting
  int get debugPreviewParseCount => _previewEngine.debugPreviewParseCount;

  @visibleForTesting
  bool get debugPreviewLinksEnabled => _linkBehavior.linksEnabled;

  @visibleForTesting
  void debugSetPreviewLinksEnabled(bool enabled) {
    _linkBehavior.debugSetLinksEnabled(enabled);
  }

  @override
  set value(TextEditingValue newValue) {
    final previousValue = value;
    final document = _document.text == newValue.text
        ? _document
        : MarkdownDocument.fromText(newValue.text);
    final line = document.lineAt(document.lineIndexForOffset(newValue.selection.extentOffset));
    final parsedLine = _previewEngine.parsedLineFor(line);
    final adjustedValue = _selectionMapper.adjustSelectionForPreviewReveal(
      document: document,
      previousValue: previousValue,
      nextValue: newValue,
      parsedLine: parsedLine,
      line: line,
    );
    super.value = adjustedValue;

    if (previousValue.text == adjustedValue.text) {
      return;
    }

    _previewEngine.invalidateForTextChange(previousValue.text, adjustedValue.text);
    _document = document;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (_document.text != value.text) {
      _document = MarkdownDocument.fromText(value.text);
      _previewEngine.clearCache();
    }

    return _previewEngine.buildTextSpan(
      document: _document,
      value: value,
      baseStyle: style ?? const TextStyle(),
      withComposing: withComposing,
      linksEnabled: _linkBehavior.linksEnabled,
      linkRecognizerBuilder: _linkBehavior.recognizerForUrl,
    );
  }

  @override
  void dispose() {
    _linkBehavior.detach();
    super.dispose();
  }
}
