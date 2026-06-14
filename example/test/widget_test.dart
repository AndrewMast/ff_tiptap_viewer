// Smoke test for the ff_tiptap_viewer example app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ff_tiptap_viewer_example/main.dart';

void main() {
  testWidgets('example app renders the sample document and controls',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ExampleApp());

    // App chrome.
    expect(find.text('ff_tiptap_viewer'), findsOneWidget);

    // Sample document content is rendered at the top of the list.
    expect(find.textContaining('This viewer renders'), findsWidgets);

    // The rest of the controls live below the fold — the list builds them
    // lazily, so scroll each into view before asserting on it.
    final listView = find.byType(Scrollable).first;

    await tester.scrollUntilVisible(
      find.text('Compact preview (TiptapText)'),
      300,
      scrollable: listView,
    );
    expect(find.text('Compact preview (TiptapText)'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('bold'),
      300,
      scrollable: listView,
    );
    expect(find.text('bold'), findsOneWidget);
    expect(find.text('mention'), findsOneWidget);
  });
}
