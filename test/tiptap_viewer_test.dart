import 'package:ff_tiptap_viewer/ff_tiptap_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

/// Pumps [child] inside a minimal Material host.
Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(home: Scaffold(body: child)),
  );
}

/// Finds the style of the first inline span whose text == [text].
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
    if (result != null) {
      break;
    }
  }
  return result;
}

/// Whether any rendered RichText contains a WidgetSpan (i.e. a chip mention).
bool _hasWidgetSpan(WidgetTester tester) {
  for (final rt in tester.widgetList<RichText>(find.byType(RichText))) {
    var found = false;
    rt.text.visitChildren((span) {
      if (span is WidgetSpan) {
        found = true;
        return false;
      }
      return true;
    });
    if (found) {
      return true;
    }
  }
  return false;
}

/// Counts rendered [SizedBox] widgets whose height equals [height].
int _countSizedBoxesOfHeight(WidgetTester tester, double height) {
  return tester
      .widgetList<SizedBox>(find.byType(SizedBox))
      .where((b) => b.height == height)
      .length;
}

/// Counts rendered [Padding] widgets whose left inset equals [left].
int _countPaddingLeft(WidgetTester tester, double left) {
  return tester
      .widgetList<Padding>(find.byType(Padding))
      .where((p) => p.padding is EdgeInsets && (p.padding as EdgeInsets).left == left)
      .length;
}

/// Two paragraphs separated by an intentionally empty paragraph (spacer).
const Map<String, dynamic> _emptyParagraphDoc = <String, dynamic>{
  'type': 'doc',
  'content': <Map<String, dynamic>>[
    <String, dynamic>{
      'type': 'paragraph',
      'content': <Map<String, dynamic>>[
        <String, dynamic>{'type': 'text', 'text': 'Above'},
      ],
    },
    <String, dynamic>{'type': 'paragraph'},
    <String, dynamic>{
      'type': 'paragraph',
      'content': <Map<String, dynamic>>[
        <String, dynamic>{'type': 'text', 'text': 'Below'},
      ],
    },
  ],
};

/// A bullet item whose content is a paragraph followed by a nested bullet list
/// — the shape that previously got pushed apart by paragraphSpacing.
const Map<String, dynamic> _nestedListDoc = <String, dynamic>{
  'type': 'doc',
  'content': <Map<String, dynamic>>[
    <String, dynamic>{
      'type': 'bulletList',
      'content': <Map<String, dynamic>>[
        <String, dynamic>{
          'type': 'listItem',
          'content': <Map<String, dynamic>>[
            <String, dynamic>{
              'type': 'paragraph',
              'content': <Map<String, dynamic>>[
                <String, dynamic>{'type': 'text', 'text': 'Parent'},
              ],
            },
            <String, dynamic>{
              'type': 'bulletList',
              'content': <Map<String, dynamic>>[
                <String, dynamic>{
                  'type': 'listItem',
                  'content': <Map<String, dynamic>>[
                    <String, dynamic>{
                      'type': 'paragraph',
                      'content': <Map<String, dynamic>>[
                        <String, dynamic>{'type': 'text', 'text': 'Child'},
                      ],
                    },
                  ],
                },
              ],
            },
          ],
        },
      ],
    },
  ],
};

/// A document containing a single mention, for isolating mention behavior.
const Map<String, dynamic> _mentionOnlyDoc = <String, dynamic>{
  'type': 'doc',
  'content': <Map<String, dynamic>>[
    <String, dynamic>{
      'type': 'paragraph',
      'content': <Map<String, dynamic>>[
        <String, dynamic>{
          'type': 'mention',
          'attrs': <String, dynamic>{'id': 'course@123', 'label': 'My Course'},
        },
      ],
    },
  ],
};

void main() {
  group('TiptapViewer rendering', () {
    testWidgets('renders plain text content', (tester) async {
      await _pump(tester,
          const TiptapViewer(document: kKitchenSinkDoc, selectable: false));
      expect(find.textContaining('Plain,'), findsOneWidget);
    });

    testWidgets('bold mark applies the theme bold weight', (tester) async {
      await _pump(tester,
          const TiptapViewer(document: kKitchenSinkDoc, selectable: false));
      expect(_spanStyle(tester, 'bold')?.fontWeight, FontWeight.w700);
    });

    testWidgets('stacked marks all apply to one span', (tester) async {
      await _pump(tester,
          const TiptapViewer(document: kKitchenSinkDoc, selectable: false));
      final style = _spanStyle(tester, 'stacked');
      expect(style?.fontWeight, FontWeight.w700);
      expect(style?.fontStyle, FontStyle.italic);
      expect(style?.decoration?.contains(TextDecoration.underline), isTrue);
      expect(style?.decoration?.contains(TextDecoration.lineThrough), isTrue);
    });

    testWidgets('blockquote and lists render', (tester) async {
      await _pump(tester,
          const TiptapViewer(document: kKitchenSinkDoc, selectable: false));
      expect(find.textContaining('Quoted line.'), findsOneWidget);
      expect(find.text('•'), findsNWidgets(2)); // two bullets
      expect(find.text('3.'), findsOneWidget); // nested ordered list start=3
    });
  });

  group('Mention extension', () {
    testWidgets('is stripped by default (not in the default set)',
        (tester) async {
      await _pump(tester,
          const TiptapViewer(document: kKitchenSinkDoc, selectable: false));
      expect(find.textContaining('@My Course'), findsNothing);
      // Surrounding content still renders.
      expect(find.textContaining('and a'), findsOneWidget);
    });

    testWidgets('renders when explicitly added', (tester) async {
      await _pump(
        tester,
        TiptapViewer(
          document: kKitchenSinkDoc,
          selectable: false,
          extensions: <TiptapExtension>[
            ...kDefaultTiptapExtensions,
            const Mention(),
          ],
        ),
      );
      expect(find.textContaining('@My Course'), findsOneWidget);
    });

    testWidgets('onTap fires with raw (id, label)', (tester) async {
      String? tappedId;
      String? tappedLabel;
      const mentionOnly = <String, dynamic>{
        'type': 'doc',
        'content': <Map<String, dynamic>>[
          <String, dynamic>{
            'type': 'paragraph',
            'content': <Map<String, dynamic>>[
              <String, dynamic>{
                'type': 'mention',
                'attrs': <String, dynamic>{
                  'id': 'course@123',
                  'label': 'My Course',
                },
              },
            ],
          },
        ],
      };

      await _pump(
        tester,
        TiptapViewer(
          document: mentionOnly,
          selectable: false,
          extensions: <TiptapExtension>[
            ...kDefaultTiptapExtensions,
            Mention(onTap: (id, label) {
              tappedId = id;
              tappedLabel = label;
            }),
          ],
        ),
      );

      await tester.tap(find.textContaining('@My Course'));
      await tester.pump();

      expect(tappedId, 'course@123');
      expect(tappedLabel, 'My Course');
    });
  });

  group('Mention display', () {
    testWidgets('highlight renders a TextSpan (no WidgetSpan)', (tester) async {
      await _pump(
        tester,
        TiptapViewer(
          document: _mentionOnlyDoc,
          selectable: false,
          extensions: <TiptapExtension>[
            ...kDefaultTiptapExtensions,
            const Mention(),
          ],
        ),
      );
      expect(find.textContaining('@My Course'), findsOneWidget);
      expect(_hasWidgetSpan(tester), isFalse);
    });

    testWidgets('chip renders a WidgetSpan', (tester) async {
      await _pump(
        tester,
        TiptapViewer(
          document: _mentionOnlyDoc,
          selectable: false,
          extensions: <TiptapExtension>[
            ...kDefaultTiptapExtensions,
            const Mention(display: MentionDisplay.chip),
          ],
        ),
      );
      expect(_hasWidgetSpan(tester), isTrue);
      expect(find.text('@My Course'), findsOneWidget); // chip's own Text
    });

    testWidgets('plain renders the bare label as text (no @, no chip)',
        (tester) async {
      await _pump(
        tester,
        TiptapViewer(
          document: _mentionOnlyDoc,
          selectable: false,
          extensions: <TiptapExtension>[
            ...kDefaultTiptapExtensions,
            const Mention(display: MentionDisplay.plain),
          ],
        ),
      );
      expect(find.textContaining('My Course'), findsOneWidget);
      expect(find.textContaining('@'), findsNothing);
      expect(_hasWidgetSpan(tester), isFalse);
      // No mention styling — it inherits the surrounding body style.
      expect(_spanStyle(tester, 'My Course')?.fontWeight,
          isNot(const TiptapViewerTheme().mentionWeight));
    });

    testWidgets('chip onTap fires with raw (id, label)', (tester) async {
      String? tappedId;
      String? tappedLabel;
      await _pump(
        tester,
        TiptapViewer(
          document: _mentionOnlyDoc,
          selectable: false,
          extensions: <TiptapExtension>[
            ...kDefaultTiptapExtensions,
            Mention(
              display: MentionDisplay.chip,
              onTap: (id, label) {
                tappedId = id;
                tappedLabel = label;
              },
            ),
          ],
        ),
      );

      await tester.tap(find.text('@My Course'));
      await tester.pump();

      expect(tappedId, 'course@123');
      expect(tappedLabel, 'My Course');
    });
  });

  group('disabled behavior', () {
    testWidgets('disabled mark degrades to plain text', (tester) async {
      // All defaults except Bold — the bold word should render unweighted.
      final withoutBold = kDefaultTiptapExtensions
          .where((e) => e.type != 'bold')
          .toList(growable: false);
      await _pump(
        tester,
        TiptapViewer(
          document: kKitchenSinkDoc,
          selectable: false,
          extensions: withoutBold,
        ),
      );
      expect(find.textContaining('bold'), findsOneWidget); // still rendered
      expect(_spanStyle(tester, 'bold')?.fontWeight, isNot(FontWeight.w700));
    });
  });

  group('theme overrides', () {
    testWidgets('custom boldWeight is applied', (tester) async {
      await _pump(
        tester,
        const TiptapViewer(
          document: kKitchenSinkDoc,
          selectable: false,
          theme: TiptapViewerTheme(boldWeight: FontWeight.w900),
        ),
      );
      expect(_spanStyle(tester, 'bold')?.fontWeight, FontWeight.w900);
    });
  });

  group('empty paragraphs', () {
    // A baseTextStyle with a clean line height makes the one-line spacer
    // (fontSize * height = 20) easy to find and distinct from paragraphSpacing.
    testWidgets('are stripped by default', (tester) async {
      await _pump(
        tester,
        const TiptapViewer(
          document: _emptyParagraphDoc,
          selectable: false,
          theme: TiptapViewerTheme(
            baseTextStyle: TextStyle(fontSize: 20, height: 1.0),
          ),
        ),
      );
      // Both lines still render; the blank-line spacer is gone.
      expect(find.text('Above'), findsOneWidget);
      expect(find.text('Below'), findsOneWidget);
      expect(_countSizedBoxesOfHeight(tester, 20.0), 0);
    });

    testWidgets('render as a one-line spacer when enabled', (tester) async {
      await _pump(
        tester,
        const TiptapViewer(
          document: _emptyParagraphDoc,
          selectable: false,
          theme: TiptapViewerTheme(
            baseTextStyle: TextStyle(fontSize: 20, height: 1.0),
            renderEmptyParagraphs: true,
          ),
        ),
      );
      expect(find.text('Above'), findsOneWidget);
      expect(find.text('Below'), findsOneWidget);
      expect(_countSizedBoxesOfHeight(tester, 20.0), 1);
    });
  });

  group('nested lists', () {
    testWidgets('use the tighter list gap, not paragraphSpacing', (tester) async {
      // Distinct values so the gap actually used is unambiguous.
      await _pump(
        tester,
        const TiptapViewer(
          document: _nestedListDoc,
          selectable: false,
          theme: TiptapViewerTheme(
            paragraphSpacing: 30,
            listItemSpacing: 7,
          ),
        ),
      );
      expect(find.text('Parent'), findsOneWidget);
      expect(find.text('Child'), findsOneWidget);
      // The gap before the nested list is listItemSpacing...
      expect(_countSizedBoxesOfHeight(tester, 7.0), 1);
      // ...and paragraphSpacing never breaks the list up.
      expect(_countSizedBoxesOfHeight(tester, 30.0), 0);
    });

    testWidgets('nested list indents less than the top-level list',
        (tester) async {
      // Distinct, unlikely-to-collide indents pin down which one each list used.
      await _pump(
        tester,
        const TiptapViewer(
          document: _nestedListDoc,
          selectable: false,
          theme: TiptapViewerTheme(
            listIndent: 23,
            nestedListIndent: 9,
          ),
        ),
      );
      expect(_countPaddingLeft(tester, 23.0), 1); // top-level list
      expect(_countPaddingLeft(tester, 9.0), 1); // nested list, indented less
    });
  });

  group('selectable flag', () {
    testWidgets('wraps in a SelectionArea when true', (tester) async {
      await _pump(tester,
          const TiptapViewer(document: kKitchenSinkDoc, selectable: true));
      expect(find.byType(SelectionArea), findsOneWidget);
    });

    testWidgets('no SelectionArea when false', (tester) async {
      await _pump(tester,
          const TiptapViewer(document: kKitchenSinkDoc, selectable: false));
      expect(find.byType(SelectionArea), findsNothing);
    });
  });

  group('tolerant rendering', () {
    testWidgets('malformed input renders nothing', (tester) async {
      await _pump(tester,
          const TiptapViewer(document: '{not json', selectable: false));
      expect(find.byType(RichText), findsNothing);
    });
  });
}
