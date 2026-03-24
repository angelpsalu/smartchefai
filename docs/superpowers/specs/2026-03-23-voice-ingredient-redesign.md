# Voice Search & Ingredient Matching Redesign

**Date:** 2026-03-23
**Status:** Approved
**Scope:** `voice_search_overlay.dart`, `firebase_service.dart`, `scan_screen.dart`, `firebase_providers.dart`

---

## Problem

Two voice flows exist in SmartChef AI:

1. **Voice recipe search** (search screen) — user speaks a recipe name → search results shown
2. **Voice ingredient input** (scan screen) — user speaks ingredients → recipes recommended

Both flows share a single bottom-sheet overlay with no visual distinction. The ingredient matching (`searchByIngredients`) calls TheMealDB API per-ingredient and returns any recipe loosely related to any ingredient spoken (OR logic). Result cards show no match context.

---

## Goals

- Full-screen voice overlay with polished state transitions and mode-specific visuals
- Ingredient matching that prioritises exact matches (ALL ingredients present) and surfaces partial matches (majority of ingredients present) below, sorted by match count descending
- "X of Y ingredients" match badge on result cards
- Offline-first: ingredient matching runs against local recipe cache only

---

## Non-Goals

- Changes to the home screen voice button behavior (still navigates to search screen)
- Changes to `VoiceSearchService` (speech engine wrapper is unchanged)
- Changes to `IngredientParser` (spoken text parser is unchanged)
- New model files or new screen files

---

## Design

### 1. Voice Overlay — Full-Screen Redesign

**Presentation:** Replace `showModalBottomSheet` with `showGeneralDialog` (`barrierDismissible: false`). Wrap the dialog content in `PopScope(canPop: false, onPopInvokedWithResult: (didPop, _) { if (!didPop) _cancel(); })` — Android back gesture triggers `_cancel()` (same as tapping the Cancel button), returning `null`. Entrance: 300ms slide-up + fade. Exit: 200ms fade-down.

**Background:** `Color(0xFF0D0D0D)` at 95% opacity — immersive dark, content faintly visible behind.

**Layout (top to bottom):**
```
[X] Cancel                          ← top-right IconButton, always visible
Status title                        ← "Listening…" / "Got it!" / error
Sub-hint text                       ← mode-specific, fades when words arrive
      ◉ ◯ ◯ ◯                      ← large ripple rings (200px mic button)
"chicken, rice and onions"          ← partial words, large bold text
[Chip] [Chip] [Chip]               ← ingredient mode only, real-time
[ Done ]   [ Try Again ]           ← shown after result/timeout state
```

**State machine — 4 states with explicit triggers:**

| State | Trigger | Title | Waves | Buttons |
|---|---|---|---|---|
| `listening` | `startListening()` called | Listening… | animated | — |
| `result` | `onResult` fires with non-empty words | Got it! | fade out (400ms) | Done (primary) + Try Again |
| `timeout` | `onDone` fires and `_partialWords` is empty (silence with no words captured) | Didn't catch that | stopped | Try Again + Cancel |
| `error` | `onError` fires (permanent mic error) | Mic unavailable | stopped | Cancel only |

"Try Again" calls `_startListening()` which clears `_partialWords` to `''` before restarting — no stale words shown on retry.

When the overlay closes:
- Done / Search → `Navigator.of(context).pop(_partialWords)` returns the spoken string
- Cancel / error Cancel → `Navigator.of(context).pop(null)` returns null

**Animation changes from current:**
- Mic button: 80px → 96px
- Ring max radii: 64/80/96px → 80/112/144px
- Result state: rings fade out with 400ms opacity animation (not hard-stop)
- Chips (ingredient mode): animate in with `ScaleTransition` + `FadeTransition`; only **newly added chips** animate (diff against previous chip list on each partial result) — already-displayed chips do not re-animate

---

### 2. Mode Parameterization

```dart
enum VoiceOverlayMode { recipeSearch, ingredientInput }
```

`showVoiceSearchOverlay` gains an optional `mode` parameter defaulting to `recipeSearch` — no change required at the search screen call site.

**Per-mode behaviour:**

| | `recipeSearch` | `ingredientInput` |
|---|---|---|
| Hint text | "Say a recipe name…" | "Say your ingredients, e.g. chicken, rice, onions" |
| Accent color | `AppColors.primaryOrange` | `AppColors.info` (blue) |
| Done button label | "Search" | "Use These Ingredients" |
| Real-time chips | no | yes — `IngredientParser.parse(partialWords)` on each partial result callback; diff against previous list to animate only new chips |
| Return value | raw `String?` | raw `String?` (parsing happens in `_onVoiceInput` after close) |

**Call site changes:**
- `search_screen.dart` — no change (default `recipeSearch`)
- `scan_screen.dart` — adds `mode: VoiceOverlayMode.ingredientInput`; remove `_isListeningIngredients` boolean and the early-return cancel path (`if (_isListeningIngredients) { await _voiceService.cancel(); return; }`). The `_voiceService.initialize()` call in `initState` and `_voiceService.dispose()` call in `dispose` remain — the service is still passed to the overlay.

---

### 3. Strict Ingredient Matching

**Algorithm:** Local-only. Drop all TheMealDB API calls from `searchByIngredients`. Filter `_cachedRecipes`.

Before filtering, ensure the cache is populated using the same lazy-loading guard already used in `searchRecipes` — i.e., if `_cachedRecipes.isEmpty`, call `getAllRecipes()` first.

A recipe's match count = number of user ingredients for which any `recipe.ingredients` string contains the user term (case-insensitive substring):

```
matchCount(recipe, userIngredients) =
  userIngredients.where((term) =>
    recipe.ingredients.any((i) => i.toLowerCase().contains(term.toLowerCase()))
  ).length
```

**Tiered inclusion and sorting:**
- **Tier 1** — `matchCount == N` (all ingredients match) → included, sorted first
- **Tier 2** — `matchCount >= ceil(N / 2)` and `matchCount < N` (majority match) → included, shown below Tier 1 with muted badge
- `matchCount < ceil(N / 2)` → excluded entirely

Results list sorted by `matchCount` descending within both tiers.

**Return type change:**

```dart
// Before
Future<List<Recipe>> searchByIngredients(List<String> ingredients)

// After
Future<List<({Recipe recipe, int matchCount})>> searchByIngredients(
  List<String> ingredients,
)
```

Uses Dart 3 anonymous record — no new model file needed.

**Note:** `scan_screen.dart` already calls `FirebaseService().searchByIngredients()` directly (bypassing `RecipeProvider`) to avoid overwriting the shared `_recipes` list used by the home screen. This pattern is preserved.

---

### 4. Scan Screen Results

**State variable update:**
```dart
// Before
List<Recipe> _scanRecipes = [];

// After
List<({Recipe recipe, int matchCount})> _scanRecipes = [];
int _totalRequested = 0;  // assigned inside _searchRecipes() immediately before the await call
bool _hasSearched = false;
```

`_totalRequested` is set inside `_searchRecipes()` as the first line (before the async call), not at detection time — this reflects the actual list after any chip removals.

**Layout:** Replace `SizedBox(height: 220)` horizontal `ListView` with a vertical `ListView` inside the existing `SingleChildScrollView`. Full-width cards.

**Match badge:** `Stack` wrapper around each `RecipeCard` with a positioned pill badge (no changes to `RecipeCard` itself):
- Full match (`matchCount == _totalRequested`): orange pill, `"All X matched"` (e.g. "All 3 matched")
- Partial match: `colorScheme.surfaceContainerHighest` background with muted text, `"X of Y"` (e.g. "2 of 3")

**Results header** (three cases):
```
exactCount > 0 && partialCount > 0  →  "${exactCount} exact · ${partialCount} partial"
exactCount > 0 && partialCount == 0 →  "${exactCount} recipe${exactCount == 1 ? '' : 's'} found"
exactCount == 0 && partialCount > 0 →  "${partialCount} partial match${partialCount == 1 ? '' : 'es'}"
```

**Empty state:** `EmptyState` widget only rendered when `_hasSearched == true` AND `_scanRecipes.isEmpty`. Not shown before any search has run. `_hasSearched` is set to `true` after the await completes in `_searchRecipes()` and reset to `false` alongside `_scanRecipes` in the "Scan Again / Try Again" clear action.

---

### 5. Provider Update

`RecipeProvider.searchByIngredients` calls the service and receives the new record list. It extracts only the `recipe` field to update `_recipes`:

```dart
Future<List<({Recipe recipe, int matchCount})>> searchByIngredients(
  List<String> ingredients,
) async {
  _isLoading = true;
  _error = null;
  notifyListeners();
  try {
    final results = await _firebaseService.searchByIngredients(ingredients);
    _recipes = results.map((r) => r.recipe).toList();
    _isLoading = false;
    notifyListeners();
    return results;
  } catch (e) {
    _error = e.toString();
    _isLoading = false;
    notifyListeners();
    rethrow;
  }
}
```

Note: this method is not called by `scan_screen.dart` (which uses the service directly), but is kept for any future callers. Its public return type changes to `Future<List<({Recipe recipe, int matchCount})>>` — any caller outside scan_screen must be updated to handle the new type.

---

## Files Changed

| File | Nature of change |
|---|---|
| `lib/shared/widgets/voice_search_overlay.dart` | Full rewrite: full-screen modal, 4-state machine, mode enum, real-time chips in ingredient mode |
| `lib/services/firebase_service.dart` | Rewrite `searchByIngredients`: drop API calls, local tiered match, return records |
| `lib/features/scan/scan_screen.dart` | Mode param, remove `_isListeningIngredients` + its cancel path, update result type, add `_totalRequested`/`_hasSearched`, vertical list, match badge, reset `_hasSearched` on clear |
| `lib/providers/firebase_providers.dart` | Update `searchByIngredients` return type + extract recipes from records |
| `lib/features/search/search_screen.dart` | No change |
| `lib/services/voice_search_service.dart` | No change |
| `lib/utils/ingredient_parser.dart` | No change |

---

## Out of Scope / Future

- Showing which specific recipe ingredients matched (expandable card detail)
- Synonym matching (e.g. "garlic" matching "garlic powder")
- Manual ingredient text input as alternative to voice
