import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gayme/content/situation.dart';
import 'package:gayme/game/game_session.dart';

Situation card(String id, SituationKind kind) {
  return Situation(
    id: id,
    kind: kind,
    target: 'women',
    category: 'school',
    difficulty: 1,
    active: true,
    text: {'en': 'Card $id', 'fil': 'Card $id'},
    explanation: {'en': 'Because $id.', 'fil': 'Dahil $id.'},
  );
}

List<Situation> deck({
  int stereotypes = 12,
  int respectful = 12,
}) {
  return [
    for (var i = 0; i < stereotypes; i++)
      card('stereotype-$i', SituationKind.stereotype),
    for (var i = 0; i < respectful; i++)
      card('respectful-$i', SituationKind.respectful),
  ];
}

void main() {
  test('builds a balanced ten-card deck without repeats', () {
    final session = GameSession(cards: deck(), random: Random(7));

    expect(session.total, 10);
    expect(
      session.deck
          .where((card) => card.kind == SituationKind.stereotype)
          .length,
      5,
    );
    expect(
      session.deck
          .where((card) => card.kind == SituationKind.respectful)
          .length,
      5,
    );
    expect(session.deck.map((card) => card.id).toSet().length, 10);
  });

  test('never shows more than two cards of the same kind in a row', () {
    for (var seed = 0; seed < 50; seed++) {
      final session = GameSession(cards: deck(), random: Random(seed));
      var run = 1;

      for (var i = 1; i < session.deck.length; i++) {
        run = session.deck[i].kind == session.deck[i - 1].kind
            ? run + 1
            : 1;

        expect(
          run,
          lessThanOrEqualTo(GameSession.maxKindRun),
          reason: 'seed $seed has a run of $run at card $i',
        );
      }
    }
  });

  test('maps kinds to the expected side', () {
    expect(
      GameSession.expectedSide(
        card('stereotype-1', SituationKind.stereotype),
      ),
      SwipeSide.left,
    );
    expect(
      GameSession.expectedSide(
        card('respectful-1', SituationKind.respectful),
      ),
      SwipeSide.right,
    );
  });

  test('scores correct answers and advances with next()', () {
    final session = GameSession(
      cards: deck(),
      roundSize: 2,
      random: Random(1),
    );
    final first = session.current!;
    final feedback = session.answer(
      GameSession.expectedSide(first),
    );

    expect(feedback.isCorrect, isTrue);
    expect(session.correctCount, 1);
    expect(session.score, GameSession.pointsPerCorrect);
    expect(session.awaitingNext, isTrue);
    expect(session.answeredCount, 1);

    expect(
      () => session.answer(GameSession.expectedSide(first)),
      throwsStateError,
    );

    session.next();

    expect(session.awaitingNext, isFalse);
    expect(session.current, isNot(same(first)));
    expect(session.answeredCount, 1);
  });

  test('records wrong answers without adding points', () {
    final session = GameSession(
      cards: deck(),
      roundSize: 1,
      random: Random(3),
    );
    final expected = GameSession.expectedSide(session.current!);
    final wrong = expected == SwipeSide.left
        ? SwipeSide.right
        : SwipeSide.left;

    final feedback = session.answer(wrong);

    expect(feedback.isCorrect, isFalse);
    expect(session.correctCount, 0);
    expect(session.score, 0);
    expect(session.missed, hasLength(1));
  });

  test('finishes after the last card is answered and advanced', () {
    final session = GameSession(
      cards: deck(stereotypes: 1, respectful: 1),
      random: Random(1),
    );

    expect(session.total, 2);

    while (!session.isFinished) {
      session.answer(GameSession.expectedSide(session.current!));
      session.next();
    }

    expect(session.isFinished, isTrue);
    expect(session.correctCount, 2);
    expect(session.score, 2 * GameSession.pointsPerCorrect);
    expect(session.accuracy, 1);
  });

  test('caps the round at the number of available cards', () {
    final session = GameSession(
      cards: deck(stereotypes: 2, respectful: 3),
      random: Random(1),
    );

    expect(session.total, 5);
  });

  test('fills from the available kind when one side is scarce', () {
    final session = GameSession(
      cards: deck(stereotypes: 1, respectful: 12),
      random: Random(1),
    );

    expect(session.total, 10);
    expect(
      session.deck
          .where((card) => card.kind == SituationKind.stereotype)
          .length,
      1,
    );
  });
}
