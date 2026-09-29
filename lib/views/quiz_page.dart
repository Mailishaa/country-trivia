import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/game_view_model.dart';
import '../viewmodels/quiz_view_model.dart';
import 'result_page.dart';
import 'widgets/answer_button.dart';
import 'widgets/attempts_indicator.dart';
import 'widgets/flag_image.dart';
import 'widgets/score_board.dart';

/// Main gameplay screen displaying a flag and answer options.
class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameVM = context.read<GameViewModel>();
      final quizVM = context.read<QuizViewModel>();
      if (quizVM.currentQuestion == null && !gameVM.isGameComplete) {
        quizVM.nextQuestion();
      }
    });
  }

  Future<void> _onAnswerSelected(String countryName) async {
    final quizVM = context.read<QuizViewModel>();
    final gameVM = context.read<GameViewModel>();

    final isCorrect = await quizVM.submitAnswer(countryName);

    if (!mounted) return;

    if (isCorrect) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Correct! +${_getPoints(quizVM.attempts)} points'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      quizVM.advance();
    } else if (quizVM.isRevealed) {
      _showRevealDialog(quizVM);
    }

    if (gameVM.isGameComplete && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ResultPage()),
      );
    }
  }

  int _getPoints(int attempts) {
    const points = [10, 8, 5];
    return attempts >= 1 && attempts <= 3 ? points[attempts - 1] : 0;
  }

  void _showRevealDialog(QuizViewModel quizVM) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Out of attempts!'),
        content: Text(
          'The correct answer is: ${quizVM.currentQuestion!.correctCountry.name}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              quizVM.advance();
            },
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Country Trivia'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Consumer<GameViewModel>(
                builder: (context, gameVM, _) => ScoreBoard(
                  score: gameVM.totalScore,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Consumer2<GameViewModel, QuizViewModel>(
        builder: (context, gameVM, quizVM, _) {
          if (gameVM.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (gameVM.isGameComplete) {
            return const Center(child: CircularProgressIndicator());
          }

          final question = quizVM.currentQuestion;
          if (question == null) {
            return const Center(child: Text('No more questions!'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Flag image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FlagImage(
                    url: question.correctCountry.flagUrl,
                  ),
                ),
                const SizedBox(height: 24),

                // Attempts indicator
                AttemptsIndicator(attemptsUsed: quizVM.attempts),
                const SizedBox(height: 16),

                // Instruction text
                Text(
                  'Which country does this flag belong to?',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Answer options
                ...question.options.map((country) {
                  AnswerButtonState buttonState;

                  if (quizVM.isRevealed) {
                    if (country.isoCode == question.correctCountry.isoCode) {
                      buttonState = AnswerButtonState.revealed;
                    } else {
                      buttonState = AnswerButtonState.disabled;
                    }
                  } else if (quizVM.selectedAnswer == country.name) {
                    buttonState = AnswerButtonState.wrong;
                  } else {
                    buttonState = AnswerButtonState.defaultState;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AnswerButton(
                      text: country.name,
                      state: buttonState,
                      onTap: quizVM.isRevealed
                          ? null
                          : () => _onAnswerSelected(country.name),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
