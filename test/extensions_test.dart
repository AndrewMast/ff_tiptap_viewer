import 'package:ff_tiptap_viewer/ff_tiptap_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

/// The style of the first inline span whose text == [text], across all RichText.
TextStyle? _spanStyle(WidgetTester tester, String text) {
  TextStyle? result;
  for (final rt in tester.widgetList<RichText>(find.byType(RichText))) {
    rt.text.visitChildren((span) {
      if (span is TextSpan && span.text == text) {
        result = span.style;
        return false;
      }
      return true;
    });
    if (result != null) break;
  }
  return result;
}

/// The first inline span whose text == [text], across all RichText.
TextSpan? _span(WidgetTester tester, String text) {
  TextSpan? result;
  for (final rt in tester.widgetList<RichText>(find.byType(RichText))) {
    rt.text.visitChildren((span) {
      if (span is TextSpan && span.text == text) {
        result = span;
        return false;
      }
      return true;
    });
    if (result != null) break;
  }
  return result;
}

Map<String, dynamic> _docOf(List<Map<String, dynamic>> content) =>
    <String, dynamic>{'type': 'doc', 'content': content};

Map<String, dynamic> _para(List<Map<String, dynamic>> content) =>
    <String, dynamic>{'type': 'paragraph', 'content': content};

Map<String, dynamic> _text(String text, [List<Map<String, dynamic>>? marks]) =>
    <String, dynamic>{
      'type': 'text',
      'text': text,
      if (marks != null) 'marks': marks,
    };

const _knownBase = TiptapViewerTheme(baseTextStyle: TextStyle(fontSize: 16));

void main() {
  group('Heading', () {
    testWidgets('renders with the per-level style (bold, scaled)',
        (tester) async {
      final doc = _docOf([
        <String, dynamic>{
          'type': 'heading',
          'attrs': <String, dynamic>{'level': 1},
          'content': <Map<String, dynamic>>[_text('Title')],
        },
      ]);
      await _pump(tester,
          TiptapViewer(document: doc, selectable: false, theme: _knownBase));
      final style = _spanStyle(tester, 'Title');
      expect(style?.fontWeight, FontWeight.w700);
      expect(style?.fontSize, 32); // 16 * 2.0 (h1 scale)
    });

    testWidgets('coerces an out-of-range / stringy level without throwing',
        (tester) async {
      final doc = _docOf([
        <String, dynamic>{
          'type': 'heading',
          'attrs': <String, dynamic>{'level': '3'},
          'content': <Map<String, dynamic>>[_text('Three')],
        },
      ]);
      await _pump(tester,
          TiptapViewer(document: doc, selectable: false, theme: _knownBase));
      expect(tester.takeException(), isNull);
      expect(_spanStyle(tester, 'Three')?.fontSize, 20); // 16 * 1.25 (h3)
    });

    testWidgets('unwraps to plain text when disabled via StarterKit flag',
        (tester) async {
      final doc = _docOf([
        <String, dynamic>{
          'type': 'heading',
          'attrs': <String, dynamic>{'level': 1},
          'content': <Map<String, dynamic>>[_text('Title')],
        },
      ]);
      await _pump(
        tester,
        TiptapViewer(
          document: doc,
          selectable: false,
          theme: _knownBase,
          extensions: const <TiptapExtension>[StarterKit(heading: false)],
        ),
      );
      // Still rendered, but at body size — not the heading size.
      expect(_spanStyle(tester, 'Title')?.fontSize, isNot(32));
    });
  });

  group('CodeBlock', () {
    testWidgets('renders the literal code in a tinted container', (tester) async {
      final doc = _docOf([
        <String, dynamic>{
          'type': 'codeBlock',
          'content': <Map<String, dynamic>>[_text('const x = 1;')],
        },
      ]);
      await _pump(
        tester,
        TiptapViewer(
          document: doc,
          selectable: false,
          theme: _knownBase.copyWith(codeBlockBackground: const Color(0xFFABCDEF)),
        ),
      );
      expect(find.text('const x = 1;'), findsOneWidget);
      final hasTintedBox = tester.widgetList<Container>(find.byType(Container)).any(
            (c) => c.decoration is BoxDecoration &&
                (c.decoration as BoxDecoration).color == const Color(0xFFABCDEF),
          );
      expect(hasTintedBox, isTrue);
    });
  });

  group('HorizontalRule', () {
    testWidgets('renders a colored rule', (tester) async {
      final doc = _docOf([
        _para([_text('A')]),
        <String, dynamic>{'type': 'horizontalRule'},
        _para([_text('B')]),
      ]);
      await _pump(
        tester,
        TiptapViewer(
          document: doc,
          selectable: false,
          theme: _knownBase.copyWith(hrColor: const Color(0xFF00FF00)),
        ),
      );
      final hasRule = tester
          .widgetList<Container>(find.byType(Container))
          .any((c) => c.color == const Color(0xFF00FF00));
      expect(hasRule, isTrue);
    });

    testWidgets('is stripped when disabled (leaf has nothing to unwrap to)',
        (tester) async {
      final doc = _docOf([
        _para([_text('A')]),
        <String, dynamic>{'type': 'horizontalRule'},
        _para([_text('B')]),
      ]);
      await _pump(
        tester,
        TiptapViewer(
          document: doc,
          selectable: false,
          theme: _knownBase.copyWith(hrColor: const Color(0xFF00FF00)),
          extensions: const <TiptapExtension>[StarterKit(horizontalRule: false)],
        ),
      );
      final hasRule = tester
          .widgetList<Container>(find.byType(Container))
          .any((c) => c.color == const Color(0xFF00FF00));
      expect(hasRule, isFalse);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });
  });

  group('HardBreak', () {
    final doc = _docOf([
      _para([
        _text('a'),
        <String, dynamic>{'type': 'hardBreak'},
        _text('b'),
      ]),
    ]);

    testWidgets('renders a newline inside the run by default', (tester) async {
      await _pump(tester,
          TiptapViewer(document: doc, selectable: false, theme: _knownBase));
      expect(_span(tester, '\n'), isNotNull);
    });

    testWidgets('renders as a space in the viewer when mode is space',
        (tester) async {
      await _pump(
        tester,
        TiptapViewer(
          document: doc,
          selectable: false,
          theme: _knownBase,
          extensions: const <TiptapExtension>[
            StarterKit(),
            HardBreak(mode: HardBreakMode.space),
          ],
        ),
      );
      expect(_span(tester, ' '), isNotNull);
      expect(_span(tester, '\n'), isNull);
    });
  });

  group('Code mark', () {
    testWidgets('applies a monospace family', (tester) async {
      final doc = _docOf([
        _para([
          _text('snippet', <Map<String, dynamic>>[
            <String, dynamic>{'type': 'code'},
          ]),
        ]),
      ]);
      await _pump(tester,
          TiptapViewer(document: doc, selectable: false, theme: _knownBase));
      expect(_spanStyle(tester, 'snippet')?.fontFamily, 'monospace');
    });
  });

  group('Link mark', () {
    Map<String, dynamic> linkDoc() => _docOf([
          _para([
            _text('click me', <Map<String, dynamic>>[
              <String, dynamic>{
                'type': 'link',
                'attrs': <String, dynamic>{'href': 'https://example.com'},
              },
            ]),
          ]),
        ]);

    testWidgets('is styled but non-interactive in the default StarterKit',
        (tester) async {
      await _pump(
        tester,
        TiptapViewer(
          document: linkDoc(),
          selectable: false,
          theme: _knownBase.copyWith(linkColor: const Color(0xFF0000FF)),
        ),
      );
      final span = _span(tester, 'click me');
      expect(span?.style?.color, const Color(0xFF0000FF));
      expect(span?.style?.decoration?.contains(TextDecoration.underline), isTrue);
      // No tap handler wired → no recognizer.
      expect(span?.recognizer, isNull);
    });

    testWidgets('becomes tappable when a wired Link is listed after the kit',
        (tester) async {
      String? tappedHref;
      await _pump(
        tester,
        TiptapViewer(
          document: linkDoc(),
          selectable: false,
          theme: _knownBase,
          extensions: <TiptapExtension>[
            const StarterKit(),
            Link(onTap: (href) => tappedHref = href),
          ],
        ),
      );
      final span = _span(tester, 'click me');
      expect(span?.recognizer, isNotNull);
      await tester.tap(find.textContaining('click me'));
      await tester.pump();
      expect(tappedHref, 'https://example.com');
    });
  });

  group('flatten / override semantics', () {
    testWidgets('a later entry overrides an earlier type (last-wins)',
        (tester) async {
      final doc = _docOf([_para([_text('hi')])]);
      await _pump(
        tester,
        TiptapViewer(
          document: doc,
          selectable: false,
          theme: _knownBase,
          extensions: const <TiptapExtension>[StarterKit(), _MarkerParagraph()],
        ),
      );
      // The custom paragraph wins over StarterKit's.
      expect(find.text('OVERRIDDEN'), findsOneWidget);
    });

    testWidgets('a custom set flattens recursively (set inside the list)',
        (tester) async {
      final doc = _docOf([
        _para([
          _text('and a '),
          <String, dynamic>{
            'type': 'mention',
            'attrs': <String, dynamic>{'id': 'x', 'label': 'Bob'},
          },
        ]),
      ]);
      await _pump(
        tester,
        TiptapViewer(
          document: doc,
          selectable: false,
          theme: _knownBase,
          extensions: const <TiptapExtension>[_DripstoneSet()],
        ),
      );
      // _DripstoneSet = [StarterKit(), Mention()] — the nested kit + mention
      // both flatten in, so the mention renders.
      expect(find.textContaining('@Bob'), findsOneWidget);
    });
  });

  group('renderer.toPlainText', () {
    final doc = TiptapDocument.parse(_docOf([
      _para([
        _text('Hi '),
        <String, dynamic>{
          'type': 'mention',
          'attrs': <String, dynamic>{'id': 'x', 'label': 'Bob'},
        },
      ]),
    ]))!;

    testWidgets('flattens to a string via inline-extension hooks',
        (tester) async {
      late String withMention;
      late String withoutMention;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          String run(List<TiptapExtension> exts) => TiptapRenderer(
                context: context,
                theme: const TiptapViewerTheme(),
                registry: TiptapRegistry(exts),
              ).toPlainText(doc.root);
          withMention = run(const <TiptapExtension>[StarterKit(), Mention()]);
          withoutMention = run(const <TiptapExtension>[StarterKit()]);
          return const SizedBox();
        }),
      ));
      // Mention enabled -> its @label is included; otherwise dropped.
      expect(withMention, 'Hi @Bob');
      expect(withoutMention, 'Hi ');
    });
  });

  group('HardBreak mode (flattened path)', () {
    final doc = TiptapDocument.parse(_docOf([
      _para([
        _text('a'),
        const <String, dynamic>{'type': 'hardBreak'},
        _text('b'),
      ]),
    ]))!;

    String flat(HardBreakMode mode) => doc.toPlainText(
          inlineLeaf: inlineLeafText(<TiptapExtension>[
            const StarterKit(),
            HardBreak(mode: mode), // last-wins over the kit's HardBreak
          ]),
        );

    test('newline keeps the break', () {
      expect(flat(HardBreakMode.newline), 'a\nb');
    });

    test('space collapses onto one line', () {
      expect(flat(HardBreakMode.space), 'a b');
    });
  });
}

/// A custom block extension replacing `paragraph` to prove last-wins override.
class _MarkerParagraph extends TiptapBlockExtension {
  const _MarkerParagraph();

  @override
  String get type => 'paragraph';

  @override
  Widget buildBlock(TiptapRenderer r, TiptapNode node) =>
      const Text('OVERRIDDEN');
}

/// A custom set built on top of StarterKit, to prove recursive flattening.
class _DripstoneSet extends TiptapExtensionSet {
  const _DripstoneSet();

  @override
  List<TiptapExtension> get extensions =>
      const <TiptapExtension>[StarterKit(), Mention()];
}
