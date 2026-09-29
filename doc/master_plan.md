# Country Trivia App — Master Plan

## 1. Overview

A Flutter mobile app that quizzes users on country flags. Each round displays a flag image and four country names. The user has up to three attempts to identify the correct country, with decreasing point rewards. The app persists both the user's score and the set of already-solved flags across sessions.

---

## 2. Requirements Summary

| # | Requirement | Details |
|---|-------------|---------|
| R1 | Flag display | Show a flag image from `https://flagcdn.com/w320/{iso}.png` |
| R2 | Four options | Display 4 country names per question |
| R3 | Scoring | 1st attempt correct = 10 pts, 2nd = 8 pts, 3rd = 5 pts, exhausted = 0 pts |
| R4 | Reveal on failure | After 3 wrong attempts, highlight the correct answer |
| R5 | No repeats | Solved flags are not shown again until all countries are exhausted |
| R6 | Reset | When all countries are solved, the game resets and starts over |
| R7 | Persistence | Score and solved flags survive app restarts |
| R8 | Architecture | MVVM with Provider for state management |
| R9 | Data source | Countries from REST Countries API (Postman doc) |

---

## 3. API Details

### 3.1 Countries API

- **Source:** `https://restcountries.com/v3.1/all` (documented in the Postman collection)
- **Fields used:** `name.common` (display name), `cca2` (ISO 3166-1 alpha-2 code for flag URL)
- **Response:** JSON array of country objects
- **Flag URL pattern:** `https://flagcdn.com/w320/{cca2_lowercase}.png`

### 3.2 Flag CDN

- **Base URL:** `https://flagcdn.com/w320/`
- **Example:** `https://flagcdn.com/w320/us.png` for the United States
- **Sizes available:** 160 (`w160`), 320 (`w320`), 640 (`w640`) — we use `w320`

---

## 4. Architecture — MVVM with Provider

```
┌─────────────────────────────────────────────────────┐
│                      UI Layer                        │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────┐ │
│  │  QuizPage    │  │  ScoreBoard  │  │ ResultPage│ │
│  │  (View)      │  │  (View)      │  │ (View)    │ │
│  └──────┬───────┘  └──────┬───────┘  └─────┬─────┘ │
│         │                 │                 │       │
│         └────────┬────────┴─────────────────┘       │
│                  │                                   │
│         ┌────────▼────────┐                         │
│         │  QuizViewModel  │  (ChangeNotifier)       │
│         │  GameViewModel  │                         │
│         └────────┬────────┘                         │
│                  │                                   │
│         ┌────────▼────────┐                         │
│         │  CountryService │  (Repository)           │
│         │  StorageService│                         │
│         └────────┬────────┘                         │
│                  │                                   │
│         ┌────────▼────────┐                         │
│         │  REST Countries │  (External API)         │
│         │  API            │                         │
│         └─────────────────┘                         │
└─────────────────────────────────────────────────────┘
```

### 4.1 Layers

| Layer | Responsibility | Key Classes |
|-------|---------------|-------------|
| **View** | Render UI, capture user input, display state | `QuizPage`, `ScoreBoard`, `ResultPage`, `FlagImage`, `AnswerButton` |
| **ViewModel** | Hold UI state, orchestrate game logic, expose data via Provider | `QuizViewModel`, `GameViewModel` |
| **Service/Repository** | Fetch data from API, persist/retrieve local data | `CountryService`, `StorageService` |
| **Model** | Plain Dart data classes | `Country`, `GameState`, `Question` |

### 4.2 Provider Setup

```dart
// main.dart — MultiProvider at the root
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => GameViewModel()),
    ChangeNotifierProvider(create: (_) => QuizViewModel()),
  ],
  child: const MyApp(),
)
```

---

## 5. Data Models

### 5.1 Country

```dart
class Country {
  final String name;    // common name, e.g. "United States"
  final String isoCode; // cca2, e.g. "US"

  const Country({required this.name, required this.isoCode});

  String get flagUrl => 'https://flagcdn.com/w320/${isoCode.toLowerCase()}.png';

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      name: json['name']['common'] as String,
      isoCode: json['cca2'] as String,
    );
  }
}
```

### 5.2 Question

```dart
class Question {
  final Country correctCountry;
  final List<Country> options; // always 4, shuffled

  const Question({required this.correctCountry, required this.options});
}
```

### 5.3 GameState (persisted)

```dart
class GameState {
  final int totalScore;
  final List<String> solvedIsoCodes; // ISO codes of solved countries

  const GameState({
    this.totalScore = 0,
    this.solvedIsoCodes = const [],
  });

  GameState copyWith({int? totalScore, List<String>? solvedIsoCodes}) { ... }

  Map<String, dynamic> toJson() => {
    'totalScore': totalScore,
    'solvedIsoCodes': solvedIsoCodes,
  };

  factory GameState.fromJson(Map<String, dynamic> json) { ... }
}
```

---

## 6. Services

### 6.1 CountryService

```dart
class CountryService {
  static const String _baseUrl = 'https://restcountries.com/v3.1';

  final http.Client _client;

  CountryService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches all countries from the REST API.
  Future<List<Country>> fetchAllCountries() async {
    final response = await _client.get(Uri.parse('$_baseUrl/all'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => Country.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load countries: ${response.statusCode}');
  }

  /// Builds a question: picks a correct country and 3 random distractors.
  Question generateQuestion(List<Country> pool) {
    final random = Random();
    final correct = pool[random.nextInt(pool.length)];
    final distractors = pool.where((c) => c.isoCode != correct.isoCode).toList()
      ..shuffle(random);
    final options = [correct, ...distractors.take(3)]..shuffle(random);
    return Question(correctCountry: correct, options: options);
  }
}
```

### 6.2 StorageService

```dart
class StorageService {
  static const String _gameStateKey = 'game_state';

  final SharedPreferences _prefs;

  StorageService({SharedPreferences? prefs}) : _prefs = prefs ?? SharedPreferences.getInstance();

  /// Loads the persisted game state.
  Future<GameState> loadGameState() async {
    final jsonString = await _prefs.getString(_gameStateKey);
    if (jsonString != null) {
      return GameState.fromJson(json.decode(jsonString));
    }
    return const GameState();
  }

  /// Saves the current game state.
  Future<void> saveGameState(GameState state) async {
    await _prefs.setString(_gameStateKey, json.encode(state.toJson()));
  }
}
```

---

## 7. ViewModels

### 7.1 GameViewModel

Manages the overall game lifecycle: score, solved flags, reset logic.

```dart
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

  // Getters
  GameState get state => _state;
  List<Country> get allCountries => _allCountries;
  bool get isLoading => _isLoading;
  int get totalScore => _state.totalScore;
  List<String> get solvedIsoCodes => _state.solvedIsoCodes;

  /// Countries that have NOT been solved yet.
  List<Country> get availableCountries =>
      _allCountries.where((c) => !_state.solvedIsoCodes.contains(c.isoCode)).toList();

  /// Whether all countries have been solved (game complete).
  bool get isGameComplete => availableCountries.isEmpty;

  /// Initialize: load persisted state and fetch countries.
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    _state = await _storageService.loadGameState();
    _allCountries = await _countryService.fetchAllCountries();

    _isLoading = false;
    notifyListeners();
  }

  /// Award points and mark a country as solved.
  Future<void> markSolved(String isoCode, int points) async {
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
```

### 7.2 QuizViewModel

Manages the current question, attempts, and answer evaluation.

```dart
class QuizViewModel extends ChangeNotifier {
  final GameViewModel _gameViewModel;

  Question? _currentQuestion;
  int _attempts = 0; // 0, 1, 2, 3
  bool _isRevealed = false;
  String? _selectedAnswer;
  bool _isCorrect = false;

  QuizViewModel({required GameViewModel gameViewModel})
      : _gameViewModel = gameViewModel;

  // Getters
  Question? get currentQuestion => _currentQuestion;
  int get attempts => _attempts;
  bool get isRevealed => _isRevealed;
  String? get selectedAnswer => _selectedAnswer;
  bool get isCorrect => _isCorrect;
  bool get hasAttemptsLeft => _attempts < 3;

  /// Points awarded per attempt number (1-indexed).
  static const List<int> pointsTable = [10, 8, 5];

  /// Generate a new question from available countries.
  void nextQuestion() {
    final available = _gameViewModel.availableCountries;
    if (available.isEmpty) return;

    _currentQuestion = _gameViewModel.countryService.generateQuestion(available);
    _attempts = 0;
    _isRevealed = false;
    _selectedAnswer = null;
    _isCorrect = false;
    notifyListeners();
  }

  /// Submit an answer. Returns true if correct.
  Future<bool> submitAnswer(String countryName) async {
    if (_isRevealed || _currentQuestion == null) return false;

    _selectedAnswer = countryName;
    _attempts++;

    if (countryName == _currentQuestion!.correctCountry.name) {
      _isCorrect = true;
      final points = pointsTable[_attempts - 1];
      await _gameViewModel.markSolved(_currentQuestion!.correctCountry.isoCode, points);
      notifyListeners();
      return true;
    }

    if (_attempts >= 3) {
      _isRevealed = true;
    }

    notifyListeners();
    return false;
  }

  /// Move to the next question after a correct answer or reveal.
  void advance() {
    nextQuestion();
  }
}
```

---

## 8. UI Screens & Widgets

### 8.1 Screen Flow

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│  App Start  │────▶│   QuizPage   │────▶│ ResultPage  │
│  (loading)  │     │  (gameplay)  │     │ (game over) │
└─────────────┘     └──────┬───────┘     └──────┬──────┘
                           │                     │
                           │  all solved         │ reset
                           ▼                     ▼
                    ┌──────────────┐     ┌─────────────┐
                    │  QuizPage    │◀────│  QuizPage   │
                    │  (next flag) │     │  (restart)  │
                    └──────────────┘     └─────────────┘
```

### 8.2 Widget Tree

```
QuizPage (Scaffold)
├── AppBar
│   ├── Title: "Country Trivia"
│   └── ScoreBoard (displays current score)
├── Body
│   ├── FlagImage (cached network image)
│   ├── AttemptsIndicator (shows remaining attempts)
│   └── AnswerOptions
│       ├── AnswerButton (x4)
│       │   ├── Correct → green highlight
│       │   ├── Wrong   → red highlight
│       │   └── Revealed → correct answer highlighted
│       └── (disabled after reveal)
└── BottomSheet / Dialog (on reveal)
    ├── "The correct answer is: {country}"
    └── "Next" button
```

### 8.3 Key Widgets

| Widget | Purpose |
|--------|---------|
| `FlagImage` | Displays flag from URL with loading/error states |
| `AnswerButton` | Tappable option with color-coded feedback |
| `ScoreBoard` | Shows running total score |
| `AttemptsIndicator` | Visual dots/bars for remaining attempts |
| `GameCompleteDialog` | Shown when all countries are solved |

---

## 9. Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  provider: ^6.1.2          # State management
  http: ^1.2.2               # HTTP client for REST API
  shared_preferences: ^2.3.3   # Local persistence
  cached_network_image: ^3.4.1  # Flag image caching (disk + memory)

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  mockito: ^5.4.4            # Mocking for tests
  build_runner: ^2.4.12      # Code generation (if needed)
  coverage: ^1.8.0           # Code coverage reporting
```

---

## 10. Project Structure

```
lib/
├── main.dart                      # App entry point, MultiProvider setup
├── models/
│   ├── country.dart               # Country data class
│   ├── question.dart              # Question data class
│   └── game_state.dart            # Persisted game state
├── services/
│   ├── country_service.dart       # API client + question generation
│   └── storage_service.dart       # SharedPreferences wrapper
├── viewmodels/
│   ├── game_view_model.dart       # Game lifecycle, score, solved flags
│   └── quiz_view_model.dart       # Current question, attempts, answers
├── views/
│   ├── quiz_page.dart             # Main gameplay screen
│   ├── result_page.dart           # Game complete / reset screen
│   └── widgets/
│       ├── flag_image.dart        # Network image with loading/error
│       ├── answer_button.dart     # Answer option button
│       ├── score_board.dart       # Score display
│       └── attempts_indicator.dart # Remaining attempts visual
└── utils/
    ├── constants.dart             # API URLs, points table, keys
    └── app_theme.dart             # Theme configuration
```

---

## 11. Game Logic Flow

### 11.1 Question Lifecycle

```
1. App starts
   ├── Load persisted GameState from SharedPreferences
   ├── Fetch all countries from REST API
   └── Filter out already-solved countries

2. Generate question
   ├── Pick random country from available pool
   ├── Pick 3 random distractors from remaining pool
   ├── Shuffle all 4 options
   └── Display flag + 4 names

3. User selects an answer
   ├── CORRECT
   │   ├── Award points (10/8/5 based on attempt)
   │   ├── Mark country as solved
   │   ├── Persist updated GameState
   │   └── Show success feedback → next question
   └── WRONG
       ├── Increment attempt counter
       ├── If attempts < 3: allow another try
       └── If attempts == 3: reveal correct answer, 0 points
           └── Show "Next" button → next question

4. Check game completion
   ├── If available pool is empty → show ResultPage
   └── ResultPage offers "Play Again" → resetGame()
```

### 11.2 Scoring Table

| Attempt | Points |
|---------|--------|
| 1st     | 10     |
| 2nd     | 8      |
| 3rd     | 5      |
| Failed  | 0      |

---

## 12. Persistence Strategy

### 12.1 What is Persisted

| Data | Key | Format |
|------|-----|--------|
| Total score | `game_state.totalScore` | `int` |
| Solved ISO codes | `game_state.solvedIsoCodes` | `List<String>` |

### 12.2 When is Data Written

- After each correct answer (score + solved list updated)
- After game reset (cleared to defaults)

### 12.3 Storage Format (SharedPreferences)

```json
{
  "totalScore": 42,
  "solvedIsoCodes": ["US", "FR", "DE", "JP", "BR"]
}
```

---

## 13. Flag Caching Strategy

### 13.1 Overview

Flag images are cached on-device to improve performance, reduce network usage, and enable offline display of previously seen flags.

### 13.2 Caching Layers

| Layer | Mechanism | Persistence | Purpose |
|-------|-----------|-------------|---------|
| **Memory cache** | `CachedNetworkImage` in-memory LRU | App session | Instant display of recently viewed flags |
| **Disk cache** | `CachedNetworkImage` / `flutter_cache_manager` | Persistent across restarts | Offline access to previously loaded flags |
| **HTTP cache** | `Cache-Control` headers from flagcdn.com | Per CDN policy | Reduces redundant network requests |

### 13.3 Implementation

```dart
// views/widgets/flag_image.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class FlagImage extends StatelessWidget {
  final String url;
  final double width;
  final double height;

  const FlagImage({
    super.key,
    required this.url,
    this.width = 320,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      // Memory cache: keep recently viewed flags in RAM
      memCacheWidth: width.toInt(),
      memCacheHeight: height.toInt(),
      // Disk cache: persist across app restarts
      cacheManager: CacheManager(
        Config(
          'flag_cache',
          stalePeriod: const Duration(days: 30),
          maxNrOfCacheObjects: 500, // ~500 flags at 320px
          fileService: HttpFileService(),
        ),
      ),
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
        ),
      ),
    );
  }
}
```

### 13.4 Cache Configuration

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Cache key | `flag_cache` | Isolated namespace for flag images |
| Stale period | 30 days | Flags rarely change; long cache is safe |
| Max objects | 500 | Covers all UN-recognized countries (~195) with headroom |
| Image width | 320px | Matches `w320` CDN size; balances quality and storage |
| Eviction policy | LRU (default) | Least recently used removed first |

### 13.5 Cache Behavior

| Scenario | Behavior |
|----------|----------|
| First load of a flag | Fetch from network → store in memory + disk |
| Revisiting a cached flag | Load from memory (instant) or disk (fast) |
| App restart | Memory cache cleared; disk cache serves flags offline |
| Cache entry expired (>30 days) | Re-fetch from network, replace stale entry |
| Cache full (500 flags) | LRU eviction removes oldest unused flags |
| Network offline + flag cached | Display from disk cache |
| Network offline + flag not cached | Show placeholder icon |

### 13.6 Prefetching (Optional Enhancement)

To further smooth gameplay, prefetch the next question's flag while the user is answering the current one:

```dart
// In QuizViewModel or a dedicated PrefetchService
void prefetchNextFlag(String isoCode) {
  final url = 'https://flagcdn.com/w320/${isoCode.toLowerCase()}.png';
  precacheImage(CachedNetworkImageProvider(url), context);
}
```

---

## 14. Error Handling



| Scenario | Handling |
|----------|----------|
| API fetch failure | Show error dialog with retry button |
| Flag image load failure | Show placeholder icon |
| SharedPreferences failure | Log warning, continue with defaults |
| Empty country pool | Trigger game complete flow |
| Network timeout | Show timeout message, offer retry |

---

## 14. Testing Strategy

### 14.1 Coverage Targets

| Layer | Target Coverage | Scope |
|-------|----------------|-------|
| **Services (Data Source)** | ≥ 80% | `CountryService`, `StorageService` — all public methods, error paths, edge cases |
| **ViewModels** | ≥ 80% | `GameViewModel`, `QuizViewModel` — all state transitions, boundary conditions |
| Models | ≥ 80% | Serialization/deserialization, factory constructors |
| UI (Views + Widgets) | Best effort | Critical user flows via widget tests |

> **Enforcement:** Run `flutter test --coverage` and verify with `genhtml` or `lcov` that services and view models meet the 80% threshold. Add tests for any uncovered branches before merging.

### 14.2 Unit Tests — Services (Data Source)

| Component | Test Cases |
|-----------|-----------|
| `Country.fromJson` | Parses valid JSON, handles missing/null fields, empty strings |
| `Country.flagUrl` | Correct URL format with lowercase ISO code |
| `CountryService.fetchAllCountries` | Success (200), server error (500), network exception, malformed JSON, empty array |
| `CountryService.generateQuestion` | Returns 4 unique options, includes correct answer, handles pool of exactly 4, handles pool < 4 (edge case) |
| `StorageService.loadGameState` | Returns saved state, returns default when key missing, handles corrupted JSON |
| `StorageService.saveGameState` | Round-trip persistence, overwrites existing data |

### 14.3 Unit Tests — ViewModels

| Component | Test Cases |
|-----------|-----------|
| `GameViewModel.initialize` | Loads persisted state, fetches countries, handles API failure |
| `GameViewModel.markSolved` | Updates score correctly, appends to solved list, prevents duplicates, persists state |
| `GameViewModel.resetGame` | Clears score to 0, clears solved list, persists reset state |
| `GameViewModel.availableCountries` | Filters out solved, returns empty when all solved |
| `GameViewModel.isGameComplete` | True when pool empty, False when countries remain |
| `QuizViewModel.nextQuestion` | Generates question from available pool, resets attempts/selection |
| `QuizViewModel.submitAnswer` | Correct on 1st attempt (10 pts), 2nd (8 pts), 3rd (5 pts), wrong answers increment counter, reveal after 3rd wrong, no double-submit after reveal |
| `QuizViewModel.advance` | Calls nextQuestion, resets state |

### 14.4 Widget Tests

| Screen | Test Cases |
|--------|-----------|
| `QuizPage` | Renders flag, 4 options, score; tap correct/wrong answers; disabled after reveal |
| `ResultPage` | Shows final score, reset button triggers reset |
| `AnswerButton` | Color changes on correct/wrong/revealed states; disabled state |
| `FlagImage` | Shows placeholder on error, loads image on success |

### 14.5 Integration Tests

| Flow | Test Cases |
|------|-----------|
| Full game loop | Start → answer questions → verify score → restart |
| Persistence | Answer questions → kill app → relaunch → verify state restored |
| Flag caching | Load flag → kill app → relaunch → flag loads from disk cache (no network) |

---

## 15. Execution Plan — Phased Implementation



### Phase 1: Project Setup & Dependencies
1. Add dependencies to `pubspec.yaml` (provider, http, shared_preferences, cached_network_image)
2. Run `flutter pub get`
3. Create folder structure under `lib/`
4. Create `lib/utils/constants.dart` with API URLs and configuration

### Phase 2: Data Layer
1. Implement `Country` model with `fromJson` factory
2. Implement `Question` model
3. Implement `GameState` model with `toJson`/`fromJson`
4. Implement `CountryService` with HTTP client and question generation
5. Implement `StorageService` with SharedPreferences wrapper
6. Write unit tests for all models and services
7. **Coverage gate:** Run `flutter test --coverage` — services must be ≥ 80%

### Phase 3: ViewModel Layer
1. Implement `GameViewModel` (initialize, markSolved, resetGame)
2. Implement `QuizViewModel` (nextQuestion, submitAnswer, advance)
3. Write unit tests for both ViewModels (mock services)
4. **Coverage gate:** Run `flutter test --coverage` — view models must be ≥ 80%

### Phase 4: UI Layer
1. Implement `main.dart` with MultiProvider setup
2. Implement `FlagImage` widget with `CachedNetworkImage` (memory + disk cache, 30-day stale period, 500 max objects)
3. Implement `AnswerButton` widget (color-coded feedback)
4. Implement `ScoreBoard` widget
5. Implement `AttemptsIndicator` widget
6. Implement `QuizPage` (main gameplay screen)
7. Implement `ResultPage` (game complete screen)
8. Write widget tests for all screens
9. **Flag caching verification:** Test that flags load from disk cache after app restart

### Phase 5: Integration & Polish
1. Wire up full game flow end-to-end
2. Add error handling dialogs (network failure, retry)
3. Add loading states and transitions
4. Add app theme and styling
5. Run full test suite (`flutter test`)
6. Run `flutter analyze` and fix any issues
7. Test on Android emulator and iOS simulator

### Phase 6: Final Validation
1. Verify all requirements (R1–R9) are met
2. Test persistence: answer questions, kill app, relaunch, verify state
3. Test reset: complete all countries, verify reset works
4. Test edge cases: single country, duplicate names, network failure
5. Performance check: smooth scrolling, fast image loading
6. **Coverage gate:** Run `flutter test --coverage` and confirm ≥ 80% on services and view models
7. **Flag cache verification:** Kill app, relaunch, confirm flags render from disk cache without network calls

---

## 16. Risk Mitigation



| Risk | Mitigation |
|------|-----------|
| API rate limiting / downtime | Cache country list locally after first fetch; show error with retry |
| Duplicate country names in options | Deduplicate by name when selecting distractors |
| Very long country names | Use `TextOverflow.ellipsis` and flexible layouts |
| Slow flag image loading | Use `cached_network_image` with placeholder and fade-in |
| SharedPreferences data corruption | Wrap in try-catch, fall back to defaults on parse error |

---

## 17. Future Enhancements (Out of Scope)



- Difficulty levels (more/fewer options, time limits)
- Categories (by continent, region)
- Leaderboard / social sharing
- Sound effects and animations
- Offline mode with pre-bundled country data
- Streak bonuses and achievements
- Dark mode toggle
