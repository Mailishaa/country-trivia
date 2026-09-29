import 'package:flutter_test/flutter_test.dart';
import 'package:country_trivia/models/game_state.dart';
import 'package:country_trivia/services/country_service.dart';
import 'package:country_trivia/services/storage_service.dart';
import 'package:country_trivia/viewmodels/game_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

void main() {
  group('GameViewModel', () {
    late GameViewModel viewModel;
    late StorageService storageService;
    late CountryService countryService;

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
            {'name': {'common': 'Brazil'}, 'cca2': 'BR'},
          ]),
          200,
        );
      });
      countryService = CountryService(client: mockClient);

      viewModel = GameViewModel(
        countryService: countryService,
        storageService: storageService,
      );
    });

    group('initialize', () {
      test('loads state and fetches countries', () async {
        await viewModel.initialize();

        expect(viewModel.isLoading, isFalse);
        expect(viewModel.allCountries.length, 5);
        expect(viewModel.totalScore, 0);
        expect(viewModel.solvedIsoCodes, isEmpty);
      });

      test('loads persisted state', () async {
        await storageService.saveGameState(
          const GameState(totalScore: 42, solvedIsoCodes: ['US']),
        );

        await viewModel.initialize();

        expect(viewModel.totalScore, 42);
        expect(viewModel.solvedIsoCodes, ['US']);
      });

      test('handles API failure gracefully', () async {
        final failClient = MockClient((request) async {
          return http.Response('Error', 500);
        });
        final failService = CountryService(client: failClient);
        final failVM = GameViewModel(
          countryService: failService,
          storageService: storageService,
        );

        await failVM.initialize();

        expect(failVM.isLoading, isFalse);
        expect(failVM.allCountries, isEmpty);
      });

      test('records a load error and is not treated as game complete',
          () async {
        final failClient = MockClient((request) async {
          return http.Response('Error', 500);
        });
        final failVM = GameViewModel(
          countryService: CountryService(client: failClient),
          storageService: storageService,
        );

        await failVM.initialize();

        expect(failVM.loadError, isNotNull);
        expect(failVM.isGameComplete, isFalse);
      });

      test('treats an empty country list as an error, not a finished game',
          () async {
        final emptyClient = MockClient((request) async {
          return http.Response(json.encode([]), 200);
        });
        final emptyVM = GameViewModel(
          countryService: CountryService(client: emptyClient),
          storageService: storageService,
        );

        await emptyVM.initialize();

        expect(emptyVM.loadError, isNotNull);
        expect(emptyVM.isGameComplete, isFalse);
      });

      test('retryLoad clears the error after a successful fetch', () async {
        var fail = true;
        final flakyClient = MockClient((request) async {
          if (fail) return http.Response('Error', 500);
          return http.Response(
            json.encode([
              {'name': {'common': 'Kenya'}, 'cca2': 'KE'},
              {'name': {'common': 'Peru'}, 'cca2': 'PE'},
              {'name': {'common': 'Norway'}, 'cca2': 'NO'},
              {'name': {'common': 'Cuba'}, 'cca2': 'CU'},
            ]),
            200,
          );
        });
        final flakyVM = GameViewModel(
          countryService: CountryService(client: flakyClient),
          storageService: storageService,
        );

        await flakyVM.initialize();
        expect(flakyVM.loadError, isNotNull);

        fail = false;
        await flakyVM.retryLoad();

        expect(flakyVM.loadError, isNull);
        expect(flakyVM.allCountries.length, 4);
      });
    });

    group('markSolved', () {
      test('updates score and solved list', () async {
        await viewModel.initialize();

        await viewModel.markSolved('US', 10);

        expect(viewModel.totalScore, 10);
        expect(viewModel.solvedIsoCodes, ['US']);
      });

      test('accumulates score', () async {
        await viewModel.initialize();

        await viewModel.markSolved('US', 10);
        await viewModel.markSolved('FR', 8);

        expect(viewModel.totalScore, 18);
        expect(viewModel.solvedIsoCodes, ['US', 'FR']);
      });

      test('prevents duplicate solves', () async {
        await viewModel.initialize();

        await viewModel.markSolved('US', 10);
        await viewModel.markSolved('US', 10);

        expect(viewModel.totalScore, 10);
        expect(viewModel.solvedIsoCodes, ['US']);
      });

      test('persists state', () async {
        await viewModel.initialize();

        await viewModel.markSolved('US', 10);

        final persisted = storageService.loadGameState();
        expect(persisted.totalScore, 10);
        expect(persisted.solvedIsoCodes, ['US']);
      });
    });

    group('resetGame', () {
      test('clears score and solved list', () async {
        await viewModel.initialize();
        await viewModel.markSolved('US', 10);
        await viewModel.markSolved('FR', 8);

        await viewModel.resetGame();

        expect(viewModel.totalScore, 0);
        expect(viewModel.solvedIsoCodes, isEmpty);
      });

      test('persists reset state', () async {
        await viewModel.initialize();
        await viewModel.markSolved('US', 10);

        await viewModel.resetGame();

        final persisted = storageService.loadGameState();
        expect(persisted.totalScore, 0);
        expect(persisted.solvedIsoCodes, isEmpty);
      });
    });

    group('availableCountries', () {
      test('filters out solved countries', () async {
        await viewModel.initialize();
        await viewModel.markSolved('US', 10);

        final available = viewModel.availableCountries;

        expect(available.length, 4);
        expect(
          available.any((c) => c.isoCode == 'US'),
          isFalse,
        );
      });

      test('returns empty when all solved', () async {
        await viewModel.initialize();
        for (final c in viewModel.allCountries) {
          await viewModel.markSolved(c.isoCode, 10);
        }

        expect(viewModel.availableCountries, isEmpty);
      });
    });

    group('isGameComplete', () {
      test('false when countries remain', () async {
        await viewModel.initialize();

        expect(viewModel.isGameComplete, isFalse);
      });

      test('true when all solved', () async {
        await viewModel.initialize();
        for (final c in viewModel.allCountries) {
          await viewModel.markSolved(c.isoCode, 10);
        }

        expect(viewModel.isGameComplete, isTrue);
      });

      test('false when every country was solved then the game was reset',
          () async {
        await viewModel.initialize();
        for (final c in viewModel.allCountries) {
          await viewModel.markSolved(c.isoCode, 10);
        }
        expect(viewModel.isGameComplete, isTrue);

        await viewModel.resetGame();

        expect(viewModel.isGameComplete, isFalse);
      });
    });
  });
}
