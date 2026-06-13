import 'package:flutter/widgets.dart';

import '../model/tiptap_mark.dart';
import '../model/tiptap_node.dart';
import '../render/tiptap_renderer.dart';

/// What the renderer does with a node/mark whose type has **no** active
/// extension (it was left out of the `extensions` list, or the server added a
/// type this package doesn't know).
///
/// See the README "disabled rule": a type that carries child content falls back
/// to [unwrap]; an attrs-only leaf falls back to [strip].
enum DisabledBehavior {
  /// Render the node's children / text without the wrapper styling.
  unwrap,

  /// Remove the node entirely (it has no child content to fall back to).
  strip,
}

/// Base type for everything you can put in a `TiptapViewer.extensions` list.
///
/// An extension's *options* change the rendering **function** — which widgets or
/// spans get produced (e.g. a mention's highlight-vs-chip display, a tap
/// callback). Visual *tokens* (colors, fonts, spacing) never live here; they
/// belong to `TiptapViewerTheme`, the single styling surface.
abstract class TiptapExtension {
  const TiptapExtension();

  /// The TipTap type name this extension handles (e.g. `paragraph`, `bold`).
  String get type;
}

/// Base for node extensions (block or inline), carrying the [disabledBehavior]
/// used when the type is present in a document but absent from the active set.
abstract class TiptapNodeExtension extends TiptapExtension {
  const TiptapNodeExtension();

  /// Fallback applied when this node type has no active extension.
  DisabledBehavior get disabledBehavior => DisabledBehavior.unwrap;
}

/// A node that renders as a block-level [Widget] (paragraph, list, blockquote…).
abstract class TiptapBlockExtension extends TiptapNodeExtension {
  const TiptapBlockExtension();

  /// Builds the block widget for [node]. Use [r] to recurse into children.
  Widget buildBlock(TiptapRenderer r, TiptapNode node);
}

/// A node that renders inline as an [InlineSpan] (text, mention…).
abstract class TiptapInlineExtension extends TiptapNodeExtension {
  const TiptapInlineExtension();

  /// Default for inline leaves with no children is to [strip] when absent.
  @override
  DisabledBehavior get disabledBehavior => DisabledBehavior.strip;

  /// Builds the inline span for [node], inheriting [style] from its container.
  InlineSpan buildInline(TiptapRenderer r, TiptapNode node, TextStyle style);
}

/// A mark extension (bold, italic, …): transforms the [TextStyle] of the text
/// it wraps.
abstract class TiptapMarkExtension extends TiptapExtension {
  const TiptapMarkExtension();

  /// Marks always [unwrap] when absent (render the text without the styling).
  DisabledBehavior get disabledBehavior => DisabledBehavior.unwrap;

  /// Returns [style] transformed by this mark (e.g. add `FontWeight.bold`).
  TextStyle apply(TiptapRenderer r, TiptapMark mark, TextStyle style);
}
