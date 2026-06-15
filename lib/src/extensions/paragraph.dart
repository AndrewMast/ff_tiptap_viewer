import 'package:flutter/widgets.dart';

import '../model/tiptap_node.dart';
import '../render/tiptap_renderer.dart';
import 'tiptap_extension.dart';

/// `paragraph` → a `Text.rich` of its inline content (empty → spacer).
class Paragraph extends TiptapBlockExtension {
  const Paragraph();

  @override
  String get type => 'paragraph';

  @override
  Widget buildBlock(TiptapRenderer r, TiptapNode node) =>
      r.buildInlineContainer(node.content, r.theme.baseTextStyle);
}
