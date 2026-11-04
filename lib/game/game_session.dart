import 'dart:math';

import '../content/situation.dart';

/// Which side of the screen the player swiped toward.
enum SwipeSide { left, right }

/// The result of answering one card.
class GameFeedback {
  const GameFeedback({
    required this.card,
    required this.chosen,
    required this.isCorrect,
  });

  final Situation card;
  final SwipeSide chosen;
  final bool isCorrect;
}

/// One playable round: builds a balanced deck, tracks answers and score.
///
/// This class is pure Dart on purpose so the game rules can be unit-tested
/// without pumping widgets.
class GameSession {
  GameSession({
    required List<Situation> cards,
    int roundSize = defaultRoundSize,
    Random? random,
  })  : roundSize = roundSize,
        _random = random ?? Random() {
    _deck = _buildDeck(
      cards.where((card) => card.active).toList(growable: false),
      roundSize,
      _random,
    );
  }

  static const int defaultRoundSize = 10;

  static const int pointsPerCorrect = 10;

  /// A deck never shows more than two cards of the same kind in a row.
  static const int maxKindRun = 2;

  final int roundSize;
  final Random _random;

  late final List<Situation> _deck;

  int _index = 0;
  int _correctCount = 0;

  GameFeedback? _pending;
  final List<GameFeedback> _history = [];

  List<Situation> get deck => List.unmodifiable(_deck);

  Situation? get current => _index < _deck.length ? _deck[_index] : null;

  int get total => _deck.length;

  /// 1-based position of the card currently on screen.
  int get currentNumber => current == null ? _deck.length : _index + 1;

  int get answeredCount => _history.length;

  int get correctCount => _correctCount;

  int get score => _correctCount * pointsPerCorrect;

  double get accuracy {
    if (_history.isEmpty) return 0;
    return _correctCount / _history.length;
  }

  /// True after [answer] until [next] is called.
  bool get awaitingNext => _pending != null;

  GameFeedback? get pendingFeedback => _pending;

  bool get isFinished => _index >= _deck.length && _pending == null;

  List<GameFeedback> get history => List.unmodifiable(_history);

  List<GameFeedback> get missed => _history
      .where((feedback) => !feedback.isCorrect)
      .toList(growable: false);

  static SwipeSide expectedSide(Situation card) {
    return card.kind == SituationKind.stereotype
        ? SwipeSide.left
        : SwipeSide.right;
  }

  /// Records the player's answer and returns the feedback for it.
  GameFeedback answer(SwipeSide side) {
    final card = current;

    if (card == null) {
      throw StateError('There is no card to answer.');
    }

    if (_pending != null) {
      throw StateError('Call next() before answering again.');
    }

    final feedback = GameFeedback(
      card: card,
      chosen: side,
      isCorrect: expectedSide(card) == side,
    );

    _pending = feedback;
    _history.add(feedback);

    if (feedback.isCorrect) {
      _correctCount++;
    }

    return feedback;
  }

  /// Moves to the next card after the feedback has been shown.
  void next() {
    if (_pending == null) return;

    _pending = null;
    _index++;
  }

  static List<Situation> _buildDeck(
    List<Situation> cards,
    int roundSize,
    Random random,
  ) {
    if (cards.isEmpty || roundSize <= 0) return <Situation>[];

    final take = min(roundSize, cards.length);
    final half = take ~/ 2;

    final stereotypes = cards
        .where((card) => card.kind == SituationKind.stereotype)
        .toList()
      ..shuffle(random);
    final respectful = cards
        .where((card) => card.kind == SituationKind.respectful)
        .toList()
      ..shuffle(random);

    final stereotypeTake = min(half, stereotypes.length);
    final respectfulTake = min(half, respectful.length);

    final chosen = <Situation>[
      ...stereotypes.take(stereotypeTake),
      ...respectful.take(respectfulTake),
    ];

    if (chosen.length < take) {
      final leftovers = <Situation>[
        ...stereotypes.skip(stereotypeTake),
        ...respectful.skip(respectfulTake),
      ]..shuffle(random);

      chosen.addAll(leftovers.take(take - chosen.length));
    }

    return _arrange(chosen, random);
  }

  /// Shuffles the chosen cards while avoiding runs longer than
  /// [maxKindRun], which players could otherwise guess.
  static List<Situation> _arrange(
    List<Situation> cards,
    Random random,
  ) {
    if (cards.length < 3) return [...cards]..shuffle(random);

    final stereotypeCount = cards
        .where((card) => card.kind == SituationKind.stereotype)
        .length;
    final respectfulCount = cards.length - stereotypeCount;
    final common = max(stereotypeCount, respectfulCount);
    final scarce = min(stereotypeCount, respectfulCount);

    // Even the best possible ordering repeats the common kind at least
    // ceil(common / (scarce + 1)) times in a row. When that already breaks
    // the rule (for example a deck with only one card of a kind), retrying
    // cannot help, so settle for a single best-effort shuffle.
    if ((common / (scarce + 1)).ceil() > maxKindRun) {
      return _greedyArrange([...cards]..shuffle(random), random);
    }

    List<Situation>? best;
    var bestRun = 1 << 30;

    // A greedy pass can still trap itself by leaving only the blocked kind
    // for the last slot, so retry until a valid arrangement shows up.
    for (var attempt = 0; attempt < 200; attempt++) {
      final arranged = _greedyArrange([...cards]..shuffle(random), random);
      final run = _longestRun(arranged);

      if (run <= maxKindRun) return arranged;

      if (run < bestRun) {
        bestRun = run;
        best = arranged;
      }
    }

    return best!;
  }

  static List<Situation> _greedyArrange(
    List<Situation> remaining,
    Random random,
  ) {
    final arranged = <Situation>[];

    while (remaining.isNotEmpty) {
      final hasRun = arranged.length >= maxKindRun &&
          arranged[arranged.length - 1].kind ==
              arranged[arranged.length - 2].kind;
      final blockedKind = hasRun ? arranged.last.kind : null;

      final candidates = <int>[];

      for (var i = 0; i < remaining.length; i++) {
        if (blockedKind == null || remaining[i].kind != blockedKind) {
          candidates.add(i);
        }
      }

      final pool = candidates.isEmpty
          ? List<int>.generate(remaining.length, (index) => index)
          : candidates;

      arranged.add(remaining.removeAt(pool[random.nextInt(pool.length)]));
    }

    return arranged;
  }

  static int _longestRun(List<Situation> cards) {
    var longest = 0;
    var run = 0;
    SituationKind? previous;

    for (final card in cards) {
      run = card.kind == previous ? run + 1 : 1;

      if (run > longest) longest = run;

      previous = card.kind;
    }

    return longest;
  }
}
