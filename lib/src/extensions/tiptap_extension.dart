import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../model/tiptap_mark.dart';
import '../model/tiptap_node.dart';
import '../render/tiptap_renderer.dart';

/// What the renderer does with a node/mark whose type has **no** active
/// extension (it was left out of the active set, or the server added a type
/// this package doesn't know).
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
/// This mirrors TipTap's `Extension`: it carries **no** schema type of its own.
/// A list entry is one of exactly two kinds (the type is `sealed`, so the
/// registry's flatten step is exhaustively checked by the compiler):
///
/// * [TiptapExtensionSet] — a *group* that expands into other extensions
///   (e.g. `StarterKit`, or your own bundle). TipTap's `addExtensions()`.
/// * [TiptapTypedExtension] — a single schema-typed handler with a [type]
///   (a node or a mark). TipTap's `Node` / `Mark`.
///
/// An extension's *options* change the rendering **function** — which widgets or
/// spans get produced (e.g. a mention's tap callback). Visual *tokens* (colors,
/// fonts, spacing) never live here; they belong to `TiptapViewerTheme`, the
/// single styling surface.
sealed class TiptapExtension {
  const TiptapExtension();
}

/// A *group* of extensions, expanded into the active set when flattened.
///
/// Subclass this to build a reusable bundle (e.g. a `Dripstone` set):
///
/// ```dart
/// class Dripstone extends TiptapExtensionSet {
///   const Dripstone();
///   @override
///   List<TiptapExtension> get extensions =>
///       const <TiptapExtension>[StarterKit(), Mention()];
/// }
/// ```
///
/// Flattening is recursive (a set may contain other sets) and **last-wins** on
/// duplicate [TiptapTypedExtension.type]: entries listed later override earlier
/// ones, so you can drop your own instance *after* a set to replace one member.
abstract class TiptapExtensionSet extends TiptapExtension {
  const TiptapExtensionSet();

  /// The extensions this set contributes, in order.
  List<TiptapExtension> get extensions;
}

/// A single schema-typed handler — a node or a mark. Mirrors TipTap's
/// `Node` / `Mark`, both of which carry a `name` (here, [type]).
abstract class TiptapTypedExtension extends TiptapExtension {
  const TiptapTypedExtension();

  /// The TipTap type name this extension handles (e.g. `paragraph`, `bold`).
  String get type;
}

/// Base for node extensions (block or inline), carrying the [disabledBehavior]
/// used when the type is present in a document but absent from the active set.
abstract class TiptapNodeExtension extends TiptapTypedExtension {
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

  /// The plain-text representation of [node] for flattened previews and
  /// `toPlainText`. Returns `null` (the default) when this extension
  /// contributes no text. A non-null result also marks the node as **inline**
  /// for plain-text block/inline classification.
  ///
  /// Example: `Mention` overrides this to return `'@$label'`.
  String? toPlainText(TiptapNode node) => null;

  /// The flattened inline span for [node] in the `TiptapText` preview path —
  /// a styled-but-non-interactive representation (no gesture recognizers).
  ///
  /// Defaults to wrapping [toPlainText] in a [base]-styled [TextSpan], so an
  /// extension only needs to override [toPlainText] for both the string and the
  /// preview span. Override this directly to apply a richer (still
  /// non-interactive) style — e.g. `Mention` keeps its color/weight.
  InlineSpan? buildFlattened(
    TiptapRenderer r,
    TiptapNode node,
    TextStyle base, {
    required bool includeStyle,
  }) {
    final text = toPlainText(node);
    return text == null ? null : TextSpan(text: text, style: base);
  }
}

/// A mark extension (bold, italic, link, …): transforms the [TextStyle] of the
/// text it wraps, and may optionally attach a tap recognizer.
abstract class TiptapMarkExtension extends TiptapTypedExtension {
  const TiptapMarkExtension();

  /// Marks always [unwrap] when absent (render the text without the styling).
  DisabledBehavior get disabledBehavior => DisabledBehavior.unwrap;

  /// Returns [style] transformed by this mark (e.g. add `FontWeight.bold`).
  TextStyle apply(TiptapRenderer r, TiptapMark mark, TextStyle style);

  /// Optionally builds a [GestureRecognizer] for the run this mark covers (e.g.
  /// a tappable link). Returns `null` (the default) for non-interactive marks.
  ///
  /// A `TextSpan` has a single recognizer slot, so when several marks on the
  /// same run return one, the **first** (in mark order) wins. The renderer
  /// registers the recognizer for disposal; do not dispose it yourself.
  GestureRecognizer? buildRecognizer(TiptapRenderer r, TiptapMark mark) => null;
}

/// Builds an `inlineLeaf` hook for [TiptapNode.toPlainText] /
/// [TiptapDocument.toPlainText] from [extensions], so inline extensions
/// contribute their text (e.g. `Mention` → `@label`).
///
/// ```dart
/// final text = doc.toPlainText(
///   inlineLeaf: inlineLeafText(const [StarterKit(), Mention()]),
/// );
/// ```
String? Function(TiptapNode node) inlineLeafText(
    List<TiptapExtension> extensions) {
  final registry = TiptapRegistry(extensions);
  return (node) {
    final ext = registry[node.type];
    return ext is TiptapInlineExtension ? ext.toPlainText(node) : null;
  };
}
