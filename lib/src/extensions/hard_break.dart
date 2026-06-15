import 'package:flutter/widgets.dart';

import '../model/tiptap_node.dart';
import '../render/tiptap_renderer.dart';
import 'tiptap_extension.dart';

/// How a [HardBreak] collapses in the **flattened / plain-text** path
/// (`TiptapText`, `toPlainText`).
///
/// This does **not** affect the full [TiptapViewer], which always renders a hard
/// break as a real line break (`\n`) — it only controls the single-run output.
enum HardBreakFlatten {
  /// Keep the line break (`\n`) — the flattened text still breaks at this point.
  newline,

  /// Replace the break with a single space — keeps everything on one line.
  space,

  /// Contribute nothing — adjacent runs join directly ("complete flatten").
  remove,
}

/// `hardBreak` → a line break (`\n`) inside the current inline run.
///
/// In flattened previews / `toPlainText`, its representation is governed by
/// [flatten] (default [HardBreakFlatten.newline]).
class HardBreak extends TiptapInlineExtension {
  /// How the break collapses in the flattened / plain-text path.
  final HardBreakFlatten flatten;

  const HardBreak({this.flatten = HardBreakFlatten.newline});

  @override
  String get type => 'hardBreak';

  @override
  InlineSpan buildInline(TiptapRenderer r, TiptapNode node, TextStyle style) =>
      TextSpan(text: '\n', style: style);

  @override
  String? toPlainText(TiptapNode node) {
    switch (flatten) {
      case HardBreakFlatten.newline:
        return '\n';
      case HardBreakFlatten.space:
        return ' ';
      case HardBreakFlatten.remove:
        return null;
    }
  }
}
