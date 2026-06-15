import 'package:flutter/widgets.dart';

import '../model/tiptap_node.dart';
import '../render/tiptap_renderer.dart';
import 'tiptap_extension.dart';

/// `heading` → a `Text.rich` of its inline content styled by level.
///
/// The level comes from `attrs['level']` (TipTap stores 1–6). The visual style
/// is `TiptapViewerTheme.headingStyle(level)`; this extension only picks the
/// level and recurses into inline content. When absent from the active set, a
/// heading [unwrap]s to plain paragraph text.
class Heading extends TiptapBlockExtension {
  const Heading();

  @override
  String get type => 'heading';

  @override
  Widget buildBlock(TiptapRenderer r, TiptapNode node) {
    final level = _coerceLevel(node.attrs['level']);
    return r.buildInlineContainer(node.content, r.theme.headingStyle(level));
  }

  /// Reads the `level` attribute defensively (the wire format is untrusted at
  /// render time): accepts an int, a numeric, or a numeric string, clamps to
  /// 1–6, and falls back to 1.
  static int _coerceLevel(Object? raw) {
    int value;
    if (raw is int) {
      value = raw;
    } else if (raw is num) {
      value = raw.toInt();
    } else if (raw is String) {
      value = int.tryParse(raw) ?? 1;
    } else {
      value = 1;
    }
    if (value < 1) return 1;
    if (value > 6) return 6;
    return value;
  }
}
