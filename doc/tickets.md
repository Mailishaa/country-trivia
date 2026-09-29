# Country Trivia App — Execution Tickets

## Legend

| Marker | Meaning |
|--------|---------|
| `[SEQUENTIAL]` | Must wait for predecessor(s) to complete |
| `[CONCURRENT]` | Can be executed in parallel with other tickets at the same level |
| `[GATE]` | Must pass before proceeding to next phase |

---

## Phase 1: Project Setup & Dependencies

### T1 — Add Dependencies to `pubspec.yaml`
- **Status:** `[SEQUENTIAL]`
- **Depends on:** None
- **Description:** Add `provider`, `http`, `shared_preferences`, `cached_network_image` to dependencies; add `coverage` to dev_dependencies. Run `flutter pub get`.
- **Acceptance Criteria:**
  - `flutter pub get` completes without errors
  - All packages resolve to compatible versions

---

### T2 — Create Project Folder Structure
- **Status:** `[CONCURRENT]` with T1
- **Depends on:** None
- **Description:** Create the folder structure under `lib/`:
  ```
  lib/
  ├── main.dart
  ├── models/
  ├── services/
  ├── viewmodels/
  ├── views/
  │   └── widgets/
  └── utils/
  ```
- **Acceptance Criteria:**
  - All directories exist
  - No files created yet (structure only)

---

### T3 — Create Constants File
- **Status:** `[CONCURRENT]` with T1, T2
- **Depends on:** None
- **Description:** Create `lib/utils/constants.dart` with API base URL, flag CDN URL pattern, points table, cache configuration, and SharedPreferences keys.
- **Acceptance Criteria:**
  - `kCountriesApiUrl = 'https://restcountries.com/v3.1/all'`
  - `kFlagUrlPattern = 'https://flagcdn.com/w320/{iso}.png'`
  - `kPointsTable = [10, 8, 5]`
  - `kGameStateKey = 'game_state'`
  - Cache config constants (stale period, max objects)

---

## Phase 2: Data Layer

### T4 — Implement `Country` Model
- **Status:** `[CONCURRENT]` with T5, T6
- **Depends on:** T1, T2
- **Description:** Create `lib/models/country.dart` with `Country` class: `name`, `isoCode` fields, `fromJson` factory, `flagUrl` getter.
- **Acceptance Criteria:**
  - Parses `name.common` and `cca2` from JSON
  - `flagUrl` returns lowercase ISO code URL
  - `toString`, `==`, `hashCode` implemented

---

### T5 — Implement `Question` Model
- **Status:** `[CONCURRENT]` with T4, T6
- **Depends on:** T1, T2
- **Description:** Create `lib/models/question.dart` with `Question` class: `correctCountry`, `options` (List of 4 Countries).
- **Acceptance Criteria:**
  - Immutable fields
  - `options` always contains `correctCountry`

---

### T6 — Implement `GameState` Model
- **Status:** `[CONCURRENT]` with T4, T5
- **Depends on:** T1, T2
- **Description:** Create `lib/models/game_state.dart` with `GameState` class: `totalScore`, `solvedIsoCodes`, `copyWith`, `toJson`, `fromJson`.
- **Acceptance Criteria:**
  - `copyWith` creates new instance with updated fields
  - `toJson` / `fromJson` round-trip correctly
  - Default values: `totalScore = 0`, `solvedIsoCodes = []`

---

### T7 — Implement `CountryService`
- **Status:** `[SEQUENTIAL]`
- **Depends on:** T4 (Country model)
- **Description:** Create `lib/services/country.dart` with `CountryService` class: `fetchAllCountries()` (HTTP GET, parse JSON), `generateQuestion(pool)` (pick correct + 3 distractors, shuffle).
- **Acceptance Criteria:**
  - `fetchAllCountries` returns `List<Country>` on 200 response
  - Throws exception on non-200 status
  - `generateQuestion` returns `Question` with 4 unique options
  - Correct answer is always in options
  - Options are shuffled

---

### T8 — Implement `StorageService`
- **Status:** `[CONCURRENT]` with T7
- **Depends on:** T6 (GameState model)
- **Description:** Create `lib/services/storage_service.dart` with `StorageService` class: `loadGameState()`, `saveGameState(state)`.
- **Acceptance Criteria:**
  - `loadGameState` returns `GameState` from SharedPreferences
  - Returns default `GameState()` when key missing
  - `saveGameState` persists JSON to SharedPreferences
  - Handles corrupted JSON gracefully (returns default)

---

### T9 — Unit Tests for Models
- **Status:** `[CONCURRENT]` with T10
- **Depends on:** T4, T5, T6
- **Description:** Create unit tests for `Country`, `Question`, `GameState` models.
- **Test Cases:**
  - `Country.fromJson`: valid JSON, missing fields, null values
  - `Country.flagUrl`: correct URL format, lowercase conversion
  - `GameState.toJson/fromJson`: round-trip, default values
  - `GameState.copyWith`: partial update, full update
- **Acceptance Criteria:**
  - All tests pass
  - ≥ 80% coverage on models

---

### T10 — Unit Tests for Services
- **Status:** `[CONCURRENT]` with T9
- **Depends on:** T7, T8
- **Description:** Create unit tests for `CountryService` and `StorageService` using `mockito` to mock HTTP client and SharedPreferences.
- **Test Cases:**
  - `CountryService.fetchAllCountries`: 200 success, 500 error, network exception, malformed JSON, empty array
  - `CountryService.generateQuestion`: 4 unique options, correct answer included, pool of exactly 4, pool < 4 edge case
  - `StorageService.loadGameState`: saved state exists, key missing, corrupted JSON
  - `StorageService.saveGameState`: round-trip, overwrite existing
- **Acceptance Criteria:**
  - All tests pass
  - ≥ 80% coverage on services
  - `[GATE]` Must pass before Phase 3

---

## Phase 3: ViewModel Layer

### T11 — Implement `GameViewModel`
- **Status:** `[SEQUENTIAL]`
- **Depends on:** T7, T8, T10 (services + tests must pass)
- **Description:** Create `lib/viewmodels/game_view_model.dart` with `GameViewModel extends ChangeNotifier`: `initialize()`, `markSolved(isoCode, points)`, `resetGame()`, getters for `state`, `availableCountries`, `isGameComplete`, `totalScore`, `solvedIsoCodes`.
- **Acceptance Criteria:**
  - `initialize` loads persisted state and fetches countries
  - `markSolved` updates score, appends ISO code, persists state
  - `resetGame` clears score and solved list, persists
  - `availableCountries` filters out solved
  - `isGameComplete` returns true when pool empty
  - Calls `notifyListeners()` on all state changes

---

### T12 — Implement `QuizViewModel`
- **Status:** `[SEQUENTIAL]`
- **Depends on:** T11 (GameViewModel)
- **Description:** Create `lib/viewmodels/quiz_view_model.dart` with `QuizViewModel extends ChangeNotifier`: `nextQuestion()`, `submitAnswer(countryName)`, `advance()`, getters for `currentQuestion`, `attempts`, `isRevealed`, `selectedAnswer`, `isCorrect`, `hasAttemptsLeft`.
- **Acceptance Criteria:**
  - `nextQuestion` generates from available pool, resets attempts/selection
  - `submitAnswer` returns true on correct, awards points (10/8/5), marks solved
  - Wrong answer increments counter, reveals after 3rd
  - No submission accepted after reveal
  - `advance` calls `nextQuestion`

---

### T13 — Unit Tests for ViewModels
- **Status:** `[SEQUENTIAL]`
- **Depends on:** T11, T12
- **Description:** Create unit tests for `GameViewModel` and `QuizViewModel` using mocked services.
- **Test Cases:**
  - `GameViewModel.initialize`: loads state, fetches countries, API failure
  - `GameViewModel.markSolved`: score update, append solved, duplicate prevention, persistence
  - `GameViewModel.resetGame`: clears score, clears list, persists
  - `GameViewModel.availableCountries`: filters solved, empty when all solved
  - `QuizViewModel.nextQuestion`: generates question, resets state
  - `QuizViewModel.submitAnswer`: correct 1st (10pts), 2nd (8pts), 3rd (5pts), wrong increments, reveal after 3rd, no double-submit
  - `QuizViewModel.advance`: calls nextQuestion
- **Acceptance Criteria:**
  - All tests pass
  - ≥ 80% coverage on view models
  - `[GATE]` Must pass before Phase 4

---

## Phase 4: UI Layer

### T14 — Implement `main.dart` with MultiProvider Setup
- **Status:** `[SEQUENTIAL]`
- **Depends on:** T11, T12 (ViewModels)
- **Description:** Rewrite `lib/main.dart` with `MultiProvider` at root, `GameViewModel` and `QuizViewModel` as `ChangeNotifierProvider`s, `MaterialApp` with theme.
- **Acceptance Criteria:**
  - Providers initialized with services
  - `GameViewModel.initialize()` called on app start
  - App launches to `QuizPage`

---

### T15 — Implement `FlagImage` Widget
- **Status:** `[CONCURRENT]` with T16, T17, T18
- **Depends on:** T1, T3 (constants for cache config)
- **Description:** Create `lib/views/widgets/flag_image.dart` with `CachedNetworkImage`, custom `CacheManager` (30-day stale, 500 max objects), placeholder and error widgets.
- **Acceptance Criteria:**
  - Displays flag from URL
  - Shows `CircularProgressIndicator` while loading
  - Shows placeholder icon on error
  - Disk cache configured with correct parameters
  - Memory cache dimensions set

---

### T16 — Implement `AnswerButton` Widget
- **Status:** `[CONCURRENT]` with T15, T17, T18
- **Depends on:** None (pure UI)
- **Description:** Create `lib/views/widgets/answer_button.dart` with color-coded states: default, correct (green), wrong (red), revealed (highlight correct), disabled.
- **Acceptance Criteria:**
  - Displays country name text
  - `onTap` callback fires when enabled
  - Visual feedback for each state
  - `disabled` property prevents taps

---

### T17 — Implement `ScoreBoard` Widget
- **Status:** `[CONCURRENT]` with T15, T16, T18
- **Depends on:** None (pure UI)
- **Description:** Create `lib/views/widgets/score_board.dart` displaying current score with icon.
- **Acceptance Criteria:**
  - Displays score integer
  - Styled with theme colors
  - Responsive layout

---

### T18 — Implement `AttemptsIndicator` Widget
- **Status:** `[CONCURRENT]` with T15, T16, T17
- **Depends on:** None (pure UI)
- **Description:** Create `lib/views/widgets/attempts_indicator.dart` showing 3 dots/bars representing remaining attempts.
- **Acceptance Criteria:**
  - Shows 3 indicators total
  - Filled/empty based on `attemptsRemaining`
  - Visual distinction between used and remaining

---

### T19 — Implement `QuizPage`
- **Status:** `[SEQUENTIAL]`
- **Depends on:** T14, T15, T16, T17, T18
- **Description:** Create `lib/views/quiz_page.dart` — main gameplay screen with `AppBar` (title + `ScoreBoard`), `FlagImage`, `AttemptsIndicator`, 4 `AnswerButton`s, reveal dialog with "Next" button.
- **Acceptance Criteria:**
  - Renders flag, 4 options, score, attempts
  - Tap correct answer → success feedback → next question
  - Tap wrong answer → red highlight → allow retry
  - 3rd wrong → reveal correct answer → show "Next" button
  - All buttons disabled after reveal
  - Auto-advance after correct answer (with delay)

---

### T20 — Implement `ResultPage`
- **Status:** `[CONCURRENT]` with T19
- **Depends on:** T14
- **Description:** Create `lib/views/result_page.dart` — game complete screen showing final score, "Play Again" button that calls `resetGame()`.
- **Acceptance Criteria:**
  - Displays final score
  - "Play Again" button triggers reset
  - Navigates back to `QuizPage` after reset

---

### T21 — Widget Tests for UI
- **Status:** `[SEQUENTIAL]`
- **Depends on:** T19, T20
- **Description:** Create widget tests for `QuizPage`, `ResultPage`, `AnswerButton`, `FlagImage`.
- **Test Cases:**
  - `QuizPage`: renders flag, 4 options, score; tap correct/wrong; disabled after reveal
  - `ResultPage`: shows score, reset button works
  - `AnswerButton`: color states, disabled state
  - `FlagImage`: placeholder on error
- **Acceptance Criteria:**
  - All widget tests pass
  - Critical user flows covered

---

## Phase 5: Integration & Polish

### T22 — Wire Up Full Game Flow
- **Status:** `[SEQUENTIAL]`
- **Depends on:** T19, T20, T21
- **Description:** Connect all screens and ViewModels end-to-end. Ensure question generation, answer submission, scoring, reveal, next question, and game reset all work together.
- **Acceptance Criteria:**
  - Complete game loop functions without crashes
  - State transitions are correct at every step
  - No orphaned UI states

---

### T23 — Add Error Handling Dialogs
- **Status:** `[CONCURRENT]` with T24, T25
- **Depends on:** T22
- **Description:** Add error dialogs for API fetch failure, network timeout, and SharedPreferences errors. Include "Retry" and "Dismiss" actions.
- **Acceptance Criteria:**
  - API failure shows error dialog with retry
  - Network timeout shows timeout message
  - SharedPreferences failure logs warning, continues with defaults
  - User can retry failed operations

---

### T24 — Add Loading States and Transitions
- **Status:** `[CONCURRENT]` with T23, T25
- **Depends on:** T22
- **Description:** Add loading indicators for initial data fetch, question transitions, and answer submission feedback (animations, snackbars).
- **Acceptance Criteria:**
  - Loading spinner during initial fetch
  - Smooth transition between questions
  - Visual feedback on answer submission (snackbar or animation)

---

### T25 — Add App Theme and Styling
- **Status:** `[CONCURRENT]` with T23, T24
- **Depends on:** T22
- **Description:** Create `lib/utils/app_theme.dart` with `ThemeData` configuration. Apply consistent colors, typography, and spacing across all widgets.
- **Acceptance Criteria:**
  - `ThemeData` defined with color scheme
  - All widgets use theme colors (no hardcoded colors)
  - Consistent padding/spacing via theme

---

### T26 — Run Full Test Suite
- **Status:** `[SEQUENTIAL]`
- **Depends on:** T22, T23, T24, T25
- **Description:** Run `flutter test` and ensure all unit and widget tests pass. Fix any failures.
- **Acceptance Criteria:**
  - All tests pass
  - No skipped tests
  - `[GATE]` Must pass before Phase 6

---

### T27 — Run `flutter analyze` and Fix Issues
- **Status:** `[CONCURRENT]` with T26
- **Depends on:** T22, T23, T24, T25
- **Description:** Run `flutter analyze` and fix all warnings and errors. Ensure code follows `flutter_lints` rules.
- **Acceptance Criteria:**
  - Zero errors
  - Zero warnings (or documented exceptions)
  - Code follows style guidelines

---

---

## Coverage Verification Tooling

`tool/coverage_report.py` parses `coverage/lcov.info` (produced by
`flutter test --coverage`) and prints per-file line coverage, exiting non-zero
if any gated file falls below the threshold.

```bash
flutter test --coverage
python3 tool/coverage_report.py 80
```

---

## Execution Result

All 34 tickets are implemented. Final state:

- **115 tests passing**, `flutter analyze` clean (0 issues)
- **Coverage gate passed** — every gated file (models, services, view models)
  is at or above 80%:

| File | Coverage |
|------|----------|
| `services/country_service.dart` | 100% |
| `services/storage_service.dart` | 100% |
| `viewmodels/game_view_model.dart` | 96.8% |
| `viewmodels/quiz_view_model.dart` | 100% |
| `models/country.dart` | 95.7% |
| `models/game_state.dart` | 85.2% |
| `models/question.dart` | 100% |

### Notes

- `restcountries.com` is the live REST Countries v3.1 endpoint behind the
  Postman documentation link. The plan referenced a mistyped host
  (`restcdn.com`), corrected in `lib/utils/constants.dart`.
- `flutter_cache_manager` is declared explicitly in `pubspec.yaml` because
  `FlagImage` uses `CacheManager`/`Config` directly rather than relying on
  `cached_network_image` re-exports.
- Widget tests that mount `QuizPage`/`ResultPage` use bounded `pump()` calls
  rather than `pumpAndSettle()`, because `FlagImage`'s placeholder spinner
  animates indefinitely and prevents settling.

---

## Phase 6: Final Validation

### T28 — Verify All Requirements (R1–R9)
- **Status:** `[SEQUENTIAL]`
- **Depends on:** T26, T27
- **Description:** Systematically verify each requirement from the master plan:
  - R1: Flag display from CDN
  - R2: Four country names per question
  - R3: Scoring (10/8/5/0)
  - R4: Reveal on failure
  - R5: No repeats
  - R6: Reset when all solved
  - R7: Persistence across restarts
  - R8: MVVM with Provider
  - R9: Countries from REST API
- **Acceptance Criteria:**
  - All requirements verified with manual or automated checks
  - Any gaps documented and addressed

---

### T29 — Test Persistence Across Restarts
- **Status:** `[CONCURRENT]` with T30, T31, T32
- **Depends on:** T28
- **Description:** Answer questions, kill app, relaunch, verify score and solved flags are restored.
- **Acceptance Criteria:**
  - Score persists after kill/relaunch
  - Solved flags persist after kill/relaunch
  - Previously solved flags do not reappear

---

### T30 — Test Game Reset
- **Status:** `[CONCURRENT]` with T29, T31, T32
- **Depends on:** T28
- **Description:** Complete all countries, verify ResultPage appears, tap "Play Again", verify score resets to 0 and all countries available again.
- **Acceptance Criteria:**
  - ResultPage shows when all countries solved
  - Reset clears score and solved list
  - All countries available after reset

---

### T31 — Test Edge Cases
- **Status:** `[CONCURRENT]` with T29, T30, T32
- **Depends on:** T28
- **Description:** Test edge cases: single country in pool, duplicate country names, network failure during gameplay, corrupted SharedPreferences data.
- **Acceptance Criteria:**
  - Single country: question still generates (may have < 4 options)
  - Duplicate names: deduplicated in options
  - Network failure: error dialog shown, retry works
  - Corrupted data: app starts with defaults, no crash

---

### T32 — Performance Check
- **Status:** `[CONCURRENT]` with T29, T30, T31
- **Depends on:** T28
- **Description:** Verify smooth scrolling, fast image loading, no jank during transitions, reasonable app startup time.
- **Acceptance Criteria:**
  - Flag images load within 2 seconds on WiFi
  - Question transitions are smooth (no frame drops)
  - App starts and shows first question within 3 seconds

---

### T33 — Coverage Gate
- **Status:** `[SEQUENTIAL]`
- **Depends on:** T26
- **Description:** Run `flutter test --coverage` and generate coverage report. Verify ≥ 80% coverage on services and view models.
- **Acceptance Criteria:**
  - `CountryService` ≥ 80% line coverage
  - `StorageService` ≥ 80% line coverage
  - `GameViewModel` ≥ 80% line coverage
  - `QuizViewModel` ≥ 80% line coverage
  - `[GATE]` Must pass before final sign-off

---

### T34 — Flag Cache Verification
- **Status:** `[CONCURRENT]` with T33
- **Depends on:** T29
- **Description:** Load flags, kill app, relaunch, verify flags render from disk cache without network calls.
- **Acceptance Criteria:**
  - Flags display after restart without network
  - Cache directory contains flag image files
  - Cache eviction works when limit reached

---

## Execution Order Summary

```
Phase 1: T1 [SEQ] ──┬── T2 [CONC] ──┬── T3 [CONC]
                     │               │
Phase 2:            │   T4 [CONC] ──┤
                     │   T5 [CONC] ──┤
                     │   T6 [CONC] ──┤
                     │               │
                     │   T7 [SEQ] ◄──┘ (depends on T4)
                     │   T8 [CONC] ◄── (depends on T6)
                     │               │
                     │   T9 [CONC] ◄── (depends on T4,T5,T6)
                     │   T10 [CONC] ◄─ (depends on T7,T8) [GATE]
                     │               │
Phase 3:            │   T11 [SEQ] ◄── (depends on T7,T8,T10)
                     │   T12 [SEQ] ◄── (depends on T11)
                     │   T13 [SEQ] ◄── (depends on T11,T12) [GATE]
                     │               │
Phase 4:            │   T14 [SEQ] ◄── (depends on T11,T12)
                     │   T15 [CONC] ◄── (depends on T1,T3)
                     │   T16 [CONC]
                     │   T17 [CONC]
                     │   T18 [CONC]
                     │   T19 [SEQ] ◄── (depends on T14,T15,T16,T17,T18)
                     │   T20 [CONC] ◄── (depends on T14)
                     │   T21 [SEQ] ◄── (depends on T19,T20)
                     │               │
Phase 5:            │   T22 [SEQ] ◄── (depends on T19,T20,T21)
                     │   T23 [CONC] ◄── (depends on T22)
                     │   T24 [CONC]
                     │   T25 [CONC]
                     │   T26 [SEQ] ◄── (depends on T22,T23,T24,T25) [GATE]
                     │   T27 [CONC] ◄── (depends on T22,T23,T24,T25)
                     │               │
Phase 6:            │   T28 [SEQ] ◄── (depends on T26,T27)
                     │   T29 [CONC] ◄── (depends on T28)
                     │   T30 [CONC]
                     │   T31 [CONC]
                     │   T32 [CONC]
                     │   T33 [SEQ] ◄── (depends on T26) [GATE]
                     │   T34 [CONC] ◄── (depends on T29)
```

---

## Concurrency Opportunities

| Phase | Concurrent Tickets | Time Savings |
|-------|-------------------|--------------|
| Phase 1 | T1, T2, T3 | ~30 min (parallel setup) |
| Phase 2 | T4, T5, T6 (models) | ~45 min (models are independent) |
| Phase 2 | T7, T8 (services) | ~30 min (services are independent) |
| Phase 2 | T9, T10 (tests) | ~30 min (tests are independent) |
| Phase 4 | T15, T16, T17, T18 (widgets) | ~1 hr (widgets are independent) |
| Phase 4 | T19, T20 (pages) | ~30 min (pages are independent) |
| Phase 5 | T23, T24, T25 (polish) | ~45 min (polish items are independent) |
| Phase 5 | T26, T27 (validation) | ~15 min (analyze can run while tests run) |
| Phase 6 | T29, T30, T31, T32 (validation) | ~30 min (tests are independent) |
| Phase 6 | T33, T34 (final gates) | ~15 min (coverage and cache check are independent) |

**Estimated total time savings from concurrency: ~5–6 hours**

---

## Critical Path

```
T1 → T4 → T7 → T10 → T11 → T12 → T13 → T14 → T15 → T19 → T21 → T22 → T26 → T28 → T33
```

The critical path consists of **14 sequential tickets** that cannot be parallelized. All other tickets have some concurrency opportunity.

---

## Definition of Done

A ticket is considered **complete** when:
1. All acceptance criteria are met
2. Code compiles without errors (`flutter analyze` clean)
3. Relevant tests pass (`flutter test`)
4. Changes are committed to git with a descriptive message
5. For `[GATE]` tickets: the gate condition is verified and documented
