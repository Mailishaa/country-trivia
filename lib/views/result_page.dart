import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/game_view_model.dart';
import '../viewmodels/quiz_view_model.dart';
import 'quiz_page.dart';

/// Screen shown when all countries have been solved.
class ResultPage extends StatelessWidget {
  const ResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Complete!'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.emoji_events,
                size: 80,
                color: Colors.amber,
              ),
              const SizedBox(height: 24),
              Text(
                'Congratulations!',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Consumer<GameViewModel>(
                builder: (context, gameVM, _) => Text(
                  'Final Score: ${gameVM.totalScore}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Consumer<GameViewModel>(
                builder: (context, gameVM, _) => Text(
                  'You solved all ${gameVM.allCountries.length} countries!',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final gameVM = context.read<GameViewModel>();
                    final quizVM = context.read<QuizViewModel>();

                    await gameVM.resetGame();
                    quizVM.nextQuestion();

                    if (context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const QuizPage()),
                      );
                    }
                  },
                  icon: const Icon(Icons.replay),
                  label: const Text('Play Again'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
