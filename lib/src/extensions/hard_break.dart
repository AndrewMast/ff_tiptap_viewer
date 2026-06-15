import 'package:flutter/widgets.dart';

import '../model/tiptap_node.dart';
import '../render/tiptap_renderer.dart';
import 'tiptap_extension.dart';

/// `hardBreak` → a line break (`\n`) inside the current inline run.
class HardBreak extends TiptapInlineExtension {
  const HardBreak();

  @override
  String get type => 'hardBreak';

  @override
  InlineSpan buildInline(TiptapRenderer r, TiptapNode node, TextStyle style) =>
      TextSpan(text: '\n', style: style);

  @override
  String? toPlainText(TiptapNode node) => '\n';
}
