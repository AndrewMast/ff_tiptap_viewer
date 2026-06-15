import 'package:flutter/widgets.dart';

import '../model/tiptap_node.dart';
import '../render/tiptap_renderer.dart';
import 'tiptap_extension.dart';

/// `blockquote` → a left border bar with padded block children.
class Blockquote extends TiptapBlockExtension {
  const Blockquote();

  @override
  String get type => 'blockquote';

  @override
  Widget buildBlock(TiptapRenderer r, TiptapNode node) {
    final t = r.theme;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: t.blockquoteBorderColor,
            width: t.blockquoteBorderWidth,
          ),
        ),
      ),
      padding: t.blockquotePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: r.buildBlockChildren(node.content),
      ),
    );
  }
}
