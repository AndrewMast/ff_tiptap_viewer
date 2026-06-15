import 'package:flutter/widgets.dart';

import '../model/tiptap_node.dart';
import '../render/tiptap_renderer.dart';
import 'tiptap_extension.dart';

/// `text` → an inline span with its marks applied (including any tap recognizer
/// a mark contributes, e.g. `link`). The renderer also handles text
/// intrinsically, so omitting this extension does not drop text.
class TextNode extends TiptapInlineExtension {
  const TextNode();

  @override
  String get type => 'text';

  @override
  DisabledBehavior get disabledBehavior => DisabledBehavior.unwrap;

  @override
  InlineSpan buildInline(TiptapRenderer r, TiptapNode node, TextStyle style) =>
      r.buildTextSpan(node, style);

  @override
  String? toPlainText(TiptapNode node) {
    final value = node.text;
    return (value == null || value.isEmpty) ? null : value;
  }
}
