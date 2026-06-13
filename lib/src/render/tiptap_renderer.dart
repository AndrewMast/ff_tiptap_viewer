import 'dart:developer' as developer;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../extensions/tiptap_extension.dart';
import '../model/tiptap_mark.dart';
import '../model/tiptap_node.dart';
import '../tiptap_viewer_theme.dart';

/// Looks up the active extension for a given TipTap type.
class TiptapRegistry {
  final Map<String, TiptapExtension> _byType;

  TiptapRegistry(List<TiptapExtension> extensions)
      : _byType = <String, TiptapExtension>{
          for (final e in extensions) e.type: e,
        };

  /// The extension handling [type], or `null` when none is active.
  TiptapExtension? operator [](String type) => _byType[type];
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

  /// Inline types that never count as "block content" for unwrap fallback.
  static const Set<String> _inlineTypes = <String>{'text', 'mention'};

  TiptapRenderer({
    required this.context,
    required this.theme,
    required this.registry,
    void Function(GestureRecognizer recognizer)? registerRecognizer,
  }) : registerRecognizer = registerRecognizer ?? _noopRecognizer;

  static void _noopRecognizer(GestureRecognizer _) {}

  /// Builds the root node. Routed through [buildBlock] so the `doc` extension
  /// (or the generic unwrap fallback when it is absent) handles it.
  Widget buildDocument(TiptapNode root) {
    return buildBlock(root) ?? const SizedBox.shrink();
  }

  /// Builds the block children of [nodes], inserting [TiptapViewerTheme.paragraphSpacing]
  /// between consecutive blocks. Empty paragraphs are themselves blank-line
  /// spacers, so no extra spacing is added on either side of them.
  List<Widget> buildBlockChildren(List<TiptapNode> nodes) {
    final widgets = <Widget>[];
    TiptapNode? previous;
    for (final node in nodes) {
      final widget = buildBlock(node);
      if (widget == null) {
        continue;
      }
      if (widgets.isNotEmpty &&
          !_isBlankParagraph(node) &&
          !_isBlankParagraph(previous)) {
        widgets.add(SizedBox(height: theme.paragraphSpacing));
      }
      widgets.add(widget);
      previous = node;
    }
    return widgets;
  }

  /// Whether [node] is an empty paragraph (rendered as a one-line spacer).
  bool _isBlankParagraph(TiptapNode? node) =>
      node != null && node.type == 'paragraph' && node.content.isEmpty;

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
      return TextSpan(text: node.text ?? '', style: applyMarks(node.marks, style));
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

  bool _hasBlockContent(TiptapNode node) =>
      node.content.any((c) => !_inlineTypes.contains(c.type));

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
