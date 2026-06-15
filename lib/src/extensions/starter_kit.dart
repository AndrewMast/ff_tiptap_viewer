import 'blockquote.dart';
import 'code_block.dart';
import 'document.dart';
import 'hard_break.dart';
import 'heading.dart';
import 'horizontal_rule.dart';
import 'link.dart';
import 'lists.dart';
import 'marks.dart';
import 'paragraph.dart';
import 'text.dart';
import 'tiptap_extension.dart';

/// The default set of extensions — the viewer's counterpart to TipTap's
/// [StarterKit](https://tiptap.dev/docs/editor/extensions/functionality/starterkit).
///
/// It bundles every node and mark a viewer needs (editor-only StarterKit
/// members like history/cursors are omitted). It is used automatically when
/// `TiptapViewer.extensions` is null.
///
/// **Mention is not included** — add `Mention(onTap: …)` yourself so a
/// half-wired mention is never shown.
///
/// **Link is included but non-interactive** — it renders as styled text with no
/// tap handler. To make links tappable, list a wired `Link(onTap: …)` after the
/// kit (flattening is last-wins, so it replaces the default):
///
/// ```dart
/// extensions: const [StarterKit(), Link(onTap: openUrl)],
/// ```
///
/// **Configure by toggling members** off with the bool flags
/// (`StarterKit(blockquote: false)`); **customize** a member by listing your own
/// instance after the kit (last-wins). This is deliberately simpler than
/// TipTap's per-member options union — a viewer's extensions are nearly all
/// zero-config, and "list-after" covers replacement.
class StarterKit extends TiptapExtensionSet {
  final bool document;
  final bool paragraph;
  final bool text;
  final bool heading;
  final bool blockquote;
  final bool bulletList;
  final bool orderedList;
  final bool listItem;
  final bool codeBlock;
  final bool horizontalRule;
  final bool hardBreak;
  final bool bold;
  final bool italic;
  final bool code;
  final bool underline;
  final bool strike;
  final bool link;

  const StarterKit({
    this.document = true,
    this.paragraph = true,
    this.text = true,
    this.heading = true,
    this.blockquote = true,
    this.bulletList = true,
    this.orderedList = true,
    this.listItem = true,
    this.codeBlock = true,
    this.horizontalRule = true,
    this.hardBreak = true,
    this.bold = true,
    this.italic = true,
    this.code = true,
    this.underline = true,
    this.strike = true,
    this.link = true,
  });

  @override
  List<TiptapExtension> get extensions => <TiptapExtension>[
        if (document) const Doc(),
        if (paragraph) const Paragraph(),
        if (text) const TextNode(),
        if (heading) const Heading(),
        if (blockquote) const Blockquote(),
        if (bulletList) const BulletList(),
        if (orderedList) const OrderedList(),
        if (listItem) const ListItem(),
        if (codeBlock) const CodeBlock(),
        if (horizontalRule) const HorizontalRule(),
        if (hardBreak) const HardBreak(),
        if (bold) const Bold(),
        if (italic) const Italic(),
        if (code) const Code(),
        if (underline) const Underline(),
        if (strike) const Strike(),
        if (link) const Link(),
      ];
}
