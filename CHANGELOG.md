# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Initial scaffold: `TiptapViewer` widget rendering TipTap JSON (string or map).
- Model layer: `TiptapDocument`, `TiptapNode`, `TiptapMark` with tolerant parsing.
- Extension system: block/inline/mark extensions with a disabled-behavior rule
  (`unwrap` / `strip`) and debug-only warnings for dropped types.
- Nodes: `Doc`, `Paragraph`, `Blockquote`, `BulletList`, `OrderedList` (honors
  `start`), `ListItem`, `TextNode`, `Mention` (`highlight` / `chip`).
- Marks: `Bold`, `Italic`, `Underline`, `Strike`.
- `TiptapViewerTheme` single styling surface with `.fromContext` + `copyWith`.
- Opt-out `selectable` (`SelectionArea`) selection/copy support.
- Example app with live node/mark toggles, theme selector, mention display
  toggle, and a fake-FlutterFlow theme mapping.
- Unit + widget tests; GitHub Actions CI (analyze + test + publish dry-run).
