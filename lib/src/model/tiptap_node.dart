import 'tiptap_mark.dart';

/// A single node in a TipTap document tree.
///
/// A node is either a block (`doc`, `paragraph`, `blockquote`, lists, …), an
/// inline leaf (`text`, `mention`), or anything the server may add later. The
/// renderer decides how to treat a node from its [type] and the active
/// extensions, so this model stays a faithful, lossless mirror of the JSON.
class TiptapNode {
  /// The node type name, e.g. `doc`, `paragraph`, `text`, `mention`.
  final String type;

  /// Raw attributes for this node (e.g. `orderedList.start`, mention `id`).
  final Map<String, dynamic> attrs;

  /// Child nodes. Empty for leaves and empty paragraphs.
  final List<TiptapNode> content;

  /// The literal text of a `text` node. `null` for every other node type.
  final String? text;

  /// Marks applied to this node (only meaningful for `text` nodes).
  final List<TiptapMark> marks;

  const TiptapNode({
    required this.type,
    this.attrs = const <String, dynamic>{},
    this.content = const <TiptapNode>[],
    this.text,
    this.marks = const <TiptapMark>[],
  });

  /// Whether this is a literal text node.
  bool get isText => type == 'text';

  /// Flattens this node (and its descendants) into a single plain string.
  ///
  /// Inline siblings (the runs inside a paragraph) are concatenated directly;
  /// block siblings (paragraphs, list items, blockquote lines, …) are joined
  /// with [separator] so the structure collapses into one readable line. Marks
  /// carry no text and are ignored; a `mention` renders as `@label` (dropped
  /// when it has no label). Empty/blank nodes contribute nothing — there are no
  /// leading, trailing, or doubled separators.
  ///
  /// This is the string counterpart to the inline `TiptapText` widget: use it
  /// when a caller just needs text (search, accessibility labels, previews).
  String toPlainText({String separator = ' '}) =>
      _plainText(separator) ?? '';

  /// Recursive worker for [toPlainText]; returns `null` for a node that
  /// contributes no text, so callers can drop it without a stray separator.
  String? _plainText(String separator) {
    if (isText) {
      final value = text;
      return (value == null || value.isEmpty) ? null : value;
    }
    if (type == 'mention') {
      final label = (attrs['label'] ?? '').toString();
      return label.isEmpty ? null : '@$label';
    }

    final parts = <String>[];
    for (final child in content) {
      final part = child._plainText(separator);
      if (part != null && part.isNotEmpty) {
        parts.add(part);
      }
    }
    if (parts.isEmpty) {
      return null;
    }

    // Block containers (anything carrying a non-inline child) join with the
    // separator; a pure inline run (a paragraph's text/mentions) concatenates.
    final hasBlockChild =
        content.any((c) => c.type != 'text' && c.type != 'mention');
    return hasBlockChild ? parts.join(separator) : parts.join();
  }

  /// Builds a node (recursively) from a decoded JSON map. Tolerant of missing
  /// or malformed fields — anything unexpected is dropped rather than thrown.
  factory TiptapNode.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content'];
    final content = rawContent is List
        ? rawContent
            .whereType<Map<Object?, Object?>>()
            .map((e) => TiptapNode.fromJson(e.cast<String, dynamic>()))
            .toList(growable: false)
        : const <TiptapNode>[];

    final rawMarks = json['marks'];
    final marks = rawMarks is List
        ? rawMarks
            .whereType<Map<Object?, Object?>>()
            .map((e) => TiptapMark.fromJson(e.cast<String, dynamic>()))
            .toList(growable: false)
        : const <TiptapMark>[];

    final rawAttrs = json['attrs'];

    return TiptapNode(
      type: (json['type'] ?? '').toString(),
      attrs: rawAttrs is Map
          ? rawAttrs.cast<String, dynamic>()
          : const <String, dynamic>{},
      content: content,
      text: json['text'] as String?,
      marks: marks,
    );
  }

  @override
  String toString() =>
      'TiptapNode($type${isText ? ': "$text"' : ''}, ${content.length} children)';
}
