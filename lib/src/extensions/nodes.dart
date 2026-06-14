import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../model/tiptap_node.dart';
import '../render/tiptap_renderer.dart';
import '../tiptap_viewer_theme.dart';
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

/// `paragraph` → a `Text.rich` of its inline content (empty → spacer).
class Paragraph extends TiptapBlockExtension {
  const Paragraph();

  @override
  String get type => 'paragraph';

  @override
  Widget buildBlock(TiptapRenderer r, TiptapNode node) =>
      r.buildInlineContainer(node.content, r.theme.baseTextStyle);
}

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

/// `text` → an inline span with its marks applied. The renderer also handles
/// text intrinsically, so omitting this extension does not drop text.
class TextNode extends TiptapInlineExtension {
  const TextNode();

  @override
  String get type => 'text';

  @override
  DisabledBehavior get disabledBehavior => DisabledBehavior.unwrap;

  @override
  InlineSpan buildInline(TiptapRenderer r, TiptapNode node, TextStyle style) =>
      TextSpan(text: node.text ?? '', style: r.applyMarks(node.marks, style));
}

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

/// How a [Mention] renders inline.
enum MentionDisplay {
  /// A styled `TextSpan` — selects and copies as real text. Default.
  highlight,

  /// A rounded `WidgetSpan` chip — richer look, weaker copy fidelity.
  chip,

  /// The bare label as ordinary body text — no mention color, weight, chip, or
  /// tap. Use this when you don't want mentions to stand out (or aren't wired to
  /// handle taps) but still want their text to read, rather than disappear. To
  /// drop mentions entirely instead, leave the [Mention] extension out of the
  /// active set so the renderer strips them.
  plain,
}

/// Signature for a mention tap. [id] and [label] are the raw stored attributes;
/// the package does not interpret the id convention.
typedef MentionTapCallback = void Function(String id, String label);

/// `mention` → a styled `@label`. Add this extension explicitly to render
/// mentions; it is intentionally **not** in the default set.
///
/// The render strategy is chosen by [display]; the colors come from the theme.
class Mention extends TiptapInlineExtension {
  /// Called when the mention is tapped, with the raw `(id, label)`.
  final MentionTapCallback? onTap;

  /// Whether to render as an inline highlight or a chip. See [MentionDisplay].
  final MentionDisplay display;

  const Mention({this.onTap, this.display = MentionDisplay.highlight});

  @override
  String get type => 'mention';

  @override
  DisabledBehavior get disabledBehavior => DisabledBehavior.strip;

  @override
  InlineSpan buildInline(TiptapRenderer r, TiptapNode node, TextStyle style) {
    final t = r.theme;
    final id = (node.attrs['id'] ?? '').toString();
    final label = (node.attrs['label'] ?? '').toString();
    final text = '@$label';
    final tap = onTap;

    // Plain: just the label, inheriting the surrounding run's style. No mention
    // color/weight, no chip, no tap.
    if (display == MentionDisplay.plain) {
      return TextSpan(text: label, style: style);
    }

    if (display == MentionDisplay.chip) {
      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: _MentionChip(
          text: text,
          // Inherit the surrounding run's family/height/size; override color
          // and weight from the theme — same tokens as the highlight path.
          textStyle: style.copyWith(
            color: t.mentionColor,
            fontWeight: t.mentionWeight,
          ),
          theme: t,
          onTap: tap == null ? null : () => tap(id, label),
        ),
      );
    }

    TapGestureRecognizer? recognizer;
    if (tap != null) {
      recognizer = TapGestureRecognizer()..onTap = () => tap(id, label);
      r.registerRecognizer(recognizer);
    }

    return TextSpan(
      text: text,
      style: style.copyWith(
        color: t.mentionColor,
        fontWeight: t.mentionWeight,
        backgroundColor: t.mentionBackgroundColor,
      ),
      recognizer: recognizer,
    );
  }
}

class _MentionChip extends StatelessWidget {
  final String text;
  final TextStyle textStyle;
  final TiptapViewerTheme theme;
  final VoidCallback? onTap;

  const _MentionChip({
    required this.text,
    required this.textStyle,
    required this.theme,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final background =
        theme.mentionBackgroundColor ?? theme.mentionColor.withValues(alpha: 0.12);
    final chip = Container(
      padding: theme.mentionChipPadding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(theme.mentionChipRadius),
      ),
      child: Text(text, style: textStyle),
    );
    if (onTap == null) {
      return chip;
    }
    return GestureDetector(onTap: onTap, child: chip);
  }
}
