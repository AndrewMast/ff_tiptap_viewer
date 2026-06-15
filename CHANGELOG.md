# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/2.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.0.3] - 2026-06-15

Adopt a TipTap-style `StarterKit`, make extension **sets** a first-class concept,
add the remaining viewer-relevant StarterKit nodes/marks, and fully decouple
`Mention` from the core. This is a **breaking** change set.

### Added

- `StarterKit`: the default extension set (used when `extensions` is null),
  mirroring TipTap's StarterKit for a viewer. Toggle members off with per-member
  bool flags (e.g. `StarterKit(blockquote: false)`); customize a member by
  listing your own instance after the kit (flattening is last-wins).
- `TiptapExtensionSet`: a base class for reusable extension bundles. Subclass it
  to build your own set (e.g. a `Dripstone` set); sets flatten recursively, so a
  set may contain other sets.
- New nodes: `Heading` (per-level styles via `TiptapViewerTheme.headingStyle`),
  `CodeBlock` (monospace, whitespace-preserving, tinted), `HorizontalRule`,
  `HardBreak` (with `HardBreak(mode: …)` rendering it as a `newline` (default)
  or a `space`).
- New marks: `Code` (inline monospace) and `Link` (in StarterKit, styled but
  non-interactive by default; add `Link(onTap: …)` after the kit to make links
  tappable).
- `TiptapMarkExtension.buildRecognizer`: lets a mark attach a tap recognizer
  (used by `Link`).
- `TiptapInlineExtension.toPlainText` / `buildFlattened`: hooks an inline
  extension uses to contribute its flattened/plain-text form (used by `Mention`).
- `inlineLeafText(extensions)`: builds an `inlineLeaf` hook for `toPlainText`, so
  mentions (and other inline extensions) appear in extracted text when enabled.
- Theme tokens: `headingStyles`, `codeBlockBackground/Padding/Radius/TextStyle`,
  `inlineCodeStyle`, `hrColor/hrThickness/hrSpacing`, `linkColor/linkUnderline`.

### Changed

- `TiptapExtension` is now a `sealed`, typeless base (like TipTap's `Extension`);
  the `type` getter moved to a new `TiptapTypedExtension` layer above
  nodes/marks. Custom extensions keep subclassing `TiptapBlockExtension` /
  `TiptapInlineExtension` / `TiptapMarkExtension` as before.
- The zero-config default now renders headings, code blocks, horizontal rules,
  hard breaks, inline code, and (non-interactive) links.
- `TiptapNode.toPlainText()` / `TiptapDocument.toPlainText()` no longer emit
  `@label` for mentions by default — pass an `inlineLeaf` hook (e.g. via
  `inlineLeafText([StarterKit(), Mention()])`) to include them. This matches
  mentions being opt-in everywhere else.
- `Mention` moved to its own file and is no longer special-cased anywhere in the
  renderer or model; it is now an ordinary inline extension built only from
  public API.

### Removed

- `kDefaultTiptapExtensions` — use `StarterKit` (the default when `extensions`
  is null, or list `const StarterKit()` explicitly).

## [0.0.2] - 2026-06-13

Add a flattened plain/inline rendering path for compact, truncatable previews.

### Added

- `TiptapText` widget: flattens a whole document into a single truncatable inline
  run for compact previews, instead of the block column `TiptapViewer` builds.
  Supports `maxLines` + `overflow`, a hard `maxChars` cap (with an optional
  `ellipsis`), `includeStyle` style stripping (keep vs. drop bold/italic/
  underline/strike), a configurable block `separator`, and opt-in `selectable`.
  Mentions render as `@label` so a preview never silently drops one.
- `TiptapDocument.toPlainText()` / `TiptapNode.toPlainText()`: pure-string
  flattening (mentions as `@label`, block siblings joined by a separator) for
  callers that just need text (search, accessibility labels).
- `TiptapRenderer.buildFlattenedSpan()`: the inline-flattening primitive behind
  `TiptapText`.

## [0.0.1] - 2026-06-13

Initial release: render TipTap JSON as native, selectable Flutter widgets via a
composable extension list and a single `TiptapViewerTheme` styling surface.

### Added

- Initial scaffold: `TiptapViewer` widget rendering TipTap JSON (string or map).
- Model layer: `TiptapDocument`, `TiptapNode`, `TiptapMark` with tolerant parsing.
- Extension system: block/inline/mark extensions with a disabled-behavior rule
  (`unwrap` / `strip`) and debug-only warnings for dropped types.
- Nodes: `Doc`, `Paragraph`, `Blockquote`, `BulletList`, `OrderedList` (honors
  `start`), `ListItem`, `TextNode`.
- Marks: `Bold`, `Italic`, `Underline`, `Strike`.
- Custom extension `Mention` (opt-in; not in the default set) with
  `highlight` / `chip` / `plain` display modes and an `onTap` callback.
- `TiptapViewerTheme` single styling surface with `.fromContext` + `copyWith`.
- `renderEmptyParagraphs` theme option (default `false`) to strip empty
  paragraphs instead of rendering them as blank-line spacers.
- `nestedListIndent` theme token so nested lists indent less than top-level
  lists.
- `MentionDisplay.plain` to render a mention as its bare label text (no color,
  weight, chip, or tap), as an alternative to `highlight` / `chip` or stripping
  it from the active extension set.
- Opt-out `selectable` (`SelectionArea`) selection/copy support.
- Example app with live node/mark toggles, theme selector, mention display
  toggle, and a fake-FlutterFlow theme mapping.
- Unit + widget tests; GitHub Actions CI (analyze + test + publish dry-run).

[Unreleased]: https://github.com/AndrewMast/ff_tiptap_viewer/compare/v0.0.3...HEAD
[0.0.3]: https://github.com/AndrewMast/ff_tiptap_viewer/compare/v0.0.2...v0.0.3
[0.0.2]: https://github.com/AndrewMast/ff_tiptap_viewer/compare/v0.0.1...v0.0.2
[0.0.1]: https://github.com/AndrewMast/ff_tiptap_viewer/releases/tag/v0.0.1
