import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

typedef MarkdownLinkOpener = Future<bool> Function(Uri uri);

class MarkdownLinkBehavior {
  MarkdownLinkBehavior({
    MarkdownLinkOpener? onOpenLink,
    void Function(bool enabled)? onLinksEnabledChanged,
  }) : _onOpenLink = onOpenLink ?? _defaultOpenLink,
       _onLinksEnabledChanged = onLinksEnabledChanged;

  final Map<String, TapGestureRecognizer> _linkRecognizers = {};
  final MarkdownLinkOpener _onOpenLink;
  final void Function(bool enabled)? _onLinksEnabledChanged;

  bool _linksEnabled = false;

  bool get linksEnabled => _linksEnabled;

  void attach() {
    _linksEnabled = _computePreviewLinksEnabled();
    HardwareKeyboard.instance.addHandler(_handleHardwareKeyEvent);
  }

  void debugSetLinksEnabled(bool enabled) {
    _setLinksEnabled(enabled);
  }

  GestureRecognizer recognizerForUrl(String url) {
    return _linkRecognizers.putIfAbsent(url, () {
      return TapGestureRecognizer()
        ..onTap = () {
          final uri = Uri.tryParse(url);
          if (uri == null) {
            return;
          }
          unawaited(_onOpenLink(uri));
        };
    });
  }

  void detach() {
    HardwareKeyboard.instance.removeHandler(_handleHardwareKeyEvent);
    for (final recognizer in _linkRecognizers.values) {
      recognizer.dispose();
    }
    _linkRecognizers.clear();
  }

  bool _handleHardwareKeyEvent(KeyEvent event) {
    _setLinksEnabled(_computePreviewLinksEnabled());
    return false;
  }

  bool _computePreviewLinksEnabled() {
    final hardwareKeyboard = HardwareKeyboard.instance;
    return hardwareKeyboard.isControlPressed || hardwareKeyboard.isMetaPressed;
  }

  void _setLinksEnabled(bool enabled) {
    if (_linksEnabled == enabled) {
      return;
    }
    _linksEnabled = enabled;
    _onLinksEnabledChanged?.call(enabled);
  }

  static Future<bool> _defaultOpenLink(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
