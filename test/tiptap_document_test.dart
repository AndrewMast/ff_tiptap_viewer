import 'package:ff_tiptap_viewer/ff_tiptap_viewer.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  group('TiptapDocument.parse', () {
    test('parses the real-world JSON string', () {
      final doc = TiptapDocument.parse(kRealWorldFixture);
      expect(doc, isNotNull);
      expect(doc!.root.type, 'doc');

      final paragraph = doc.root.content.single;
      expect(paragraph.type, 'paragraph');
      expect(paragraph.content.length, 5);

      final boldNode = paragraph.content[1];
      expect(boldNode.text, 'bold');
      expect(boldNode.marks.single.type, 'bold');
    });

    test('accepts an already-decoded Map', () {
      final doc = TiptapDocument.parse(kKitchenSinkDoc);
      expect(doc, isNotNull);
      expect(doc!.root.type, 'doc');
    });

    test('parses stacked marks on a single text node', () {
      final doc = TiptapDocument.parse(kKitchenSinkDoc)!;
      final firstParagraph = doc.root.content.first;
      final stacked =
          firstParagraph.content.firstWhere((n) => n.text == 'stacked');
      expect(
        stacked.marks.map((m) => m.type),
        containsAll(<String>['bold', 'italic', 'underline', 'strike']),
      );
    });

    test('parses mention attributes', () {
      final doc = TiptapDocument.parse(kKitchenSinkDoc)!;
      final mention = doc.root.content.first.content
          .firstWhere((n) => n.type == 'mention');
      expect(mention.attrs['id'], 'course@123');
      expect(mention.attrs['label'], 'My Course');
    });

    test('keeps an empty paragraph as an empty node', () {
      final doc = TiptapDocument.parse(kKitchenSinkDoc)!;
      final empties =
          doc.root.content.where((n) => n.type == 'paragraph' && n.content.isEmpty);
      expect(empties, isNotEmpty);
    });

    test('reads the ordered list start attribute', () {
      final doc = TiptapDocument.parse(kKitchenSinkDoc)!;
      final bulletList =
          doc.root.content.firstWhere((n) => n.type == 'bulletList');
      final nestedOrdered = bulletList.content.first.content
          .firstWhere((n) => n.type == 'orderedList');
      expect(nestedOrdered.attrs['start'], 3);
    });

    group('tolerant of bad input', () {
      test('empty string → null', () {
        expect(TiptapDocument.parse(''), isNull);
        expect(TiptapDocument.parse('   '), isNull);
      });

      test('malformed JSON → null (no throw)', () {
        expect(TiptapDocument.parse('{not json'), isNull);
      });

      test('non-object JSON → null', () {
        expect(TiptapDocument.parse('[1,2,3]'), isNull);
        expect(TiptapDocument.parse('42'), isNull);
      });

      test('null → null', () {
        expect(TiptapDocument.parse(null), isNull);
      });
    });
  });
}
