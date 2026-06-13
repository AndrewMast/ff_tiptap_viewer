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
