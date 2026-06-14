# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/2.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/AndrewMast/ff_tiptap_viewer/compare/v0.0.1...HEAD
[0.0.1]: https://github.com/AndrewMast/ff_tiptap_viewer/releases/tag/v0.0.1
