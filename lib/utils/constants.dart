/// Application-wide constants for the Country Trivia app.
library;

/// Base URL for the REST Countries API.
const String kCountriesApiUrl = 'https://restcountries.com/v3.1/all';

/// Base URL pattern for flag images from flagcdn.com.
/// Use [String.replaceAll] with the lowercase ISO 3166-1 alpha-2 code.
/// Example: 'https://flagcdn.com/w320/{iso}'.replaceAll('{iso}', 'us')
const String kFlagUrlPattern = 'https://flagcdn.com/w320/{iso}.png';

/// Points awarded per attempt (1-indexed).
/// - 1st attempt correct: 10 points
/// - 2nd attempt correct: 8 points
/// - 3rd attempt correct: 5 points
/// - All attempts exhausted: 0 points
const List<int> kPointsTable = [10, 8, 5];

/// Maximum number of attempts per question.
const int kMaxAttempts = 3;

/// SharedPreferences key for persisting game state.
const String kGameStateKey = 'game_state';

/// Flag cache configuration.
const String kFlagCacheKey = 'flag_cache';
const Duration kFlagCacheStalePeriod = Duration(days: 30);
const int kFlagCacheMaxObjects = 500;

/// Default flag image dimensions (matches w320 CDN size).
const double kFlagWidth = 320;
const double kFlagHeight = 200;
