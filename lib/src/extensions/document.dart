import 'package:flutter/widgets.dart';

import '../model/tiptap_node.dart';
import '../render/tiptap_renderer.dart';
import 'tiptap_extension.dart';

/// `doc` → renders its block children in a column. (The viewer normally starts
/// from the root directly; this exists for completeness if a `doc` is nested.)
class Doc extends TiptapBlockExtension {
  const Doc();

  @override
  String get type => 'doc';

  @override
  Widget buildBlock(TiptapRenderer r, TiptapNode node) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: r.buildBlockChildren(node.content),
      );
}
