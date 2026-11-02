// Smoke test for the app-wide settings introduced in lib/app_settings.dart.
//
// It checks that changing the language and muting the music on the main menu
// is reflected on the game screen, which previously kept its own copies.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gayme/app_settings.dart';
import 'package:gayme/main.dart';

void main() {
  test('AppSettings keeps the last non-zero volume for toggling', () {
    final settings = AppSettings();

    settings.musicVolume = 0.4;
    settings.toggleMusic();

    expect(settings.musicVolume, 0);

    settings.toggleMusic();

    expect(settings.musicVolume, 0.4);
  });

  testWidgets('language and volume are shared with the game screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const StereotypicalApp());
    await tester.pump(const Duration(milliseconds: 500));

    // Open the settings dialog from the main menu.
    await tester.tap(find.byIcon(Icons.settings_rounded));
    await tester.pump(const Duration(milliseconds: 400));

    // Mute the music and switch to Filipino.
    await tester.tap(find.byIcon(Icons.music_note));
    await tester.pump();
    await tester.tap(find.text('Filipino'));
    await tester.pump();

    expect(find.text('TAPOS NA'), findsOneWidget);

    // Close the dialog; the menu button should be localized already.
    await tester.tap(find.text('TAPOS NA'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('SIMULAN ANG LARO'), findsOneWidget);

    // Start the game and check that the shared settings came along.
    await tester.tap(find.text('SIMULAN ANG LARO'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Mag-swipe pakaliwa o pakanan'), findsOneWidget);
    expect(find.text('PAKALIWA'), findsOneWidget);

    // Open the in-game settings and confirm the muted music carried over.
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pump(const Duration(milliseconds: 400));

    final sliders = tester.widgetList<Slider>(find.byType(Slider)).toList();

    expect(sliders, hasLength(2));
    expect(sliders.first.value, 0);
  });
}
