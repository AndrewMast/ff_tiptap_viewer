import 'package:flutter/material.dart';

/// The single styling surface for a `TiptapViewer`.
///
/// Every extension reads its visual tokens (colors, fonts, spacing, radius,
/// list glyph) from here — extensions themselves only decide *which* widgets get
/// produced, never how they are colored. Build one with the const constructor,
/// derive sensible defaults from the host with [TiptapViewerTheme.fromContext],
/// and tweak with [copyWith].
@immutable
class TiptapViewerTheme {
  /// Base style for all body text. Marks and nodes derive from this.
  final TextStyle baseTextStyle;

  /// Vertical gap inserted between consecutive block siblings.
  final double paragraphSpacing;

  /// Whether empty paragraphs render at all.
  ///
  /// When false (default), empty paragraphs are stripped entirely: they produce
  /// no widget and add no surrounding spacing, collapsing the gap they would
  /// have created. When true, an empty paragraph renders as a single blank line
  /// — the way the TipTap editor shows a deliberate vertical gap.
  final bool renderEmptyParagraphs;

  /// Weight applied by the `bold` mark.
  final FontWeight boldWeight;

  /// Color of the blockquote's left border bar.
  final Color blockquoteBorderColor;

  /// Width of the blockquote's left border bar.
  final double blockquoteBorderWidth;

  /// Inner padding of a blockquote.
  final EdgeInsetsGeometry blockquotePadding;

  /// Glyph used as the bullet for unordered lists.
  final String bulletGlyph;

  /// Left indent applied to a list level.
  final double listIndent;

  /// Vertical gap between list items. Also used for the gap between a list
  /// item's own content and a list nested inside it, so a nested list stays
  /// tight to its parent instead of being pushed away by [paragraphSpacing].
  final double listItemSpacing;

  /// Horizontal gap between a list marker and its content.
  final double listMarkerGap;

  /// Style for ordered-list numbers. Falls back to [baseTextStyle] when null.
  final TextStyle? orderedNumberStyle;

  /// Foreground color for mentions.
  final Color mentionColor;

  /// Weight for mentions.
  final FontWeight mentionWeight;

  /// Background for mentions. For `highlight` it's a flat highlight; for `chip`
  /// it fills the pill. When null, the chip derives a tint from [mentionColor]
  /// and the highlight has no background.
  final Color? mentionBackgroundColor;

  /// Corner radius of a mention chip.
  final double mentionChipRadius;

  /// Inner padding of a mention chip.
  final EdgeInsetsGeometry mentionChipPadding;

  const TiptapViewerTheme({
    this.baseTextStyle =
        const TextStyle(fontSize: 16, height: 1.4, color: Color(0xFF1A1A1A)),
    this.paragraphSpacing = 8.0,
    this.renderEmptyParagraphs = false,
    this.boldWeight = FontWeight.w700,
    this.blockquoteBorderColor = const Color(0xFFCCCCCC),
    this.blockquoteBorderWidth = 4.0,
    this.blockquotePadding =
        const EdgeInsets.only(left: 12, top: 4, bottom: 4),
    this.bulletGlyph = '•',
    this.listIndent = 14.0,
    this.listItemSpacing = 4.0,
    this.listMarkerGap = 8.0,
    this.orderedNumberStyle,
    this.mentionColor = const Color(0xFF2563EB),
    this.mentionWeight = FontWeight.w600,
    this.mentionBackgroundColor,
    this.mentionChipRadius = 6.0,
    this.mentionChipPadding =
        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
  });

  /// Derives defaults from the host's Material theme. Safe in any FlutterFlow /
  /// MaterialApp host; for the branded look, map your design system into a
  /// [TiptapViewerTheme] explicitly (see the example app).
  factory TiptapViewerTheme.fromContext(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.bodyMedium ?? DefaultTextStyle.of(context).style;
    return TiptapViewerTheme(
      baseTextStyle: base,
      mentionColor: theme.colorScheme.primary,
      blockquoteBorderColor: theme.dividerColor,
    );
  }

  /// Returns a copy with the given fields replaced.
  TiptapViewerTheme copyWith({
    TextStyle? baseTextStyle,
    double? paragraphSpacing,
    bool? renderEmptyParagraphs,
    FontWeight? boldWeight,
    Color? blockquoteBorderColor,
    double? blockquoteBorderWidth,
    EdgeInsetsGeometry? blockquotePadding,
    String? bulletGlyph,
    double? listIndent,
    double? listItemSpacing,
    double? listMarkerGap,
    TextStyle? orderedNumberStyle,
    Color? mentionColor,
    FontWeight? mentionWeight,
    Color? mentionBackgroundColor,
    double? mentionChipRadius,
    EdgeInsetsGeometry? mentionChipPadding,
  }) {
    return TiptapViewerTheme(
      baseTextStyle: baseTextStyle ?? this.baseTextStyle,
      paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
      renderEmptyParagraphs: renderEmptyParagraphs ?? this.renderEmptyParagraphs,
      boldWeight: boldWeight ?? this.boldWeight,
      blockquoteBorderColor: blockquoteBorderColor ?? this.blockquoteBorderColor,
      blockquoteBorderWidth: blockquoteBorderWidth ?? this.blockquoteBorderWidth,
      blockquotePadding: blockquotePadding ?? this.blockquotePadding,
      bulletGlyph: bulletGlyph ?? this.bulletGlyph,
      listIndent: listIndent ?? this.listIndent,
      listItemSpacing: listItemSpacing ?? this.listItemSpacing,
      listMarkerGap: listMarkerGap ?? this.listMarkerGap,
      orderedNumberStyle: orderedNumberStyle ?? this.orderedNumberStyle,
      mentionColor: mentionColor ?? this.mentionColor,
      mentionWeight: mentionWeight ?? this.mentionWeight,
      mentionBackgroundColor:
          mentionBackgroundColor ?? this.mentionBackgroundColor,
      mentionChipRadius: mentionChipRadius ?? this.mentionChipRadius,
      mentionChipPadding: mentionChipPadding ?? this.mentionChipPadding,
    );
  }
}
