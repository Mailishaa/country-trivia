import 'package:flutter_test/flutter_test.dart';
import 'package:country_trivia/models/game_state.dart';

void main() {
  group('GameState', () {
    group('default constructor', () {
      test('has zero score', () {
        const state = GameState();

        expect(state.totalScore, 0);
      });

      test('has empty solved list', () {
        const state = GameState();

        expect(state.solvedIsoCodes, isEmpty);
      });
    });

    group('copyWith', () {
      test('updates totalScore', () {
        const state = GameState();
        final updated = state.copyWith(totalScore: 10);

        expect(updated.totalScore, 10);
        expect(updated.solvedIsoCodes, isEmpty);
      });

      test('updates solvedIsoCodes', () {
        const state = GameState();
        final updated = state.copyWith(solvedIsoCodes: ['US', 'FR']);

        expect(updated.totalScore, 0);
        expect(updated.solvedIsoCodes, ['US', 'FR']);
      });

      test('updates both fields', () {
        const state = GameState();
        final updated = state.copyWith(
          totalScore: 15,
          solvedIsoCodes: ['DE'],
        );

        expect(updated.totalScore, 15);
        expect(updated.solvedIsoCodes, ['DE']);
      });

      test('preserves original when no args', () {
        const state = GameState(totalScore: 5, solvedIsoCodes: ['JP']);
        final updated = state.copyWith();

        expect(updated.totalScore, 5);
        expect(updated.solvedIsoCodes, ['JP']);
      });
    });

    group('toJson / fromJson', () {
      test('round-trips correctly', () {
        const state = GameState(
          totalScore: 42,
          solvedIsoCodes: ['US', 'FR', 'DE'],
        );

        final json = state.toJson();
        final restored = GameState.fromJson(json);

        expect(restored.totalScore, 42);
        expect(restored.solvedIsoCodes, ['US', 'FR', 'DE']);
      });

      test('handles empty state', () {
        const state = GameState();

        final json = state.toJson();
        final restored = GameState.fromJson(json);

        expect(restored.totalScore, 0);
        expect(restored.solvedIsoCodes, isEmpty);
      });

      test('handles missing fields in JSON', () {
        final json = <String, dynamic>{};

        final state = GameState.fromJson(json);

        expect(state.totalScore, 0);
        expect(state.solvedIsoCodes, isEmpty);
      });

      test('handles null values in JSON', () {
        final json = {
          'totalScore': null,
          'solvedIsoCodes': null,
        };

        final state = GameState.fromJson(json);

        expect(state.totalScore, 0);
        expect(state.solvedIsoCodes, isEmpty);
      });
    });

    group('equality', () {
      test('same values are equal', () {
        const a = GameState(totalScore: 10, solvedIsoCodes: ['US']);
        const b = GameState(totalScore: 10, solvedIsoCodes: ['US']);

        expect(a, equals(b));
      });

      test('different score not equal', () {
        const a = GameState(totalScore: 10, solvedIsoCodes: ['US']);
        const b = GameState(totalScore: 20, solvedIsoCodes: ['US']);

        expect(a, isNot(equals(b)));
      });

      test('different solved list not equal', () {
        const a = GameState(totalScore: 10, solvedIsoCodes: ['US']);
        const b = GameState(totalScore: 10, solvedIsoCodes: ['FR']);

        expect(a, isNot(equals(b)));
      });
    });
  });
}
