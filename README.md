# ff_tiptap_viewer

Render [TipTap](https://tiptap.dev) JSON as native, **selectable and copyable**
Flutter widgets. Zero runtime dependencies; composable extensions; a single
theming surface.

## Features

- Accepts the API's **JSON string** _or_ an already-decoded `Map`.
- A TipTap-style **`StarterKit`** is the default: `doc`, `paragraph`, `heading`,
  `blockquote`, `bulletList` / `orderedList` (with `start`) / `listItem`,
  `codeBlock`, `horizontalRule`, `hardBreak`, `text`; marks `bold`, `italic`,
  `underline`, `strike`, `code`, and `link` (styled, opt-in tap).
- **Extension sets** — bundle extensions into a reusable `TiptapExtensionSet`
  (like `StarterKit`) and combine sets with individual extensions in one list.
- Ships a custom `Mention` extension (opt-in — see below).
- **TipTap-style extension list** — include only the nodes/marks you want; the
  rest degrade gracefully (wrap → unwrap, leaf → strip).
- Text is **selectable/copyable** out of the box (`SelectionArea`).
- One `TiptapViewerTheme` controls all visual tokens.
- A flattened `TiptapText` widget (plus a pure `toPlainText()`) for compact,
  truncatable previews — see [Compact previews](#compact-previews-tiptaptext).

## Usage

```dart
TiptapViewer(
  document: courseDescriptionJsonString, // String or Map<String, dynamic>
  theme: TiptapViewerTheme.fromContext(context),
  selectable: true,
)
```

Omit `extensions` to use the default `StarterKit` (every supported node/mark
**except** `Mention`; links render styled but non-interactive). Pass a list to
take control — sets and individual extensions mix freely, and later entries win:

```dart
TiptapViewer(
  document: courseDescriptionJsonString,
  extensions: [
    const StarterKit(),                                  // the bundle
    Mention(onTap: (id, label) {/* navigate; id is opaque */}),
    Link(onTap: (href) {/* launchUrl(href) */}),         // makes links tappable
  ],
)
```

## StarterKit & extension sets

`StarterKit` is a `TiptapExtensionSet` — a group that flattens into its members.
Configure it by toggling members off, or by listing your own instance **after**
it (flattening is **last-wins**, so the later entry overrides the earlier one of
the same type):

```dart
extensions: [
  const StarterKit(blockquote: false),       // drop a member
  const Heading(),                           // replace/customize one (last-wins)
]
```

Build your own reusable set by subclassing `TiptapExtensionSet` (sets flatten
recursively, so a set may contain other sets):

```dart
class Dripstone extends TiptapExtensionSet {
  const Dripstone();
  @override
  List<TiptapExtension> get extensions =>
      const [StarterKit(), Mention(), Link()];
}

// then: extensions: const [Dripstone()]
```

## Links

`Link` ships **inside** `StarterKit`, but the kit's instance has no `onTap`, so
links render as colored/underlined **non-interactive** text by default (a link
with no handler is still readable). The package is dependency-free and never
opens URLs itself — list a wired `Link(onTap: …)` after the kit to handle taps:

```dart
extensions: [const StarterKit(), Link(onTap: (href) => launchUrl(Uri.parse(href)))]
```

## Compact previews (`TiptapText`)

`TiptapViewer` builds a column of block widgets — the full document. For a
list/card preview you usually want the opposite: the whole document **flattened
onto one truncatable line**. `TiptapText` does that.

```dart
TiptapText(
  document: courseDescriptionJsonString, // String or Map
  maxLines: 2,
  overflow: TextOverflow.ellipsis,       // line cap
  maxChars: 120,                         // hard character cap (adds an ellipsis)
  includeStyle: false,                   // strip bold/italic/underline/strike
)
```

Inline runs concatenate; block siblings (paragraphs, list items, blockquote
lines, …) are joined with `separator` (a space by default). Block *structure* —
indents, bullets, numbers, blockquote bars — is intentionally dropped; this is
the "plain" path. `TiptapText` uses `StarterKit` by default, so — like the
viewer — **mentions are opt-in**: pass `extensions: [StarterKit(), Mention()]`
to have them render as `@label` (in the theme's mention color/weight when
`includeStyle` is true).

`maxLines` + `overflow` give a visual line cap; `maxChars` is a hard character
cap that cuts the text and appends `ellipsis` (default `…`, set `''` to cut with
no marker). `TiptapText` is **not** wrapped in a `SelectionArea` by default
(`selectable: false`) — previews are usually tap-through.

> **Note:** with `overflow: TextOverflow.ellipsis`, the trailing `…` is drawn by
> Flutter's text layout and adopts the style of the run it truncates inside — so
> when the cut lands in marked text (and `includeStyle` is true), the `…` can
> pick up that run's weight/color/decoration (e.g. a strikethrough running
> through the ellipsis). This is a Flutter limitation. The `maxChars` cap is not
> affected — it appends its own `ellipsis` in the base style — so reach for
> `maxChars` (or `includeStyle: false`) when a clean ellipsis matters.

When you only need a `String` (search, accessibility labels), skip the widget and
call `TiptapDocument.toPlainText()` (or `TiptapNode.toPlainText()`) directly. By
default this extracts `text` only; to include inline extensions like mentions
(`@label`), pass an `inlineLeaf` hook built from your extensions:

```dart
doc.toPlainText(inlineLeaf: inlineLeafText(const [StarterKit(), Mention()]));
```

## Mentions (custom extension)

`Mention` is a custom extension, kept out of the default set so it only renders
when you add it explicitly and wire up `onTap`.

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
trivial since FF exposes plain `Color`/`TextStyle`. In the FlutterFlow app:

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
