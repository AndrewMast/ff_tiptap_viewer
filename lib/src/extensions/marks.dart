import 'package:flutter/widgets.dart';

import '../model/tiptap_mark.dart';
import '../render/tiptap_renderer.dart';
import 'tiptap_extension.dart';

/// Adds a [TextDecoration] to [style], combining with any existing decoration
/// so underline + strike can coexist on the same text.
TextStyle _addDecoration(TextStyle style, TextDecoration decoration) {
  final existing = style.decoration;
  final combined = (existing == null || existing == TextDecoration.none)
      ? decoration
      : TextDecoration.combine(<TextDecoration>[existing, decoration]);
  return style.copyWith(decoration: combined);
}

/// `bold` mark → applies the theme's bold weight.
class Bold extends TiptapMarkExtension {
  const Bold();

  @override
  String get type => 'bold';

  @override
  TextStyle apply(TiptapRenderer r, TiptapMark mark, TextStyle style) =>
      style.copyWith(fontWeight: r.theme.boldWeight);
}

/// `italic` mark → `FontStyle.italic`.
class Italic extends TiptapMarkExtension {
  const Italic();

  @override
  String get type => 'italic';

  @override
  TextStyle apply(TiptapRenderer r, TiptapMark mark, TextStyle style) =>
      style.copyWith(fontStyle: FontStyle.italic);
}

/// `underline` mark → `TextDecoration.underline`.
class Underline extends TiptapMarkExtension {
  const Underline();

  @override
  String get type => 'underline';

  @override
  TextStyle apply(TiptapRenderer r, TiptapMark mark, TextStyle style) =>
      _addDecoration(style, TextDecoration.underline);
}

/// `strike` mark → `TextDecoration.lineThrough`.
class Strike extends TiptapMarkExtension {
  const Strike();

  @override
  String get type => 'strike';

  @override
  TextStyle apply(TiptapRenderer r, TiptapMark mark, TextStyle style) =>
      _addDecoration(style, TextDecoration.lineThrough);
}
