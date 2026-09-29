/// Represents the persisted state of the game.
class GameState {
  /// Total accumulated score.
  final int totalScore;

  /// ISO codes of countries that have been solved.
  final List<String> solvedIsoCodes;

  const GameState({
    this.totalScore = 0,
    this.solvedIsoCodes = const [],
  });

  /// Creates a copy with optionally updated fields.
  GameState copyWith({
    int? totalScore,
    List<String>? solvedIsoCodes,
  }) {
    return GameState(
      totalScore: totalScore ?? this.totalScore,
      solvedIsoCodes: solvedIsoCodes ?? this.solvedIsoCodes,
    );
  }

  /// Converts to JSON for persistence.
  Map<String, dynamic> toJson() => {
        'totalScore': totalScore,
        'solvedIsoCodes': solvedIsoCodes,
      };

  /// Creates from JSON (SharedPreferences format).
  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      totalScore: json['totalScore'] as int? ?? 0,
      solvedIsoCodes: (json['solvedIsoCodes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameState &&
          runtimeType == other.runtimeType &&
          totalScore == other.totalScore &&
          _listEquals(solvedIsoCodes, other.solvedIsoCodes);

  @override
  int get hashCode => totalScore.hashCode ^ solvedIsoCodes.hashCode;

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() =>
      'GameState(totalScore: $totalScore, solved: ${solvedIsoCodes.length})';
}
