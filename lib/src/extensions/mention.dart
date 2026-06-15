import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../model/tiptap_node.dart';
import '../render/tiptap_renderer.dart';
import '../tiptap_viewer_theme.dart';
import 'tiptap_extension.dart';

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
/// mentions; it is intentionally **not** part of `StarterKit`, so a half-wired
/// mention is never shown.
///
/// Mention is a plain [TiptapInlineExtension] using only public API — the
/// renderer no longer special-cases the `mention` type anywhere, so this serves
/// as the reference for building your own inline extension. The render strategy
/// is chosen by [display]; the colors come from the theme.
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

  String _label(TiptapNode node) => (node.attrs['label'] ?? '').toString();

  @override
  String? toPlainText(TiptapNode node) {
    final label = _label(node);
    return label.isEmpty ? null : '@$label';
  }

  @override
  InlineSpan? buildFlattened(
    TiptapRenderer r,
    TiptapNode node,
    TextStyle base, {
    required bool includeStyle,
  }) {
    final label = _label(node);
    if (label.isEmpty) {
      return null;
    }
    final style = includeStyle
        ? base.copyWith(
            color: r.theme.mentionColor,
            fontWeight: r.theme.mentionWeight,
          )
        : base;
    return TextSpan(text: '@$label', style: style);
  }

  @override
  InlineSpan buildInline(TiptapRenderer r, TiptapNode node, TextStyle style) {
    final t = r.theme;
    final id = (node.attrs['id'] ?? '').toString();
    final label = _label(node);
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
