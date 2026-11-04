import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gayme/app_settings.dart';
import 'package:gayme/content/situation.dart';
import 'package:gayme/content/situation_repository.dart';
import 'package:gayme/game_screen.dart';

class _FakeRepository extends SituationRepository {
  _FakeRepository(this.cards);

  final List<Situation> cards;

  @override
  Future<List<Situation>> loadCards() async => cards;
}

const _stereotypeCard = Situation(
  id: 'stereotype-test',
  kind: SituationKind.stereotype,
  target: 'women',
  category: 'home',
  difficulty: 1,
  active: true,
  text: {
    'en': '“A woman’s place is in the kitchen.”',
    'fil': '“Ang lugar ng babae ay sa kusina.”',
  },
  explanation: {
    'en': 'This assumes women should only do housework.',
    'fil': 'Ipinapalagay nitong housework lang ang dapat gawin ng babae.',
  },
);

const _respectfulCard = Situation(
  id: 'respectful-test',
  kind: SituationKind.respectful,
  target: 'women',
  category: 'workplace',
  difficulty: 1,
  active: true,
  text: {
    'en': '“She earned the promotion through her work.”',
    'fil': '“Nakuha niya ang promotion dahil sa galing niya.”',
  },
  explanation: {
    'en': 'It credits her effort instead of her gender.',
    'fil': 'Kinikilala nito ang pagsisikap niya, hindi ang kasarian.',
  },
);

String _english(Situation card) => card.text['en']!;

Future<void> _swipe(
  WidgetTester tester,
  String text, {
  required bool left,
}) async {
  await tester.drag(
    find.text(text),
    Offset(left ? -300 : 300, 0),
  );
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

void main() {
  testWidgets('swipe, feedback, next card, and results', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cards = [_stereotypeCard, _respectfulCard];

    await tester.pumpWidget(
      SettingsScope(
        settings: AppSettings(),
        child: MaterialApp(
          home: GameScreen(repository: _FakeRepository(cards)),
        ),
      ),
    );

    // Let the asynchronous repository load resolve and the first card build.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    final firstIsStereotype =
        find.text(_english(_stereotypeCard)).evaluate().isNotEmpty;
    final first = firstIsStereotype ? _stereotypeCard : _respectfulCard;
    final second = firstIsStereotype ? _respectfulCard : _stereotypeCard;

    // Answer the first card correctly.
    await _swipe(
      tester,
      _english(first),
      left: first.kind == SituationKind.stereotype,
    );

    expect(find.text('EXACTLY!'), findsOneWidget);
    expect(find.text(_english(first)), findsNothing);

    await tester.tap(find.text('NEXT'));
    await tester.pump();

    expect(find.text(_english(second)), findsOneWidget);

    // Answer the second card incorrectly to populate the review list.
    await _swipe(
      tester,
      _english(second),
      left: second.kind == SituationKind.respectful,
    );

    expect(find.text('NOT QUITE.'), findsOneWidget);

    await tester.tap(find.text('SEE RESULTS'));
    await tester.pumpAndSettle();

    expect(find.text('RESULTS'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('50% CORRECT'), findsOneWidget);
    expect(find.text('CARDS TO REVIEW'), findsOneWidget);
    expect(find.text(_english(second)), findsOneWidget);
  });

  testWidgets('Filipino round fits a narrow phone', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final settings = AppSettings()..language = AppSettings.filipino;
    final cards = [_stereotypeCard, _respectfulCard];

    await tester.pumpWidget(
      SettingsScope(
        settings: settings,
        child: MaterialApp(
          home: GameScreen(repository: _FakeRepository(cards)),
        ),
      ),
    );

    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(tester.takeException(), isNull);

    final firstIsStereotype =
        find.text(_stereotypeCard.text['fil']!).evaluate().isNotEmpty;
    final first = firstIsStereotype ? _stereotypeCard : _respectfulCard;
    final second = firstIsStereotype ? _respectfulCard : _stereotypeCard;

    await _swipe(
      tester,
      first.text['fil']!,
      left: first.kind == SituationKind.stereotype,
    );

    expect(find.text('TAMA!'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('SUSUNOD'));
    await tester.pump();

    await _swipe(
      tester,
      second.text['fil']!,
      left: second.kind == SituationKind.respectful,
    );

    expect(find.text('HINDI TAMA.'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('TINGNAN ANG RESULTA'));
    await tester.pumpAndSettle();

    expect(find.text('RESULTA'), findsOneWidget);
    expect(find.text('MGA CARD NA BALIKAN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
