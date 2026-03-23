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
- Strict ingredient matching: only return recipes containing ALL spoken ingredients
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

**Presentation:** Replace `showModalBottomSheet` with `showGeneralDialog`. Entrance: 300ms slide-up + fade. Exit: 200ms fade-down. Non-dismissible by tapping outside.

**Background:** `Color(0xFF0D0D0D)` at 95% opacity — immersive dark, content faintly visible behind.

**Layout (top to bottom):**
```
[X] Cancel                          ← top-right, always visible
Status title                        ← "Listening…" / "Got it!" / error
Sub-hint text                       ← mode-specific, fades when words arrive
      ◉ ◯ ◯ ◯                      ← large ripple rings (200px mic button)
"chicken, rice and onions"          ← partial words, large bold text
[Chip] [Chip] [Chip]               ← ingredient mode only, real-time
[ Done ]   [ Try Again ]           ← shown after result state
```

**State machine:**

| State | Title | Waves | Buttons |
|---|---|---|---|
| `listening` | Listening… | animated | — |
| `result` | Got it! | fade out (400ms) | Done (primary) + Try Again |
| `timeout` | Didn't catch that | stopped | Try Again + Cancel |
| `error` | Mic unavailable | stopped | Cancel only |

**Animation changes from current:**
- Mic button: 80px → 96px
- Ring max radii: 64/80/96px → 80/112/144px
- Result state: rings fade out with 400ms opacity animation (not hard-stop)
- Chips (ingredient mode): each chip enters with `ScaleTransition` + `FadeTransition`, 150ms stagger

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
| Real-time chips | no | yes — `IngredientParser.parse(partialWords)` on each partial result callback |
| Return value | raw `String?` | raw `String?` (parsing happens in `_onVoiceInput` after close) |

**Call site changes:**
- `search_screen.dart` — no change (default `recipeSearch`)
- `scan_screen.dart` — adds `mode: VoiceOverlayMode.ingredientInput`

---

### 3. Strict Ingredient Matching

**Algorithm:** Local-only. Drop all TheMealDB API calls from `searchByIngredients`. Run against `_cachedRecipes`.

A recipe passes if **every** user ingredient has at least one match in `recipe.ingredients` (case-insensitive substring):

```
for each userIngredient:
  recipe.ingredients.any((i) => i.toLowerCase().contains(userIngredient.toLowerCase()))

→ recipe included only if ALL user ingredients match
```

**Tiered results (sorted by match count descending):**
- **Tier 1** — all N ingredients match → shown first
- **Tier 2** — at least `ceil(N/2)` ingredients match (majority) → shown below with muted badge
- Fewer matches → excluded entirely

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

**Cache guarantee:** `searchByIngredients` calls `_ensureCacheLoaded()` before filtering to guarantee `_cachedRecipes` is populated (same pattern as `searchRecipes`).

---

### 4. Scan Screen Results

**Type update:**
```dart
// Before
List<Recipe> _scanRecipes = [];

// After
List<({Recipe recipe, int matchCount})> _scanRecipes = [];
```

**Layout:** Replace `SizedBox(height: 220)` horizontal `ListView` with a vertical `ListView` inside the existing `SingleChildScrollView`. Full-width cards.

**Match badge:** `Stack` wrapper around each `RecipeCard` with a positioned pill badge (no changes to `RecipeCard` itself):
- Full match (matchCount == totalRequested): orange pill, `"All X matched"`
- Partial match: `colorScheme.surfaceContainerHighest` pill with muted text, `"X of Y"`

**Results header:**
```dart
// e.g.: "4 exact · 2 partial" or "6 recipes found" if all exact
```

**Empty state:** `EmptyState` widget with `Icons.search_off`, title "No recipes found", subtitle "Try removing an ingredient or scanning again."

---

### 5. Provider Update

`RecipeProvider.searchByIngredients` updates its internal `_recipes` list using only the `recipe` field from each record. The `matchCount` is surfaced directly to `scan_screen` via the return value — not stored in provider state (it's scan-screen-local data).

```dart
Future<List<({Recipe recipe, int matchCount})>> searchByIngredients(
  List<String> ingredients,
) async { ... }
```

---

## Files Changed

| File | Nature of change |
|---|---|
| `lib/shared/widgets/voice_search_overlay.dart` | Full rewrite |
| `lib/services/firebase_service.dart` | Rewrite `searchByIngredients` method |
| `lib/features/scan/scan_screen.dart` | Mode param, result type, vertical list, match badge |
| `lib/providers/firebase_providers.dart` | Update `searchByIngredients` return type |
| `lib/features/search/search_screen.dart` | No change |
| `lib/services/voice_search_service.dart` | No change |
| `lib/utils/ingredient_parser.dart` | No change |

---

## Out of Scope / Future

- Showing which specific recipe ingredients matched (expandable card detail)
- Synonym matching (e.g. "garlic" matching "garlic powder")
- Manual ingredient text input as alternative to voice
