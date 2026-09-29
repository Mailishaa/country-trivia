import 'package:flutter/foundation.dart';

import '../models/question.dart';
import '../utils/constants.dart';
import 'game_view_model.dart';

/// Manages the current question, attempts, and answer evaluation.
class QuizViewModel extends ChangeNotifier {
  final GameViewModel _gameViewModel;

  Question? _currentQuestion;
  int _attempts = 0;
  bool _isRevealed = false;
  String? _selectedAnswer;
  bool _isCorrect = false;

  QuizViewModel({required GameViewModel gameViewModel})
      : _gameViewModel = gameViewModel;

  Question? get currentQuestion => _currentQuestion;
  int get attempts => _attempts;
  bool get isRevealed => _isRevealed;
  String? get selectedAnswer => _selectedAnswer;
  bool get isCorrect => _isCorrect;
  bool get hasAttemptsLeft => _attempts < kMaxAttempts;

  /// Points awarded per attempt number (1-indexed).
  static const List<int> pointsTable = kPointsTable;

  /// Generate a new question from available countries.
  void nextQuestion() {
    final available = _gameViewModel.availableCountries;
    if (available.isEmpty) {
      _currentQuestion = null;
      notifyListeners();
      return;
    }

    _currentQuestion = _gameViewModel.countryService.generateQuestion(available);
    _attempts = 0;
    _isRevealed = false;
    _selectedAnswer = null;
    _isCorrect = false;
    notifyListeners();
  }

  /// Submit an answer. Returns true if correct.
  Future<bool> submitAnswer(String countryName) async {
    if (_isRevealed || _currentQuestion == null) return false;

    _selectedAnswer = countryName;
    _attempts++;

    if (_currentQuestion!.isCorrectName(countryName)) {
      _isCorrect = true;
      final points = pointsTable[_attempts - 1];
      await _gameViewModel.markSolved(
        _currentQuestion!.correctCountry.isoCode,
        points,
      );
      notifyListeners();
      return true;
    }

    if (_attempts >= kMaxAttempts) {
      _isRevealed = true;
    }

    notifyListeners();
    return false;
  }

  /// Move to the next question after a correct answer or reveal.
  void advance() {
    nextQuestion();
  }
}
