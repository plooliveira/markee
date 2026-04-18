import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:markee/src/markdown/inline_preview_parser.dart';

class MarkdownSpanBuilder {
  const MarkdownSpanBuilder();

  TextSpan buildLine({
    required MarkdownPreviewLine line,
    required TextStyle baseStyle,
    required bool linksEnabled,
    GestureRecognizer? Function(String url)? linkRecognizerBuilder,
  }) {
    return TextSpan(
      children: line.segments
          .map(
            (segment) => TextSpan(
              text: segment.text,
              style: _styleForSegment(
                segment.style,
                baseStyle,
                headingLevel: line.headingLevel,
              ),
              recognizer: !linksEnabled || segment.linkUrl == null
                  ? null
                  : linkRecognizerBuilder?.call(segment.linkUrl!),
            ),
          )
          .toList(growable: false),
    );
  }

  TextStyle _styleForSegment(
    MarkdownSegmentStyle style,
    TextStyle baseStyle, {
    int? headingLevel,
  }) {
    switch (style) {
      case MarkdownSegmentStyle.hiddenSyntax:
        final hiddenFontSize = math.max((baseStyle.fontSize ?? 14) * 0.05, 0.1);
        return baseStyle.copyWith(
          color: Colors.transparent,
          fontSize: hiddenFontSize,
          height: 0.1,
        );
      case MarkdownSegmentStyle.headingText:
        final level = headingLevel ?? 1;
        return baseStyle.copyWith(
          fontSize: (baseStyle.fontSize ?? 16) + (7 - level).toDouble(),
          fontWeight: FontWeight.w700,
        );
      case MarkdownSegmentStyle.listMarker:
        return baseStyle.copyWith(
          color: Colors.black54,
          fontWeight: FontWeight.w600,
        );
      case MarkdownSegmentStyle.quoteMarker:
        return baseStyle.copyWith(
          color: Colors.black54,
          fontStyle: FontStyle.italic,
        );
      case MarkdownSegmentStyle.strong:
        return baseStyle.copyWith(fontWeight: FontWeight.w700);
      case MarkdownSegmentStyle.emphasis:
        return baseStyle.copyWith(fontStyle: FontStyle.italic);
      case MarkdownSegmentStyle.strikethrough:
        return baseStyle.copyWith(decoration: TextDecoration.lineThrough);
      case MarkdownSegmentStyle.inlineCode:
        return baseStyle.copyWith(
          fontFamily: 'monospace',
          backgroundColor: const Color(0x11000000),
        );
      case MarkdownSegmentStyle.linkText:
        return baseStyle.copyWith(
          color: Colors.blue.shade700,
          decoration: TextDecoration.underline,
        );
      case MarkdownSegmentStyle.linkDestination:
        return baseStyle.copyWith(color: Colors.blueGrey.shade400);
      case MarkdownSegmentStyle.imageAlt:
        return baseStyle.copyWith(
          fontStyle: FontStyle.italic,
          color: Colors.black87,
        );
      case MarkdownSegmentStyle.imageSource:
        return baseStyle.copyWith(color: Colors.blueGrey.shade400);
      case MarkdownSegmentStyle.horizontalRule:
        return baseStyle.copyWith(color: Colors.black26);
      case MarkdownSegmentStyle.code:
        return baseStyle.copyWith(
          fontFamily: 'monospace',
          color: Colors.black87,
        );
      case MarkdownSegmentStyle.codeFence:
        return baseStyle.copyWith(
          fontFamily: 'monospace',
          color: Colors.black38,
        );
      case MarkdownSegmentStyle.plain:
        return baseStyle;
    }
  }
}
