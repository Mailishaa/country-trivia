import 'package:flutter_test/flutter_test.dart';
import 'package:country_trivia/models/country.dart';
import 'package:country_trivia/models/question.dart';

void main() {
  group('Question', () {
    const correct = Country(name: 'United States', isoCode: 'US');
    const options = [
      Country(name: 'United States', isoCode: 'US'),
      Country(name: 'France', isoCode: 'FR'),
      Country(name: 'Germany', isoCode: 'DE'),
      Country(name: 'Japan', isoCode: 'JP'),
    ];

    const question = Question(correctCountry: correct, options: options);

    group('isCorrect', () {
      test('returns true for correct country', () {
        expect(question.isCorrect(correct), isTrue);
      });

      test('returns false for wrong country', () {
        const wrong = Country(name: 'France', isoCode: 'FR');
        expect(question.isCorrect(wrong), isFalse);
      });
    });

    group('isCorrectName', () {
      test('returns true for correct name', () {
        expect(question.isCorrectName('United States'), isTrue);
      });

      test('returns false for wrong name', () {
        expect(question.isCorrectName('France'), isFalse);
      });
    });

    group('properties', () {
      test('has 4 options', () {
        expect(question.options.length, 4);
      });

      test('options contains correct answer', () {
        expect(
          question.options.any((c) => c.isoCode == correct.isoCode),
          isTrue,
        );
      });
    });

    group('toString', () {
      test('includes correct name and all options', () {
        final result = question.toString();

        expect(result, contains('United States'));
        expect(result, contains('France'));
        expect(result, contains('Germany'));
        expect(result, contains('Japan'));
      });
    });
  });
}
