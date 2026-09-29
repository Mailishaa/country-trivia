import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:country_trivia/services/country_service.dart';
import 'package:country_trivia/services/storage_service.dart';
import 'package:country_trivia/viewmodels/game_view_model.dart';
import 'package:country_trivia/viewmodels/quiz_view_model.dart';
import 'package:country_trivia/views/quiz_page.dart';
import 'package:country_trivia/views/result_page.dart';

void main() {
  group('ResultPage', () {
    late GameViewModel gameVM;
    late QuizViewModel quizVM;
    late StorageService storageService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storageService = StorageService(prefs: prefs);

      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode([
            {'name': {'common': 'United States'}, 'cca2': 'US'},
            {'name': {'common': 'France'}, 'cca2': 'FR'},
            {'name': {'common': 'Germany'}, 'cca2': 'DE'},
            {'name': {'common': 'Japan'}, 'cca2': 'JP'},
          ]),
          200,
        );
      });

      gameVM = GameViewModel(
        countryService: CountryService(client: mockClient),
        storageService: storageService,
      );
      quizVM = QuizViewModel(gameViewModel: gameVM);

      await gameVM.initialize();
    });

    Widget createTestApp({Widget home = const ResultPage()}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: gameVM),
          ChangeNotifierProvider.value(value: quizVM),
        ],
        child: MaterialApp(home: home),
      );
    }

    testWidgets('shows congratulations and final score', (tester) async {
      // Solve every country so the game-complete state is realistic.
      for (final c in gameVM.allCountries) {
        await gameVM.markSolved(c.isoCode, 10);
      }

      await tester.pumpWidget(createTestApp());
      await tester.pump();

      expect(find.text('Game Complete!'), findsOneWidget);
      expect(find.text('Congratulations!'), findsOneWidget);
      expect(find.text('Final Score: 40'), findsOneWidget);
      expect(find.text('You solved all 4 countries!'), findsOneWidget);
    });

    testWidgets('renders a Play Again button', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      expect(find.text('Play Again'), findsOneWidget);
      expect(find.byIcon(Icons.replay), findsOneWidget);
    });

    testWidgets('tapping Play Again resets score and solved flags',
        (tester) async {
      await gameVM.markSolved('US', 10);
      await gameVM.markSolved('FR', 8);

      await tester.pumpWidget(createTestApp());
      await tester.pump();

      await tester.tap(find.text('Play Again'));
      // QuizPage mounts FlagImage's perpetual spinner, so pumpAndSettle
      // would never return. Use bounded pumps instead.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(gameVM.totalScore, 0);
      expect(gameVM.solvedIsoCodes, isEmpty);
    });

    testWidgets('reset is persisted to storage', (tester) async {
      await gameVM.markSolved('US', 10);

      await tester.pumpWidget(createTestApp());
      await tester.pump();

      await tester.tap(find.text('Play Again'));
      // QuizPage mounts FlagImage's perpetual spinner, so pumpAndSettle
      // would never return. Use bounded pumps instead.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final persisted = storageService.loadGameState();
      expect(persisted.totalScore, 0);
      expect(persisted.solvedIsoCodes, isEmpty);
    });

    testWidgets('navigates back to the quiz after reset', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      await tester.tap(find.text('Play Again'));
      // The route transition runs, then QuizPage mounts FlagImage's
      // perpetual spinner, so pumpAndSettle would never return. Pump past
      // the transition duration, then do a couple of bounded frames.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(QuizPage), findsOneWidget);
      expect(find.byType(ResultPage), findsNothing);
    });

    testWidgets('a new question is available after reset', (tester) async {
      for (final c in gameVM.allCountries) {
        await gameVM.markSolved(c.isoCode, 10);
      }
      expect(gameVM.isGameComplete, isTrue);

      await tester.pumpWidget(createTestApp());
      await tester.pump();

      await tester.tap(find.text('Play Again'));
      // QuizPage mounts FlagImage's perpetual spinner, so pumpAndSettle
      // would never return. Use bounded pumps instead.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(gameVM.isGameComplete, isFalse);
      expect(gameVM.availableCountries.length, 4);
      expect(quizVM.currentQuestion, isNotNull);
    });
  });
}
