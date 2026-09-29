import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_state.dart';
import '../utils/constants.dart';

/// Service for persisting and retrieving game state using SharedPreferences.
class StorageService {
  final SharedPreferences _prefs;

  StorageService({required SharedPreferences prefs}) : _prefs = prefs;

  /// Initializes the service by obtaining SharedPreferences instance.
  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs: prefs);
  }

  /// Loads the persisted game state.
  ///
  /// Returns default [GameState] if no data exists or data is corrupted.
  GameState loadGameState() {
    try {
      final jsonString = _prefs.getString(kGameStateKey);
      if (jsonString == null) {
        return const GameState();
      }
      final decoded = json.decode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        return const GameState();
      }
      return GameState.fromJson(decoded);
    } catch (_) {
      // Corrupted data — return defaults
      return const GameState();
    }
  }

  /// Saves the game state to SharedPreferences.
  Future<void> saveGameState(GameState state) async {
    final jsonString = json.encode(state.toJson());
    await _prefs.setString(kGameStateKey, jsonString);
  }

  /// Clears all persisted game data.
  Future<void> clear() async {
    await _prefs.remove(kGameStateKey);
  }
}
