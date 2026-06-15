import 'dart:convert';

import 'tiptap_node.dart';

/// A parsed TipTap document, wrapping the root (`doc`) node.
///
/// Use [TiptapDocument.parse] to accept the wire format — a JSON
/// **string** — or an already-decoded `Map`. Parsing is deliberately tolerant:
/// malformed or empty input yields `null` rather than throwing, so a viewer can
/// render nothing instead of crashing on bad data.
class TiptapDocument {
  /// The root node of the document (conventionally of type `doc`).
  final TiptapNode root;

  const TiptapDocument(this.root);

  /// Flattens the whole document into a single plain string. See
  /// [TiptapNode.toPlainText] — block siblings are joined with [separator].
  ///
  /// Non-text inline leaves (e.g. `mention`) contribute text only when
  /// [inlineLeaf] is supplied; build one from your extensions with
  /// `inlineLeafText(extensions)`.
  String toPlainText({
    String separator = ' ',
    String? Function(TiptapNode node)? inlineLeaf,
  }) =>
      root.toPlainText(separator: separator, inlineLeaf: inlineLeaf);

  /// Parses [input] into a document.
  ///
  /// Accepts:
  /// * a JSON [String] (the TipTap API format) — decoded internally,
  /// * an already-decoded [Map],
  ///
  /// Returns `null` for empty, malformed, or non-object input.
  static TiptapDocument? parse(Object? input) {
    Map<String, dynamic>? map;

    if (input is String) {
      if (input.trim().isEmpty) {
        return null;
      }
      try {
        final decoded = jsonDecode(input);
        if (decoded is Map) {
          map = decoded.cast<String, dynamic>();
        }
      } catch (_) {
        return null;
      }
    } else if (input is Map) {
      map = input.cast<String, dynamic>();
    }

    if (map == null) {
      return null;
    }

    try {
      return TiptapDocument(TiptapNode.fromJson(map));
    } catch (_) {
      return null;
    }
  }
}
