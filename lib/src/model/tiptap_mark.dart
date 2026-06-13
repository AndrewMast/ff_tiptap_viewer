/// A TipTap mark (e.g. `bold`, `italic`) applied to a text node.
///
/// Marks decorate inline text. A single text node may carry several stacked
/// marks. Unknown attributes are preserved verbatim in [attrs] so custom
/// extensions can read them.
class TiptapMark {
  /// The mark type name, e.g. `bold`, `italic`, `underline`, `strike`.
  final String type;

  /// Raw attributes for this mark, as decoded from JSON. Empty when absent.
  final Map<String, dynamic> attrs;

  const TiptapMark({required this.type, this.attrs = const <String, dynamic>{}});

  /// Builds a mark from a decoded JSON map. Tolerant of missing fields.
  factory TiptapMark.fromJson(Map<String, dynamic> json) {
    final rawAttrs = json['attrs'];

    return TiptapMark(
      type: (json['type'] ?? '').toString(),
      attrs: rawAttrs is Map
          ? rawAttrs.cast<String, dynamic>()
          : const <String, dynamic>{},
    );
  }

  @override
  String toString() => 'TiptapMark($type)';
}
