import 'package:flutter/material.dart';

import 'extensions/starter_kit.dart';
import 'extensions/tiptap_extension.dart';
import 'model/tiptap_document.dart';
import 'render/tiptap_renderer.dart';
import 'tiptap_viewer.dart';
import 'tiptap_viewer_theme.dart';

/// Default extensions for `TiptapText` previews — a `const [StarterKit()]`.
const List<TiptapExtension> _defaultExtensions = <TiptapExtension>[StarterKit()];

/// Renders TipTap JSON flattened into a single inline run — a compact,
/// truncatable preview, rather than the block layout of [TiptapViewer].
///
/// The whole document collapses onto one [Text.rich]: inline runs concatenate,
/// block siblings (paragraphs, list items, blockquote lines, …) are joined with
/// [separator], and structure (indents, bullets, numbers) is dropped. Combine
/// [maxLines] + [overflow] for a line cap, and/or [maxChars] for a hard
/// character cap (truncated text gets [ellipsis] appended).
///
/// ```dart
/// TiptapText(
///   document: courseDescriptionJsonString, // String or Map
///   maxLines: 2,
///   overflow: TextOverflow.ellipsis,
///   includeStyle: false, // strip bold/italic/underline/strike → flat text
/// )
/// ```
///
/// For callers that only need a [String] (search, accessibility), use
/// [TiptapDocument.toPlainText] instead of this widget.
class TiptapText extends StatelessWidget {
  /// The document to render — a JSON [String] (the API format) or a decoded
  /// [Map]. Malformed/empty input renders nothing.
  final Object? document;

  /// Active extensions, used for marks (and inline styling like mentions). When
  /// null, a default `const [StarterKit()]` is used. Block layout is irrelevant
  /// here, but custom mark extensions are honored when [includeStyle] is true,
  /// and inline extensions (e.g. `Mention`) render their flattened form. Note
  /// `StarterKit` excludes `Mention`, so add it here to show mentions.
  final List<TiptapExtension>? extensions;

  /// Styling surface. When null, derived via [TiptapViewerTheme.fromContext].
  final TiptapViewerTheme? theme;

  /// When true (default), text marks (bold/italic/underline/strike) and mention
  /// color/weight are applied. When false, every run uses the theme's base text
  /// style — a flat, unstyled preview. Mirrors the FlutterFlow `includeStyle`.
  final bool includeStyle;

  /// Maximum number of lines before [overflow] applies. Null means unbounded.
  final int? maxLines;

  /// How visual overflow past [maxLines] is handled. Defaults to
  /// [TextOverflow.clip] (Flutter's `Text` default); pass
  /// [TextOverflow.ellipsis] for a trailing "…".
  ///
  /// Only takes effect when [maxLines] is set. With no line cap there is nothing
  /// to overflow against, so this is forced to [TextOverflow.clip] and the full
  /// text renders — otherwise the text engine would treat an ellipsis/fade
  /// overflow with a null [maxLines] as a single line.
  ///
  /// Note: with [TextOverflow.ellipsis] the trailing "…" is drawn by Flutter's
  /// text layout, which styles it with the run it truncates inside — so when the
  /// cut lands in marked text (and [includeStyle] is true) the "…" inherits that
  /// run's weight/color/decoration (e.g. a strikethrough running through the
  /// ellipsis). This is a Flutter limitation with no per-ellipsis style hook.
  /// The [maxChars] cap does not have this issue: it appends its own [ellipsis]
  /// in the base style. Use [maxChars] (or [includeStyle] `false`) if a clean,
  /// unstyled ellipsis matters.
  final TextOverflow overflow;

  /// Hard cap on the number of characters rendered. When the flattened text is
  /// longer, it is cut at this length and [ellipsis] is appended. Null means no
  /// character cap (rely on [maxLines]/[overflow] instead).
  final int? maxChars;

  /// Appended when [maxChars] truncates the text. Defaults to `…`; pass an empty
  /// string (or null) to cut without any marker.
  final String? ellipsis;

  /// Separator inserted between flattened block siblings. Defaults to a space.
  final String separator;

  /// Horizontal alignment of the text within its box.
  final TextAlign? textAlign;

  /// When true, wraps the output in a [SelectionArea]. Defaults to false —
  /// compact previews are usually tap-through, not selectable.
  final bool selectable;

  const TiptapText({
    super.key,
    required this.document,
    this.extensions,
    this.theme,
    this.includeStyle = true,
    this.maxLines,
    this.overflow = TextOverflow.clip,
    this.maxChars,
    this.ellipsis = '…',
    this.separator = ' ',
    this.textAlign,
    this.selectable = false,
  });

  /// Convenience factory for the common case of a raw JSON string.
  factory TiptapText.fromJson(
    String json, {
    Key? key,
    List<TiptapExtension>? extensions,
    TiptapViewerTheme? theme,
    bool includeStyle = true,
    int? maxLines,
    TextOverflow overflow = TextOverflow.clip,
    int? maxChars,
    String? ellipsis = '…',
    String separator = ' ',
    TextAlign? textAlign,
    bool selectable = false,
  }) {
    return TiptapText(
      key: key,
      document: json,
      extensions: extensions,
      theme: theme,
      includeStyle: includeStyle,
      maxLines: maxLines,
      overflow: overflow,
      maxChars: maxChars,
      ellipsis: ellipsis,
      separator: separator,
      textAlign: textAlign,
      selectable: selectable,
    );
  }

  @override
  Widget build(BuildContext context) {
    final parsed = TiptapDocument.parse(document);
    if (parsed == null) {
      return const SizedBox.shrink();
    }

    final resolvedTheme = theme ?? TiptapViewerTheme.fromContext(context);
    final renderer = TiptapRenderer(
      context: context,
      theme: resolvedTheme,
      registry: TiptapRegistry(extensions ?? _defaultExtensions),
    );

    var span = renderer.buildFlattenedSpan(
      parsed.root,
      includeStyle: includeStyle,
      separator: separator,
    );

    final cap = maxChars;
    if (cap != null && cap >= 0) {
      span = _capChars(span, cap, resolvedTheme.baseTextStyle);
    }

    // Guard a Flutter engine quirk: an ellipsis/fade overflow with no explicit
    // maxLines is treated as maxLines == 1 (it ellipsizes the first line). With
    // no line cap we want the full text, so fall back to clip — there is no line
    // budget to overflow against anyway.
    final effectiveOverflow = maxLines == null ? TextOverflow.clip : overflow;

    final child = Text.rich(
      span,
      maxLines: maxLines,
      overflow: effectiveOverflow,
      textAlign: textAlign,
    );
    return selectable ? SelectionArea(child: child) : child;
  }

  /// Truncates [span] to at most [max] characters of visible text, appending
  /// [ellipsis] when anything was cut.
  InlineSpan _capChars(InlineSpan span, int max, TextStyle base) {
    final truncator = _SpanTruncator(max);
    final capped = truncator.visit(span);
    final marker = ellipsis;
    if (!truncator.truncated || marker == null || marker.isEmpty) {
      return capped;
    }
    return TextSpan(
      style: base,
      children: <InlineSpan>[capped, TextSpan(text: marker, style: base)],
    );
  }
}

/// Walks an [InlineSpan] tree, keeping the first [max] characters and recording
/// whether any text was dropped. A [WidgetSpan] counts as one character.
class _SpanTruncator {
  _SpanTruncator(this.max);

  final int max;
  int _used = 0;
  bool truncated = false;

  InlineSpan visit(InlineSpan span) {
    if (span is TextSpan) {
      String? text = span.text;
      if (text != null && text.isNotEmpty) {
        final remaining = max - _used;
        if (remaining <= 0) {
          truncated = true;
          text = '';
        } else if (text.length > remaining) {
          text = text.substring(0, remaining);
          _used = max;
          truncated = true;
        } else {
          _used += text.length;
        }
      }

      List<InlineSpan>? children;
      final source = span.children;
      if (source != null && source.isNotEmpty) {
        children = <InlineSpan>[for (final c in source) visit(c)];
      }

      return TextSpan(
        text: text,
        style: span.style,
        recognizer: span.recognizer,
        children: children,
      );
    }

    // Any non-text span (e.g. a WidgetSpan) is one indivisible unit.
    if (_used >= max) {
      truncated = true;
      return const TextSpan(text: '');
    }
    _used += 1;
    return span;
  }
}
