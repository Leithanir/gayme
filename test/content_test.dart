import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gayme/content/situation.dart';

void main() {
  const paths = [
    'assets/data/stereotypes.json',
    'assets/data/respectful.json',
  ];

  test('situation files follow the schema and content rules', () {
    final cards = <Situation>[];
    final ids = <String>{};
    final englishTexts = <String>{};

    for (final path in paths) {
      final file = File(path);

      expect(file.existsSync(), isTrue, reason: '$path is missing');

      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      expect(document['schemaVersion'], 1, reason: path);
      expect(document['defaultLanguage'], 'en', reason: path);

      final rawCards = document['cards'];

      expect(rawCards, isA<List<dynamic>>(), reason: path);

      for (final rawCard in rawCards as List<dynamic>) {
        final card =
            Situation.fromJson(rawCard as Map<String, dynamic>);

        expect(ids.add(card.id), isTrue,
            reason: 'duplicate id "${card.id}"');

        final english = card.text['en']!;
        final filipino = card.text['fil']!;

        expect(englishTexts.add(english), isTrue,
            reason: 'duplicate English text "$english"');

        expect(english.length, lessThanOrEqualTo(160), reason: card.id);
        expect(filipino.length, lessThanOrEqualTo(160), reason: card.id);

        expect(english.contains('\u201C'), isTrue,
            reason: '${card.id} is missing an opening curly quote');
        expect(english.contains('\u201D'), isTrue,
            reason: '${card.id} is missing a closing curly quote');
        expect(filipino.contains('\u201C'), isTrue,
            reason: '${card.id} fil is missing an opening curly quote');
        expect(filipino.contains('\u201D'), isTrue,
            reason: '${card.id} fil is missing a closing curly quote');

        cards.add(card);
      }
    }

    expect(cards.length, greaterThanOrEqualTo(10));

    final stereotypes =
        cards.where((card) => card.kind == SituationKind.stereotype);
    final respectful =
        cards.where((card) => card.kind == SituationKind.respectful);

    expect(stereotypes.length, greaterThanOrEqualTo(5));
    expect(respectful.length, greaterThanOrEqualTo(5));

    for (final target in Situation.targets) {
      expect(
        cards.any((card) => card.target == target),
        isTrue,
        reason: 'no cards for target "$target"',
      );
    }

    for (final category in Situation.categories) {
      expect(
        cards.any((card) => card.category == category),
        isTrue,
        reason: 'no cards for category "$category"',
      );
    }
  });
}
