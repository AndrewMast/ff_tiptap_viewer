import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'extensions/marks.dart';
import 'extensions/nodes.dart';
import 'extensions/tiptap_extension.dart';
import 'model/tiptap_document.dart';
import 'render/tiptap_renderer.dart';
import 'tiptap_viewer_theme.dart';

/// The default extension set used when `TiptapViewer.extensions` is omitted.
///
/// Contains every Dripstone node and mark **except** [Mention] — mentions only
/// render when you add `Mention(onTap: …)` yourself, so a half-wired mention is
/// never shown and DRIP content (which never has mentions) renders fully.
const List<TiptapExtension> kDefaultTiptapExtensions = <TiptapExtension>[
  Doc(),
  Paragraph(),
  TextNode(),
  Blockquote(),
  BulletList(),
  OrderedList(),
  ListItem(),
  Bold(),
  Italic(),
  Underline(),
  Strike(),
];

/// Renders Dripstone's TipTap (ProseMirror) JSON as native Flutter widgets.
///
/// ```dart
/// TiptapViewer(
///   document: courseDescriptionJsonString, // String or Map
///   extensions: const [
///     Paragraph(), TextNode(), Bold(), Italic(),
///     Mention(onTap: (id, label) {/* navigate */}),
///   ],
///   theme: TiptapViewerTheme.fromContext(context),
///   selectable: true,
/// )
/// ```
class TiptapViewer extends StatefulWidget {
  /// The document to render — a JSON [String] (the API format) or a decoded
  /// [Map]. Malformed/empty input renders nothing.
  final Object? document;

  /// Active extensions. When null, [kDefaultTiptapExtensions] is used.
  final List<TiptapExtension>? extensions;

  /// Styling surface. When null, derived via [TiptapViewerTheme.fromContext].
  final TiptapViewerTheme? theme;

  /// When true (default), wraps the output in a [SelectionArea] so the whole
  /// document is selectable/copyable. Set false if a [SelectionArea] already
  /// exists in an ancestor (nesting them is illegal).
  final bool selectable;

  const TiptapViewer({
    super.key,
    required this.document,
    this.extensions,
    this.theme,
    this.selectable = true,
  });

  /// Convenience factory for the common case of a raw JSON string.
  factory TiptapViewer.fromJson(
    String json, {
    Key? key,
    List<TiptapExtension>? extensions,
    TiptapViewerTheme? theme,
    bool selectable = true,
  }) {
    return TiptapViewer(
      key: key,
      document: json,
      extensions: extensions,
      theme: theme,
      selectable: selectable,
    );
  }

  @override
  State<TiptapViewer> createState() => _TiptapViewerState();
}

class _TiptapViewerState extends State<TiptapViewer> {
  final List<GestureRecognizer> _recognizers = <GestureRecognizer>[];

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Recognizers from the previous build are detached once we rebuild below.
    _disposeRecognizers();

    final document = TiptapDocument.parse(widget.document);
    if (document == null) {
      return const SizedBox.shrink();
    }

    final theme = widget.theme ?? TiptapViewerTheme.fromContext(context);
    final registry =
        TiptapRegistry(widget.extensions ?? kDefaultTiptapExtensions);
    final renderer = TiptapRenderer(
      context: context,
      theme: theme,
      registry: registry,
      registerRecognizer: _recognizers.add,
    );

    final child = renderer.buildDocument(document.root);
    return widget.selectable ? SelectionArea(child: child) : child;
  }
}
