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
  /// Cross-platform monospace family stack used by inline code and code blocks
  /// when no explicit family is supplied.
  static const List<String> monospaceFamilyFallback = <String>[
    'monospace',
    'Menlo',
    'Courier New',
    'Consolas',
  ];

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

  /// Per-level heading styles. When null (or a level is missing), [headingStyle]
  /// derives one by scaling [baseTextStyle]. Provide a sparse map to override
  /// just the levels you care about (e.g. `{1: ..., 2: ...}`).
  final Map<int, TextStyle>? headingStyles;

  /// Color of the blockquote's left border bar.
  final Color blockquoteBorderColor;

  /// Width of the blockquote's left border bar.
  final double blockquoteBorderWidth;

  /// Inner padding of a blockquote.
  final EdgeInsetsGeometry blockquotePadding;

  /// Glyph used as the bullet for unordered lists.
  final String bulletGlyph;

  /// Left indent applied to a top-level list.
  final double listIndent;

  /// Left indent applied to a list nested inside another list. Smaller than
  /// [listIndent] because a nested list already sits behind its parent item's
  /// marker and gap, so a full [listIndent] on top reads as too far in.
  final double nestedListIndent;

  /// Vertical gap between list items. Also used for the gap between a list
  /// item's own content and a list nested inside it, so a nested list stays
  /// tight to its parent instead of being pushed away by [paragraphSpacing].
  final double listItemSpacing;

  /// Horizontal gap between a list marker and its content.
  final double listMarkerGap;

  /// Style for ordered-list numbers. Falls back to [baseTextStyle] when null.
  final TextStyle? orderedNumberStyle;

  /// Background fill of a code block. See [resolveCodeBlockTextStyle] for text.
  final Color codeBlockBackground;

  /// Inner padding of a code block.
  final EdgeInsetsGeometry codeBlockPadding;

  /// Corner radius of a code block.
  final double codeBlockRadius;

  /// Text style for a code block. When null, [resolveCodeBlockTextStyle] derives
  /// a monospace style from [baseTextStyle].
  final TextStyle? codeBlockTextStyle;

  /// Style for the inline `code` mark. When null, [resolveInlineCodeStyle]
  /// derives a monospace style (with a subtle background) from [baseTextStyle].
  final TextStyle? inlineCodeStyle;

  /// Color of a horizontal rule.
  final Color hrColor;

  /// Thickness of a horizontal rule.
  final double hrThickness;

  /// Vertical space above and below a horizontal rule.
  final double hrSpacing;

  /// Foreground color for links.
  final Color linkColor;

  /// Whether links are underlined.
  final bool linkUnderline;

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
    this.headingStyles,
    this.blockquoteBorderColor = const Color(0xFFCCCCCC),
    this.blockquoteBorderWidth = 4.0,
    this.blockquotePadding =
        const EdgeInsets.only(left: 12, top: 4, bottom: 4),
    this.bulletGlyph = '•',
    this.listIndent = 14.0,
    this.nestedListIndent = 8.0,
    this.listItemSpacing = 4.0,
    this.listMarkerGap = 8.0,
    this.orderedNumberStyle,
    this.codeBlockBackground = const Color(0xFFF2F2F2),
    this.codeBlockPadding = const EdgeInsets.all(12),
    this.codeBlockRadius = 6.0,
    this.codeBlockTextStyle,
    this.inlineCodeStyle,
    this.hrColor = const Color(0xFFCCCCCC),
    this.hrThickness = 1.0,
    this.hrSpacing = 8.0,
    this.linkColor = const Color(0xFF2563EB),
    this.linkUnderline = true,
    this.mentionColor = const Color(0xFF2563EB),
    this.mentionWeight = FontWeight.w600,
    this.mentionBackgroundColor,
    this.mentionChipRadius = 6.0,
    this.mentionChipPadding =
        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
  });

  /// Approximate font-size multipliers (relative to [baseTextStyle]) used when
  /// [headingStyles] has no entry for a level. Levels outside 1..6 clamp.
  static const Map<int, double> _headingScale = <int, double>{
    1: 2.0,
    2: 1.5,
    3: 1.25,
    4: 1.1,
    5: 1.0,
    6: 0.9,
  };

  /// The style for a heading of [level], honoring [headingStyles] when present
  /// and otherwise scaling [baseTextStyle] (bold, larger for lower levels).
  TextStyle headingStyle(int level) {
    final override = headingStyles?[level];
    if (override != null) {
      return override;
    }
    final clamped = level < 1 ? 1 : (level > 6 ? 6 : level);
    final scale = _headingScale[clamped]!;
    final base = baseTextStyle;
    return base.copyWith(
      fontSize: (base.fontSize ?? 16) * scale,
      fontWeight: FontWeight.w700,
      height: 1.2,
    );
  }

  /// The resolved code-block text style — [codeBlockTextStyle] if set, else a
  /// monospace derivation of [baseTextStyle].
  TextStyle resolveCodeBlockTextStyle() =>
      codeBlockTextStyle ??
      baseTextStyle.copyWith(
        fontFamily: 'monospace',
        fontFamilyFallback: monospaceFamilyFallback,
        height: 1.4,
      );

  /// The resolved inline `code` style — [inlineCodeStyle] if set, else a
  /// monospace derivation of [baseTextStyle] with a subtle background.
  TextStyle resolveInlineCodeStyle() =>
      inlineCodeStyle ??
      baseTextStyle.copyWith(
        fontFamily: 'monospace',
        fontFamilyFallback: monospaceFamilyFallback,
        backgroundColor: codeBlockBackground,
      );

  /// Derives defaults from the host's Material theme. Safe in any FlutterFlow /
  /// MaterialApp host; for the branded look, map your design system into a
  /// [TiptapViewerTheme] explicitly (see the example app).
  factory TiptapViewerTheme.fromContext(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.bodyMedium ?? DefaultTextStyle.of(context).style;
    return TiptapViewerTheme(
      baseTextStyle: base,
      mentionColor: theme.colorScheme.primary,
      linkColor: theme.colorScheme.primary,
      blockquoteBorderColor: theme.dividerColor,
      hrColor: theme.dividerColor,
      codeBlockBackground: theme.colorScheme.surfaceContainerHighest,
    );
  }

  /// Returns a copy with the given fields replaced.
  TiptapViewerTheme copyWith({
    TextStyle? baseTextStyle,
    double? paragraphSpacing,
    bool? renderEmptyParagraphs,
    FontWeight? boldWeight,
    Map<int, TextStyle>? headingStyles,
    Color? blockquoteBorderColor,
    double? blockquoteBorderWidth,
    EdgeInsetsGeometry? blockquotePadding,
    String? bulletGlyph,
    double? listIndent,
    double? nestedListIndent,
    double? listItemSpacing,
    double? listMarkerGap,
    TextStyle? orderedNumberStyle,
    Color? codeBlockBackground,
    EdgeInsetsGeometry? codeBlockPadding,
    double? codeBlockRadius,
    TextStyle? codeBlockTextStyle,
    TextStyle? inlineCodeStyle,
    Color? hrColor,
    double? hrThickness,
    double? hrSpacing,
    Color? linkColor,
    bool? linkUnderline,
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
      headingStyles: headingStyles ?? this.headingStyles,
      blockquoteBorderColor: blockquoteBorderColor ?? this.blockquoteBorderColor,
      blockquoteBorderWidth: blockquoteBorderWidth ?? this.blockquoteBorderWidth,
      blockquotePadding: blockquotePadding ?? this.blockquotePadding,
      bulletGlyph: bulletGlyph ?? this.bulletGlyph,
      listIndent: listIndent ?? this.listIndent,
      nestedListIndent: nestedListIndent ?? this.nestedListIndent,
      listItemSpacing: listItemSpacing ?? this.listItemSpacing,
      listMarkerGap: listMarkerGap ?? this.listMarkerGap,
      orderedNumberStyle: orderedNumberStyle ?? this.orderedNumberStyle,
      codeBlockBackground: codeBlockBackground ?? this.codeBlockBackground,
      codeBlockPadding: codeBlockPadding ?? this.codeBlockPadding,
      codeBlockRadius: codeBlockRadius ?? this.codeBlockRadius,
      codeBlockTextStyle: codeBlockTextStyle ?? this.codeBlockTextStyle,
      inlineCodeStyle: inlineCodeStyle ?? this.inlineCodeStyle,
      hrColor: hrColor ?? this.hrColor,
      hrThickness: hrThickness ?? this.hrThickness,
      hrSpacing: hrSpacing ?? this.hrSpacing,
      linkColor: linkColor ?? this.linkColor,
      linkUnderline: linkUnderline ?? this.linkUnderline,
      mentionColor: mentionColor ?? this.mentionColor,
      mentionWeight: mentionWeight ?? this.mentionWeight,
      mentionBackgroundColor:
          mentionBackgroundColor ?? this.mentionBackgroundColor,
      mentionChipRadius: mentionChipRadius ?? this.mentionChipRadius,
      mentionChipPadding: mentionChipPadding ?? this.mentionChipPadding,
    );
  }
}
