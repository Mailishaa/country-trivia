import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:country_trivia/services/country_service.dart';
import 'package:country_trivia/services/storage_service.dart';
import 'package:country_trivia/viewmodels/game_view_model.dart';
import 'package:country_trivia/viewmodels/quiz_view_model.dart';
import 'package:country_trivia/views/quiz_page.dart';
import 'package:country_trivia/views/widgets/answer_button.dart';
import 'package:country_trivia/views/widgets/attempts_indicator.dart';
import 'package:country_trivia/views/widgets/flag_image.dart';
import 'package:country_trivia/views/widgets/score_board.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

void main() {
  group('QuizPage', () {
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
      quizVM.nextQuestion();
    });

    Widget createTestApp() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: gameVM),
          ChangeNotifierProvider.value(value: quizVM),
        ],
        child: const MaterialApp(home: QuizPage()),
      );
    }

    // The default 800x600 test surface is too short to hold the flag plus
    // four answer buttons, so taps on the lower buttons miss. Use a taller
    // surface and reset it after each test.
    setUp(() {
      final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views
          .first;
      view.physicalSize = const Size(1000, 2400);
      view.devicePixelRatio = 1.0;
    });

    tearDown(() {
      final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views
          .first;
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });

    // FlagImage shows an infinitely animating CircularProgressIndicator
    // placeholder, so pumpAndSettle would never return. Use fixed pumps.
    Future<void> pumpPage(WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('renders flag, options, and score', (tester) async {
      await pumpPage(tester);

      // Should have 4 answer buttons
      expect(find.byType(ElevatedButton), findsNWidgets(4));

      // Should show attempts indicator
      expect(find.byType(AttemptsIndicator), findsOneWidget);
    });

    testWidgets('shows score board and title', (tester) async {
      await pumpPage(tester);

      expect(find.text('Country Trivia'), findsOneWidget);
      expect(find.byType(ScoreBoard), findsOneWidget);
    });

    testWidgets('displays all four answer options', (tester) async {
      await pumpPage(tester);

      final question = quizVM.currentQuestion!;
      expect(question.options.length, 4);
      for (final option in question.options) {
        expect(find.text(option.name), findsOneWidget);
      }
    });

    testWidgets('displays the flag for the current question', (tester) async {
      await pumpPage(tester);

      final question = quizVM.currentQuestion!;
      expect(find.byType(FlagImage), findsOneWidget);
      final flag = tester.widget<FlagImage>(find.byType(FlagImage));
      expect(flag.url, question.correctCountry.flagUrl);
    });

    testWidgets('tapping a wrong answer marks it as wrong', (tester) async {
      await pumpPage(tester);

      final question = quizVM.currentQuestion!;
      final wrong = question.options
          .firstWhere((c) => c.name != question.correctCountry.name);

      await tester.tap(find.text(wrong.name));
      await tester.pump();

      expect(quizVM.attempts, 1);
      expect(quizVM.isCorrect, isFalse);
      final button = tester.widget<AnswerButton>(
        find.ancestor(
          of: find.text(wrong.name),
          matching: find.byType(AnswerButton),
        ),
      );
      expect(button.state, AnswerButtonState.wrong);
    });

    testWidgets('reveals the correct answer after 3 wrong attempts',
        (tester) async {
      await pumpPage(tester);

      final question = quizVM.currentQuestion!;
      final wrongOptions = question.options
          .where((c) => c.name != question.correctCountry.name)
          .toList();

      for (final wrong in wrongOptions) {
        await tester.tap(find.text(wrong.name));
        await tester.pump();
      }

      expect(quizVM.attempts, 3);
      expect(quizVM.isRevealed, isTrue);

      // Reveal dialog shows the correct answer
      expect(find.text('Out of attempts!'), findsOneWidget);
      expect(
        find.text('The correct answer is: ${question.correctCountry.name}'),
        findsOneWidget,
      );
    });

    testWidgets('tapping the correct answer awards points', (tester) async {
      await pumpPage(tester);

      final question = quizVM.currentQuestion!;
      await tester.tap(find.text(question.correctCountry.name));
      await tester.pump();

      expect(quizVM.isCorrect, isTrue);
      expect(gameVM.totalScore, 10);

      // Drain the 1s delay before the page auto-advances, and the
      // snackbar duration, so no timers leak past teardown.
      await tester.pump(const Duration(seconds: 2));
    });
  });
}
