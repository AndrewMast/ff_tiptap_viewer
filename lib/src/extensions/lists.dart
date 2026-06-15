import 'package:flutter/widgets.dart';

import '../model/tiptap_node.dart';
import '../render/tiptap_renderer.dart';
import 'tiptap_extension.dart';

/// `listItem` → its block children in a column. Lists drive the markers; this
/// is the fallback when a `listItem` is encountered outside a list.
class ListItem extends TiptapBlockExtension {
  const ListItem();

  @override
  String get type => 'listItem';

  @override
  Widget buildBlock(TiptapRenderer r, TiptapNode node) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: r.buildBlockChildren(node.content, inListItem: true),
      );
}

/// Shared rendering for ordered and bullet lists.
abstract class _ListBase extends TiptapBlockExtension {
  const _ListBase();

  /// Whether this list numbers its items.
  bool get ordered;

  @override
  Widget buildBlock(TiptapRenderer r, TiptapNode node) {
    final t = r.theme;
    final items =
        node.content.where((c) => c.type == 'listItem').toList(growable: false);
    final start = ordered ? _coerceStart(node.attrs['start']) : 0;
    // The first list indents by listIndent; lists nested inside another list
    // already sit behind their parent marker, so they indent by the smaller
    // nestedListIndent. Children build one level deeper.
    final indent = r.listDepth == 0 ? t.listIndent : t.nestedListIndent;

    return r.withDeeperList(() {
      final rows = <Widget>[];
      for (var i = 0; i < items.length; i++) {
        if (i > 0) {
          rows.add(SizedBox(height: t.listItemSpacing));
        }
        final marker = ordered ? '${start + i}.' : t.bulletGlyph;
        rows.add(_buildRow(r, items[i], marker));
      }

      return Padding(
        padding: EdgeInsets.only(left: indent),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: rows,
        ),
      );
    });
  }

  /// Reads an ordered list's `start` attribute defensively. The wire format is
  /// untrusted at render time (parsing is tolerant but doesn't validate attr
  /// types), so a `start` arriving as a JSON double, a numeric string, or
  /// anything unexpected must not throw — it falls back to 1.
  static int _coerceStart(Object? raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw) ?? 1;
    return 1;
  }

  Widget _buildRow(TiptapRenderer r, TiptapNode item, String marker) {
    final t = r.theme;
    final markerStyle = (ordered ? t.orderedNumberStyle : null) ?? t.baseTextStyle;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(marker, style: markerStyle),
        SizedBox(width: t.listMarkerGap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: r.buildBlockChildren(item.content, inListItem: true),
          ),
        ),
      ],
    );
  }
}

/// `bulletList` → glyph-marked items (nested lists indent naturally).
class BulletList extends _ListBase {
  const BulletList();

  @override
  String get type => 'bulletList';

  @override
  bool get ordered => false;
}

/// `orderedList` → numbered items; honors the `start` attribute.
class OrderedList extends _ListBase {
  const OrderedList();

  @override
  String get type => 'orderedList';

  @override
  bool get ordered => true;
}
