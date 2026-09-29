import 'package:flutter_test/flutter_test.dart';
import 'package:country_trivia/services/country_service.dart';
import 'package:country_trivia/services/storage_service.dart';
import 'package:country_trivia/viewmodels/game_view_model.dart';
import 'package:country_trivia/viewmodels/quiz_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

void main() {
  group('QuizViewModel', () {
    late GameViewModel gameVM;
    late QuizViewModel quizVM;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storageService = StorageService(prefs: prefs);

      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode([
            {'name': {'common': 'United States'}, 'cca2': 'US'},
            {'name': {'common': 'France'}, 'cca2': 'FR'},
            {'name': {'common': 'Germany'}, 'cca2': 'DE'},
            {'name': {'common': 'Japan'}, 'cca2': 'JP'},
            {'name': {'common': 'Brazil'}, 'cca2': 'BR'},
          ]),
          200,
        );
      });
      final countryService = CountryService(client: mockClient);

      gameVM = GameViewModel(
        countryService: countryService,
        storageService: storageService,
      );
      quizVM = QuizViewModel(gameViewModel: gameVM);

      await gameVM.initialize();
    });

    group('nextQuestion', () {
      test('generates a question', () {
        quizVM.nextQuestion();

        expect(quizVM.currentQuestion, isNotNull);
        expect(quizVM.currentQuestion!.options.length, 4);
      });

      test('resets attempts and selection', () {
        quizVM.nextQuestion();

        // Simulate some attempts
        quizVM.submitAnswer('Wrong');
        quizVM.submitAnswer('Also Wrong');

        quizVM.nextQuestion();

        expect(quizVM.attempts, 0);
        expect(quizVM.selectedAnswer, isNull);
        expect(quizVM.isRevealed, isFalse);
      });

      test('sets question to null when pool empty', () async {
        // Solve all countries
        for (final c in gameVM.allCountries) {
          await gameVM.markSolved(c.isoCode, 10);
        }

        quizVM.nextQuestion();

        expect(quizVM.currentQuestion, isNull);
      });
    });

    group('submitAnswer', () {
      test('returns true on correct answer', () async {
        quizVM.nextQuestion();
        final correctName = quizVM.currentQuestion!.correctCountry.name;

        final result = await quizVM.submitAnswer(correctName);

        expect(result, isTrue);
        expect(quizVM.isCorrect, isTrue);
      });

      test('returns false on wrong answer', () async {
        quizVM.nextQuestion();
        final correctName = quizVM.currentQuestion!.correctCountry.name;
        final wrongName = quizVM.currentQuestion!.options
            .firstWhere((c) => c.name != correctName)
            .name;

        final result = await quizVM.submitAnswer(wrongName);

        expect(result, isFalse);
        expect(quizVM.isCorrect, isFalse);
      });

      test('increments attempts on wrong answer', () async {
        quizVM.nextQuestion();
        final correctName = quizVM.currentQuestion!.correctCountry.name;
        final wrongName = quizVM.currentQuestion!.options
            .firstWhere((c) => c.name != correctName)
            .name;

        await quizVM.submitAnswer(wrongName);

        expect(quizVM.attempts, 1);
      });

      test('reveals after 3 wrong attempts', () async {
        quizVM.nextQuestion();
        final correctName = quizVM.currentQuestion!.correctCountry.name;
        final wrongNames = quizVM.currentQuestion!.options
            .where((c) => c.name != correctName)
            .map((c) => c.name)
            .toList();

        await quizVM.submitAnswer(wrongNames[0]);
        await quizVM.submitAnswer(wrongNames[1]);
        await quizVM.submitAnswer(wrongNames[2]);

        expect(quizVM.isRevealed, isTrue);
        expect(quizVM.attempts, 3);
      });

      test('no submission after reveal', () async {
        quizVM.nextQuestion();
        final correctName = quizVM.currentQuestion!.correctCountry.name;
        final wrongNames = quizVM.currentQuestion!.options
            .where((c) => c.name != correctName)
            .map((c) => c.name)
            .toList();

        await quizVM.submitAnswer(wrongNames[0]);
        await quizVM.submitAnswer(wrongNames[1]);
        await quizVM.submitAnswer(wrongNames[2]);

        final result = await quizVM.submitAnswer(correctName);

        expect(result, isFalse);
      });

      test('awards 10 points on first attempt', () async {
        quizVM.nextQuestion();
        final correctName = quizVM.currentQuestion!.correctCountry.name;

        await quizVM.submitAnswer(correctName);

        expect(gameVM.totalScore, 10);
      });

      test('awards 8 points on second attempt', () async {
        quizVM.nextQuestion();
        final correctName = quizVM.currentQuestion!.correctCountry.name;
        final wrongName = quizVM.currentQuestion!.options
            .firstWhere((c) => c.name != correctName)
            .name;

        await quizVM.submitAnswer(wrongName);
        await quizVM.submitAnswer(correctName);

        expect(gameVM.totalScore, 8);
      });

      test('awards 5 points on third attempt', () async {
        quizVM.nextQuestion();
        final correctName = quizVM.currentQuestion!.correctCountry.name;
        final wrongNames = quizVM.currentQuestion!.options
            .where((c) => c.name != correctName)
            .map((c) => c.name)
            .toList();

        await quizVM.submitAnswer(wrongNames[0]);
        await quizVM.submitAnswer(wrongNames[1]);
        await quizVM.submitAnswer(correctName);

        expect(gameVM.totalScore, 5);
      });

      test('awards 0 points when all attempts exhausted', () async {
        quizVM.nextQuestion();
        final correctName = quizVM.currentQuestion!.correctCountry.name;
        final wrongNames = quizVM.currentQuestion!.options
            .where((c) => c.name != correctName)
            .map((c) => c.name)
            .toList();

        await quizVM.submitAnswer(wrongNames[0]);
        await quizVM.submitAnswer(wrongNames[1]);
        await quizVM.submitAnswer(wrongNames[2]);

        expect(gameVM.totalScore, 0);
      });
    });

    group('advance', () {
      test('calls nextQuestion', () {
        quizVM.nextQuestion();

        quizVM.advance();

        // Question should be different (or at least state reset)
        expect(quizVM.attempts, 0);
        expect(quizVM.isRevealed, isFalse);
      });
    });

    group('hasAttemptsLeft', () {
      test('true initially', () {
        quizVM.nextQuestion();

        expect(quizVM.hasAttemptsLeft, isTrue);
      });

      test('false after 3 attempts', () async {
        quizVM.nextQuestion();
        final correctName = quizVM.currentQuestion!.correctCountry.name;
        final wrongNames = quizVM.currentQuestion!.options
            .where((c) => c.name != correctName)
            .map((c) => c.name)
            .toList();

        await quizVM.submitAnswer(wrongNames[0]);
        await quizVM.submitAnswer(wrongNames[1]);
        await quizVM.submitAnswer(wrongNames[2]);

        expect(quizVM.hasAttemptsLeft, isFalse);
      });
    });
  });
}
