import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:country_trivia/models/game_state.dart';
import 'package:country_trivia/services/storage_service.dart';

void main() {
  group('StorageService', () {
    late SharedPreferences prefs;
    late StorageService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      service = StorageService(prefs: prefs);
    });

    group('loadGameState', () {
      test('returns default when key missing', () {
        final state = service.loadGameState();

        expect(state.totalScore, 0);
        expect(state.solvedIsoCodes, isEmpty);
      });

      test('returns saved state when key exists', () async {
        await prefs.setString(
          'game_state',
          '{"totalScore":42,"solvedIsoCodes":["US","FR"]}',
        );

        final state = service.loadGameState();

        expect(state.totalScore, 42);
        expect(state.solvedIsoCodes, ['US', 'FR']);
      });

      test('returns default on corrupted JSON', () async {
        await prefs.setString('game_state', 'not valid json{');

        final state = service.loadGameState();

        expect(state.totalScore, 0);
        expect(state.solvedIsoCodes, isEmpty);
      });

      test('returns default on wrong type in JSON', () async {
        await prefs.setString(
          'game_state',
          '{"totalScore":"not_a_number","solvedIsoCodes":null}',
        );

        final state = service.loadGameState();

        expect(state.totalScore, 0);
        expect(state.solvedIsoCodes, isEmpty);
      });

      test('returns default when stored JSON is not an object', () async {
        await prefs.setString('game_state', '[1, 2, 3]');

        final state = service.loadGameState();

        expect(state.totalScore, 0);
        expect(state.solvedIsoCodes, isEmpty);
      });
    });

    group('create', () {
      test('builds a service from SharedPreferences', () async {
        final created = await StorageService.create();

        expect(created.loadGameState().totalScore, 0);
      });

      test('created service can persist and reload state', () async {
        final created = await StorageService.create();

        await created.saveGameState(
          const GameState(totalScore: 7, solvedIsoCodes: ['IT']),
        );

        expect(created.loadGameState().totalScore, 7);
        expect(created.loadGameState().solvedIsoCodes, ['IT']);
      });
    });

    group('saveGameState', () {
      test('persists state correctly', () async {
        const state = GameState(
          totalScore: 15,
          solvedIsoCodes: ['DE', 'JP'],
        );

        await service.saveGameState(state);

        final loaded = service.loadGameState();
        expect(loaded.totalScore, 15);
        expect(loaded.solvedIsoCodes, ['DE', 'JP']);
      });

      test('overwrites existing data', () async {
        const state1 = GameState(totalScore: 10, solvedIsoCodes: ['US']);
        await service.saveGameState(state1);

        const state2 = GameState(totalScore: 20, solvedIsoCodes: ['FR']);
        await service.saveGameState(state2);

        final loaded = service.loadGameState();
        expect(loaded.totalScore, 20);
        expect(loaded.solvedIsoCodes, ['FR']);
      });

      test('round-trip preserves all data', () async {
        const original = GameState(
          totalScore: 100,
          solvedIsoCodes: ['US', 'FR', 'DE', 'JP', 'BR'],
        );

        await service.saveGameState(original);
        final loaded = service.loadGameState();

        expect(loaded.totalScore, original.totalScore);
        expect(loaded.solvedIsoCodes, original.solvedIsoCodes);
      });
    });

    group('clear', () {
      test('removes saved data', () async {
        const state = GameState(totalScore: 50, solvedIsoCodes: ['US']);
        await service.saveGameState(state);

        await service.clear();

        final loaded = service.loadGameState();
        expect(loaded.totalScore, 0);
        expect(loaded.solvedIsoCodes, isEmpty);
      });
    });
  });
}
