# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.0.1] - 2026-06-13

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
