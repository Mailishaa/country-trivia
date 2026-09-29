import 'package:flutter/foundation.dart';

import '../models/country.dart';
import '../models/game_state.dart';
import '../services/country_service.dart';
import '../services/storage_service.dart';

export 'package:country_trivia/services/country_service.dart'
    show CountriesApiException;

/// Manages the overall game lifecycle: score, solved flags, and reset logic.
class GameViewModel extends ChangeNotifier {
  final CountryService _countryService;
  final StorageService _storageService;

  GameState _state = const GameState();
  List<Country> _allCountries = [];
  bool _isLoading = true;
  String? _loadError;

  GameViewModel({
    required CountryService countryService,
    required StorageService storageService,
  })  : _countryService = countryService,
        _storageService = storageService;

  GameState get state => _state;
  List<Country> get allCountries => _allCountries;
  bool get isLoading => _isLoading;
  int get totalScore => _state.totalScore;
  List<String> get solvedIsoCodes => _state.solvedIsoCodes;
  CountryService get countryService => _countryService;

  /// Message describing why the country list could not be loaded, or null.
  String? get loadError => _loadError;

  /// Countries that have NOT been solved yet.
  List<Country> get availableCountries => _allCountries
      .where((c) => !_state.solvedIsoCodes.contains(c.isoCode))
      .toList();

  /// Whether all countries have been solved (game complete).
  ///
  /// Requires a non-empty country list, so a failed load is never mistaken for
  /// a finished game.
  bool get isGameComplete =>
      _loadError == null && _allCountries.isNotEmpty && availableCountries.isEmpty;

  /// Initialize: load persisted state and fetch countries.
  Future<void> initialize() async {
    _isLoading = true;
    _loadError = null;
    notifyListeners();

    try {
      _state = _storageService.loadGameState();
      _allCountries = await _countryService.fetchAllCountries();
      if (_allCountries.isEmpty) {
        _loadError = 'The countries service returned no countries.';
      }
    } on CountriesApiException catch (e) {
      _loadError = e.message;
      _allCountries = [];
    } catch (e) {
      _loadError = 'Could not load countries: $e';
      _allCountries = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Retry loading the country list after a failure.
  Future<void> retryLoad() => initialize();

  /// Award points and mark a country as solved.
  Future<void> markSolved(String isoCode, int points) async {
    if (_state.solvedIsoCodes.contains(isoCode)) return;

    _state = GameState(
      totalScore: _state.totalScore + points,
      solvedIsoCodes: [..._state.solvedIsoCodes, isoCode],
    );
    await _storageService.saveGameState(_state);
    notifyListeners();
  }

  /// Reset the game: clear score and solved flags.
  Future<void> resetGame() async {
    _state = const GameState();
    await _storageService.saveGameState(_state);
    notifyListeners();
  }
}
