import 'country.dart';

/// Represents a trivia question with a correct answer and 4 options.
class Question {
  /// The correct country for this question.
  final Country correctCountry;

  /// List of 4 country options (including the correct one), shuffled.
  final List<Country> options;

  const Question({
    required this.correctCountry,
    required this.options,
  });

  /// Whether [country] is the correct answer.
  bool isCorrect(Country country) => country.isoCode == correctCountry.isoCode;

  /// Whether [countryName] matches the correct answer's name.
  bool isCorrectName(String countryName) =>
      countryName == correctCountry.name;

  @override
  String toString() =>
      'Question(correct: ${correctCountry.name}, options: ${options.map((c) => c.name).toList()})';
}
