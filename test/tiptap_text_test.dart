import 'package:ff_tiptap_viewer/ff_tiptap_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

/// Pumps [child] inside a minimal Material host.
Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

/// The single flattened [Text.rich]'s root span.
TextSpan _rootSpan(WidgetTester tester) {
  final richText = tester.widget<RichText>(find.byType(RichText));
  return richText.text as TextSpan;
}

/// Concatenates all text in the rendered RichText, in order.
String _renderedText(WidgetTester tester) {
  final buffer = StringBuffer();
  _rootSpan(tester).visitChildren((span) {
    if (span is TextSpan && span.text != null) {
      buffer.write(span.text);
    }
    return true;
  });
  return buffer.toString();
}

/// The style of the first inline span whose text == [text].
TextStyle? _spanStyle(WidgetTester tester, String text) {
  TextStyle? result;
  _rootSpan(tester).visitChildren((span) {
    if (span is TextSpan && span.text == text) {
      result = span.style;
      return false;
    }
    return true;
  });
  return result;
}

void main() {
  group('TiptapText flattening', () {
    testWidgets('renders one RichText, not a block Column', (tester) async {
      await _pump(tester, const TiptapText(document: kKitchenSinkDoc));
      expect(find.byType(RichText), findsOneWidget);
    });

    testWidgets('flattens every block onto a single run', (tester) async {
      await _pump(tester, const TiptapText(document: kKitchenSinkDoc));
      final text = _renderedText(tester);
      // Inline runs of the first paragraph concatenate directly...
      expect(text, contains('Plain, bold, italic, stacked, '));
      // ...and later blocks are all present in the same run.
      expect(text, contains('Quoted line.'));
      expect(text, contains('First bullet'));
      expect(text, contains('Second bullet'));
      expect(text, contains('Nested three'));
    });

    testWidgets('joins block siblings with the separator', (tester) async {
      await _pump(
        tester,
        const TiptapText(document: kKitchenSinkDoc, separator: ' | '),
      );
      final text = _renderedText(tester);
      // Blockquote line and the bullet that follows it are block siblings.
      expect(text, contains('Quoted line. | First bullet'));
    });

    testWidgets('malformed input renders nothing', (tester) async {
      await _pump(tester, const TiptapText(document: '{not json'));
      expect(find.byType(RichText), findsNothing);
    });
  });

  group('TiptapText mark stripping', () {
    testWidgets('keeps marks when includeStyle is true (default)',
        (tester) async {
      await _pump(tester, const TiptapText(document: kKitchenSinkDoc));
      expect(_spanStyle(tester, 'bold')?.fontWeight, FontWeight.w700);
      final stacked = _spanStyle(tester, 'stacked');
      expect(stacked?.fontStyle, FontStyle.italic);
      expect(stacked?.decoration?.contains(TextDecoration.underline), isTrue);
    });

    testWidgets('strips marks when includeStyle is false', (tester) async {
      await _pump(
        tester,
        const TiptapText(document: kKitchenSinkDoc, includeStyle: false),
      );
      expect(_spanStyle(tester, 'bold')?.fontWeight, isNot(FontWeight.w700));
      expect(_spanStyle(tester, 'stacked')?.fontStyle, isNot(FontStyle.italic));
      expect(_spanStyle(tester, 'stacked')?.decoration ?? TextDecoration.none,
          TextDecoration.none);
    });
  });

  group('TiptapText mentions', () {
    // StarterKit (the default) excludes Mention, so add it to show mentions.
    const withMention = <TiptapExtension>[StarterKit(), Mention()];

    testWidgets('drops mentions by default (StarterKit excludes Mention)',
        (tester) async {
      await _pump(tester, const TiptapText(document: kKitchenSinkDoc));
      expect(_renderedText(tester), isNot(contains('@My Course')));
      // Surrounding text still flattens correctly.
      expect(_renderedText(tester), contains('and a .'));
    });

    testWidgets('renders mentions as @label when Mention is supplied',
        (tester) async {
      await _pump(
        tester,
        const TiptapText(document: kKitchenSinkDoc, extensions: withMention),
      );
      expect(_renderedText(tester), contains('@My Course'));
    });

    testWidgets('styles the mention with theme color/weight when styled',
        (tester) async {
      const theme = TiptapViewerTheme(
        mentionColor: Color(0xFF112233),
        mentionWeight: FontWeight.w800,
      );
      await _pump(
        tester,
        const TiptapText(
          document: kKitchenSinkDoc,
          theme: theme,
          extensions: withMention,
        ),
      );
      expect(_spanStyle(tester, '@My Course')?.fontWeight, theme.mentionWeight);
      expect(_spanStyle(tester, '@My Course')?.color, theme.mentionColor);
    });

    testWidgets('mention inherits base style when includeStyle is false',
        (tester) async {
      await _pump(
        tester,
        const TiptapText(
          document: kKitchenSinkDoc,
          includeStyle: false,
          extensions: withMention,
        ),
      );
      expect(_spanStyle(tester, '@My Course')?.fontWeight,
          isNot(const TiptapViewerTheme().mentionWeight));
    });
  });

  group('TiptapText maxLines / overflow', () {
    testWidgets('passes maxLines and overflow through to Text.rich',
        (tester) async {
      await _pump(
        tester,
        const TiptapText(
          document: kKitchenSinkDoc,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      );
      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(richText.maxLines, 2);
      expect(richText.overflow, TextOverflow.ellipsis);
    });

    testWidgets('no maxLines forces clip so an ellipsis does not collapse to '
        'one line', (tester) async {
      // With overflow: ellipsis but no maxLines, the text engine would treat it
      // as a single line; the widget overrides to clip so all lines render.
      await _pump(
        tester,
        const TiptapText(
          document: kKitchenSinkDoc,
          overflow: TextOverflow.ellipsis,
        ),
      );
      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(richText.maxLines, isNull);
      expect(richText.overflow, TextOverflow.clip);
    });
  });

  group('TiptapText maxChars', () {
    testWidgets('caps the rendered text and appends the ellipsis',
        (tester) async {
      await _pump(
        tester,
        const TiptapText(document: kKitchenSinkDoc, maxChars: 5),
      );
      // 5 chars of "Plain, …" + the ellipsis marker.
      expect(_renderedText(tester), 'Plain…');
    });

    testWidgets('does not append the ellipsis when nothing is cut',
        (tester) async {
      const doc = <String, dynamic>{
        'type': 'doc',
        'content': <Map<String, dynamic>>[
          <String, dynamic>{
            'type': 'paragraph',
            'content': <Map<String, dynamic>>[
              <String, dynamic>{'type': 'text', 'text': 'Short'},
            ],
          },
        ],
      };
      await _pump(tester, const TiptapText(document: doc, maxChars: 100));
      expect(_renderedText(tester), 'Short');
    });

    testWidgets('cuts across spans without an ellipsis when ellipsis is empty',
        (tester) async {
      await _pump(
        tester,
        const TiptapText(
          document: kKitchenSinkDoc,
          maxChars: 9,
          ellipsis: '',
        ),
      );
      // "Plain, bo" — the cut lands inside the bold span, keeping styled runs.
      expect(_renderedText(tester), 'Plain, bo');
    });
  });

  group('TiptapText selectable', () {
    testWidgets('is not selectable by default', (tester) async {
      await _pump(tester, const TiptapText(document: kKitchenSinkDoc));
      expect(find.byType(SelectionArea), findsNothing);
    });

    testWidgets('wraps in a SelectionArea when requested', (tester) async {
      await _pump(
        tester,
        const TiptapText(document: kKitchenSinkDoc, selectable: true),
      );
      expect(find.byType(SelectionArea), findsOneWidget);
    });
  });
}
