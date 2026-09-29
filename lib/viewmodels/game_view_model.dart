import 'package:flutter/foundation.dart';

import '../models/country.dart';
import '../models/game_state.dart';
import '../services/country_service.dart';
import '../services/storage_service.dart';

/// Manages the overall game lifecycle: score, solved flags, and reset logic.
class GameViewModel extends ChangeNotifier {
  final CountryService _countryService;
  final StorageService _storageService;

  GameState _state = const GameState();
  List<Country> _allCountries = [];
  bool _isLoading = true;

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

  /// Countries that have NOT been solved yet.
  List<Country> get availableCountries => _allCountries
      .where((c) => !_state.solvedIsoCodes.contains(c.isoCode))
      .toList();

  /// Whether all countries have been solved (game complete).
  bool get isGameComplete => availableCountries.isEmpty;

  /// Initialize: load persisted state and fetch countries.
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _state = _storageService.loadGameState();
      _allCountries = await _countryService.fetchAllCountries();
    } catch (e) {
      // On error, start fresh
      _state = const GameState();
      _allCountries = [];
    }

    _isLoading = false;
    notifyListeners();
  }

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
