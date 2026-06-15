import 'package:flutter/widgets.dart';

import '../model/tiptap_node.dart';
import '../render/tiptap_renderer.dart';
import 'tiptap_extension.dart';

/// How a [HardBreak] renders.
///
/// To drop hard breaks entirely, leave [HardBreak] out of the active set
/// (e.g. `StarterKit(hardBreak: false)`) so the renderer strips them.
enum HardBreakMode {
  /// Render as a line break (`\n`). The default.
  newline,

  /// Render as a single space — keeps the surrounding text on one line.
  space,
}

/// `hardBreak` → a line break (or a space, per [mode]) inside the inline run.
class HardBreak extends TiptapInlineExtension {
  /// How the break renders.
  final HardBreakMode mode;

  const HardBreak({this.mode = HardBreakMode.newline});

  @override
  String get type => 'hardBreak';

  String get _char => mode == HardBreakMode.space ? ' ' : '\n';

  @override
  InlineSpan buildInline(TiptapRenderer r, TiptapNode node, TextStyle style) =>
      TextSpan(text: _char, style: style);

  @override
  String? toPlainText(TiptapNode node) => _char;
}
