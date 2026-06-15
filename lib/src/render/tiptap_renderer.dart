import 'dart:developer' as developer;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../extensions/tiptap_extension.dart';
import '../model/tiptap_mark.dart';
import '../model/tiptap_node.dart';
import '../tiptap_viewer_theme.dart';

/// Looks up the active extension for a given TipTap type.
///
/// Construction flattens the entries: a [TiptapExtensionSet] expands (recursively)
/// into its members, and each [TiptapTypedExtension] registers under its
/// [TiptapTypedExtension.type]. Flattening is left-to-right and **last-wins** —
/// an entry listed later overrides an earlier one of the same type, so you can
/// drop a replacement after a set. Shadowing is logged in debug builds.
class TiptapRegistry {
  final Map<String, TiptapTypedExtension> _byType;

  TiptapRegistry(List<TiptapExtension> extensions)
      : _byType = _flatten(extensions);

  static Map<String, TiptapTypedExtension> _flatten(
      List<TiptapExtension> extensions) {
    final map = <String, TiptapTypedExtension>{};
    void visit(List<TiptapExtension> list) {
      for (final e in list) {
        switch (e) {
          case TiptapExtensionSet():
            visit(e.extensions);
          case TiptapTypedExtension():
            assert(() {
              if (map.containsKey(e.type)) {
                developer.log(
                  '"${e.type}" overridden by a later extension',
                  name: 'ff_tiptap_viewer',
                );
              }
              return true;
            }());
            map[e.type] = e;
        }
      }
    }

    visit(extensions);
    return map;
  }

  /// The extension handling [type], or `null` when none is active.
  TiptapTypedExtension? operator [](String type) => _byType[type];
}

/// Walks a [TiptapNode] tree and produces Flutter widgets/spans.
///
/// Block nodes become widgets ([buildBlock]); inline nodes become
/// [InlineSpan]s ([buildInline]); marks transform text styles ([applyMarks]).
/// Extensions receive the renderer so they can recurse into their children.
class TiptapRenderer {
  /// The build context of the host `TiptapViewer`.
  final BuildContext context;

  /// The resolved theme (single styling surface).
  final TiptapViewerTheme theme;

  /// The active extension registry.
  final TiptapRegistry registry;

  /// Sink for gesture recognizers created during a build, so the owning widget
  /// can dispose them. Defaults to a no-op (e.g. when used in isolation).
  final void Function(GestureRecognizer recognizer) registerRecognizer;

  TiptapRenderer({
    required this.context,
    required this.theme,
    required this.registry,
    void Function(GestureRecognizer recognizer)? registerRecognizer,
  }) : registerRecognizer = registerRecognizer ?? _noopRecognizer;

  static void _noopRecognizer(GestureRecognizer _) {}

  /// Whether [node] renders inline — intrinsic `text`, any type handled by a
  /// [TiptapInlineExtension] (e.g. `mention`, `hardBreak`), or a content-less
  /// leaf (so an *unregistered* inline node like a mention without its
  /// extension still doesn't flip its paragraph to block-join). Everything else
  /// is treated as block content for the unwrap/flatten classification.
  bool _isInlineNode(TiptapNode node) =>
      node.isText ||
      node.content.isEmpty ||
      registry[node.type] is TiptapInlineExtension;

  /// How many lists deep the current build is. 0 at the top level; a list
  /// extension reads this to pick its indent, then nests its children one
  /// deeper via [withDeeperList].
  int _listDepth = 0;

  /// The current list-nesting depth (0 == a top-level list).
  int get listDepth => _listDepth;

  /// Builds a widget with the list-nesting depth incremented, restoring it
  /// afterward. Builds are synchronous and depth-first, so the counter is
  /// always balanced.
  Widget withDeeperList(Widget Function() build) {
    _listDepth++;
    try {
      return build();
    } finally {
      _listDepth--;
    }
  }

  /// Builds the root node. Routed through [buildBlock] so the `doc` extension
  /// (or the generic unwrap fallback when it is absent) handles it.
  Widget buildDocument(TiptapNode root) {
    return buildBlock(root) ?? const SizedBox.shrink();
  }

  /// Builds the block children of [nodes], inserting [TiptapViewerTheme.paragraphSpacing]
  /// between consecutive blocks. Empty paragraphs are themselves blank-line
  /// spacers, so no extra spacing is added on either side of them — unless
  /// [TiptapViewerTheme.renderEmptyParagraphs] is false, in which case they are
  /// stripped before they reach the layout.
  ///
  /// When [inListItem] is true (the content of a list item), the gap adjacent to
  /// a nested list uses the tighter [TiptapViewerTheme.listItemSpacing] instead,
  /// so a sub-list stays attached to its parent item rather than reading as a
  /// separate block.
  List<Widget> buildBlockChildren(List<TiptapNode> nodes,
      {bool inListItem = false}) {
    final widgets = <Widget>[];
    TiptapNode? previous;
    for (final node in nodes) {
      // With empty paragraphs disabled, blank paragraphs are dropped wholesale:
      // no spacer widget and no surrounding gap, collapsing the line entirely.
      if (!theme.renderEmptyParagraphs && _isBlankParagraph(node)) {
        continue;
      }
      final widget = buildBlock(node);
      if (widget == null) {
        continue;
      }
      if (widgets.isNotEmpty &&
          !_isBlankParagraph(node) &&
          !_isBlankParagraph(previous)) {
        final tight =
            inListItem && (_isListBlock(node) || _isListBlock(previous));
        widgets.add(SizedBox(
            height: tight ? theme.listItemSpacing : theme.paragraphSpacing));
      }
      widgets.add(widget);
      previous = node;
    }
    return widgets;
  }

  /// Whether [node] is an empty paragraph (rendered as a one-line spacer).
  bool _isBlankParagraph(TiptapNode? node) =>
      node != null && node.type == 'paragraph' && node.content.isEmpty;

  /// Whether [node] is a list block (bullet or ordered).
  bool _isListBlock(TiptapNode? node) =>
      node != null && (node.type == 'bulletList' || node.type == 'orderedList');

  /// Builds a single block widget, or `null` when the node is stripped.
  Widget? buildBlock(TiptapNode node) {
    final ext = registry[node.type];
    if (ext is TiptapBlockExtension) {
      return ext.buildBlock(this, node);
    }

    // No active block extension: apply the disabled rule.
    final behavior = ext is TiptapNodeExtension
        ? ext.disabledBehavior
        : (_hasBlockContent(node)
            ? DisabledBehavior.unwrap
            : DisabledBehavior.strip);
    _warnDropped(node.type, behavior, hasExtension: ext != null);

    if (behavior == DisabledBehavior.strip) {
      return null;
    }

    // Unwrap: render whatever is inside without this node's wrapper.
    if (_hasBlockContent(node)) {
      final children = buildBlockChildren(node.content);
      if (children.isEmpty) {
        return null;
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: children,
      );
    }
    return buildInlineContainer(node.content, theme.baseTextStyle);
  }

  /// Builds a `Text.rich` container for a run of inline [nodes]. An empty run
  /// (e.g. an empty paragraph) renders as a single-line spacer.
  Widget buildInlineContainer(List<TiptapNode> nodes, TextStyle style) {
    if (nodes.isEmpty) {
      final lineHeight = (style.fontSize ?? 14.0) * (style.height ?? 1.2);
      return SizedBox(height: lineHeight);
    }
    return Text.rich(TextSpan(style: style, children: buildInlineSpans(nodes, style)));
  }

  /// Builds the inline spans for [nodes].
  List<InlineSpan> buildInlineSpans(List<TiptapNode> nodes, TextStyle style) {
    final spans = <InlineSpan>[];
    for (final node in nodes) {
      final span = buildInline(node, style);
      if (span != null) {
        spans.add(span);
      }
    }
    return spans;
  }

  /// Builds a single inline span, or `null` when the node is stripped.
  InlineSpan? buildInline(TiptapNode node, TextStyle style) {
    final ext = registry[node.type];
    if (ext is TiptapInlineExtension) {
      return ext.buildInline(this, node, style);
    }

    // Intrinsic fallback: text always renders, even without a TextNode ext.
    if (node.isText) {
      return buildTextSpan(node, style);
    }

    final behavior =
        ext is TiptapNodeExtension ? ext.disabledBehavior : DisabledBehavior.strip;
    _warnDropped(node.type, behavior, hasExtension: ext != null);

    if (behavior == DisabledBehavior.strip) {
      return null;
    }
    if (node.content.isNotEmpty) {
      return TextSpan(children: buildInlineSpans(node.content, style));
    }
    return null;
  }

  /// Builds the [TextSpan] for a `text` [node]: folds its marks into [style] and
  /// attaches the first tap recognizer any mark contributes (e.g. `link`),
  /// registering it for disposal. Used by the `text` extension and the
  /// intrinsic-text fallback.
  TextSpan buildTextSpan(TiptapNode node, TextStyle style) {
    final resolved = applyMarks(node.marks, style);
    GestureRecognizer? recognizer;
    for (final mark in node.marks) {
      final ext = registry[mark.type];
      if (ext is TiptapMarkExtension) {
        final rec = ext.buildRecognizer(this, mark);
        if (rec != null) {
          recognizer = rec;
          registerRecognizer(rec);
          break; // a TextSpan has a single recognizer slot — first-wins.
        }
      }
    }
    return TextSpan(text: node.text ?? '', style: resolved, recognizer: recognizer);
  }

  /// Applies [marks] (in order) to [style] using the active mark extensions.
  /// An absent mark is unwrapped — the style is left unchanged.
  TextStyle applyMarks(List<TiptapMark> marks, TextStyle style) {
    var result = style;
    for (final mark in marks) {
      final ext = registry[mark.type];
      if (ext is TiptapMarkExtension) {
        result = ext.apply(this, mark, result);
      } else {
        _warnDropped(mark.type, DisabledBehavior.unwrap, hasExtension: ext != null);
      }
    }
    return result;
  }

  /// Flattens [root] into a single plain string, honoring inline extensions
  /// (e.g. `Mention` → `@label`) via their [TiptapInlineExtension.toPlainText].
  /// Types with no active inline extension contribute no text.
  String toPlainText(TiptapNode root, {String separator = ' '}) =>
      root.toPlainText(separator: separator, inlineLeaf: _plainLeaf);

  String? _plainLeaf(TiptapNode node) {
    final ext = registry[node.type];
    return ext is TiptapInlineExtension ? ext.toPlainText(node) : null;
  }

  /// Flattens [root] into a single [InlineSpan] for a compact, inline preview
  /// (one `Text.rich`/`RichText`), instead of the block [Column] that
  /// [buildBlock] produces.
  ///
  /// Inline runs concatenate; block siblings (paragraphs, list items, …) are
  /// joined with [separator] so the whole tree collapses onto one run. Block
  /// structure (indents, bullets, numbers, blockquote bars) is intentionally
  /// dropped — this is the "plain" path. An inline extension renders via its
  /// [TiptapInlineExtension.buildFlattened] (e.g. a `mention` as `@label` in the
  /// theme's mention color when [includeStyle] is true).
  ///
  /// When [includeStyle] is true (default), text marks are applied via the
  /// active mark extensions; when false, every run uses [theme.baseTextStyle].
  /// Returns an empty span when nothing renders.
  InlineSpan buildFlattenedSpan(
    TiptapNode root, {
    bool includeStyle = true,
    String separator = ' ',
  }) {
    final base = theme.baseTextStyle;
    return _flatten(root, base, includeStyle: includeStyle, separator: separator) ??
        TextSpan(text: '', style: base);
  }

  /// Recursive worker for [buildFlattenedSpan]; returns `null` for a node that
  /// contributes nothing, so empty nodes never produce a stray separator.
  InlineSpan? _flatten(
    TiptapNode node,
    TextStyle base, {
    required bool includeStyle,
    required String separator,
  }) {
    if (node.isText) {
      final value = node.text ?? '';
      if (value.isEmpty) {
        return null;
      }
      return TextSpan(
        text: value,
        style: includeStyle ? applyMarks(node.marks, base) : base,
      );
    }

    // An inline extension provides its own flattened representation.
    final ext = registry[node.type];
    if (ext is TiptapInlineExtension) {
      return ext.buildFlattened(this, node, base, includeStyle: includeStyle);
    }

    final children = <InlineSpan>[];
    for (final child in node.content) {
      final span =
          _flatten(child, base, includeStyle: includeStyle, separator: separator);
      if (span != null) {
        children.add(span);
      }
    }
    if (children.isEmpty) {
      return null;
    }

    // A block container (any non-inline child) joins its parts with the
    // separator; a pure inline run concatenates them.
    final hasBlockChild = node.content.any((c) => !_isInlineNode(c));
    if (!hasBlockChild) {
      return TextSpan(style: base, children: children);
    }
    final joined = <InlineSpan>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        joined.add(TextSpan(text: separator, style: base));
      }
      joined.add(children[i]);
    }
    return TextSpan(style: base, children: joined);
  }

  bool _hasBlockContent(TiptapNode node) =>
      node.content.any((c) => !_isInlineNode(c));

  void _warnDropped(String type, DisabledBehavior behavior,
      {required bool hasExtension}) {
    assert(() {
      if (type.isEmpty) {
        return true;
      }
      final action = behavior == DisabledBehavior.strip ? 'stripped' : 'unwrapped';
      final reason =
          hasExtension ? 'incompatible extension kind' : 'no active extension';
      developer.log('"$type" $action: $reason', name: 'ff_tiptap_viewer');
      return true;
    }());
  }
}
