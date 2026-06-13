# ff_tiptap_viewer

Render [TipTap](https://tiptap.dev) (ProseMirror) JSON — the format
[Dripstone](https://dripstone.com) serves rich text in — as native, **selectable
and copyable** Flutter widgets. Zero runtime dependencies; composable
extensions; a single theming surface.

## Features

- Accepts the API's **JSON string** _or_ an already-decoded `Map`.
- Renders `paragraph`, `blockquote`, `bulletList`, `orderedList` (with `start`),
  `listItem`, `text`, and `mention`; marks `bold`, `italic`, `underline`,
  `strike`.
- **TipTap-style extension list** — include only the nodes/marks you want; the
  rest degrade gracefully (wrap → unwrap, leaf → strip).
- Text is **selectable/copyable** out of the box (`SelectionArea`).
- One `TiptapViewerTheme` controls all visual tokens.

## Usage

```dart
TiptapViewer(
  document: courseDescriptionJsonString, // String or Map<String, dynamic>
  extensions: <TiptapExtension>[
    Paragraph(), TextNode(), Bold(), Italic(), Underline(), Strike(),
    Blockquote(), BulletList(), OrderedList(), ListItem(),
    Mention(onTap: (id, label) {/* navigate; id is opaque */}),
  ],
  theme: TiptapViewerTheme.fromContext(context),
  selectable: true,
)
```

Omit `extensions` to use the default set (everything **except** `Mention` — add
that explicitly so mentions only render when you wire up `onTap`).

## Mentions

`Mention.onTap` receives the **raw** `(id, label)` strings exactly as stored;
the package never parses any id convention (e.g. `course@123`) — your app
decides what an id means.

`Mention(display: …)` chooses the render strategy:

- `MentionDisplay.highlight` (default) — a styled `TextSpan`. Selects and copies
  as real text; lighter, with a flat highlight.
- `MentionDisplay.chip` — a rounded `WidgetSpan` pill. Selection and copy are
  faithful too (the `@label` lands in the clipboard) — verified on web and iOS.
  Re-check on Android/desktop before relying on chip copy there.

## Theming

`TiptapViewerTheme` is the single styling surface; extensions only choose *which*
widgets get produced. Derive defaults with `TiptapViewerTheme.fromContext(context)`,
then `copyWith(...)`.

### FlutterFlow

A package can't import the host app's `FlutterFlowTheme`, but mapping it is
trivial since FF exposes plain `Color`/`TextStyle`. In the Dripstone app:

```dart
TiptapViewerTheme tiptapThemeFromFlutterFlow(FlutterFlowTheme ff) {
  return TiptapViewerTheme(
    baseTextStyle: ff.bodyMedium.copyWith(color: ff.primaryText),
    blockquoteBorderColor: ff.alternate,
    mentionColor: ff.primary,
    orderedNumberStyle: ff.bodyMedium.copyWith(color: ff.primaryText),
  );
}
```

See `example/lib/fake_flutter_flow_theme.dart` for a runnable version.

## Example

```sh
cd example
flutter create .          # generate platform folders (web/android/…)
flutter run -d chrome     # or an emulator
```

## License

MIT — see [LICENSE](LICENSE).
