import 'package:flutter/widgets.dart';

import '../model/tiptap_node.dart';
import '../render/tiptap_renderer.dart';
import 'tiptap_extension.dart';

/// `codeBlock` → a padded, tinted container of monospace, whitespace-preserving
/// text. No syntax highlighting (the package is dependency-free); long lines
/// soft-wrap. When absent from the active set, the code [unwrap]s to plain text.
class CodeBlock extends TiptapBlockExtension {
  const CodeBlock();

  @override
  String get type => 'codeBlock';

  @override
  Widget buildBlock(TiptapRenderer r, TiptapNode node) {
    final t = r.theme;
    return Container(
      width: double.infinity,
      padding: t.codeBlockPadding,
      decoration: BoxDecoration(
        color: t.codeBlockBackground,
        borderRadius: BorderRadius.circular(t.codeBlockRadius),
      ),
      child: Text(
        _code(node),
        style: t.resolveCodeBlockTextStyle(),
      ),
    );
  }

  /// Concatenates the literal text of the block's children, preserving newlines
  /// (TipTap stores a code block's body as `text` nodes, including line breaks).
  static String _code(TiptapNode node) {
    final buffer = StringBuffer();
    for (final child in node.content) {
      if (child.isText) {
        buffer.write(child.text ?? '');
      } else if (child.type == 'hardBreak') {
        buffer.write('\n');
      }
    }
    return buffer.toString();
  }
}
