import 'package:flutter/widgets.dart';

import '../model/tiptap_node.dart';
import '../render/tiptap_renderer.dart';
import 'tiptap_extension.dart';

/// `horizontalRule` → a thin divider line with vertical breathing room.
///
/// It is a content-free leaf, so when absent from the active set it [strip]s
/// (there is nothing to unwrap to).
class HorizontalRule extends TiptapBlockExtension {
  const HorizontalRule();

  @override
  String get type => 'horizontalRule';

  @override
  DisabledBehavior get disabledBehavior => DisabledBehavior.strip;

  @override
  Widget buildBlock(TiptapRenderer r, TiptapNode node) {
    final t = r.theme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: t.hrSpacing),
      child: Container(height: t.hrThickness, color: t.hrColor),
    );
  }
}
