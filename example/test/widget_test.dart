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

    // Sample document content is rendered.
    expect(find.textContaining('This viewer renders'), findsOneWidget);

    // The node/mark toggles are present.
    expect(find.text('bold'), findsOneWidget);
    expect(find.text('mention'), findsOneWidget);
  });
}
