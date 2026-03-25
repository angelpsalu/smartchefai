# Voice Search & Ingredient Matching Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the voice input overlay to a polished full-screen experience with per-mode visuals, and replace the fuzzy API-based ingredient matching with strict offline tiered matching.

**Architecture:** Four changes in dependency order — (1) rewrite `FirebaseService.searchByIngredients` to local tiered matching returning Dart 3 records; (2) update `RecipeProvider.searchByIngredients` to match new signature; (3) rewrite `voice_search_overlay.dart` as full-screen modal with 4-state machine and `VoiceOverlayMode` enum; (4) update `scan_screen.dart` to pass mode, use new result type, and render vertical list with match badges.

**Tech Stack:** Flutter, Provider (ChangeNotifier), `speech_to_text`, Dart 3 anonymous records, `showGeneralDialog`, `AnimationController`, `CustomPainter`, `flutter_test`

**Spec:** `docs/superpowers/specs/2026-03-23-voice-ingredient-redesign.md`

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `lib/services/firebase_service.dart` | Modify | Replace `searchByIngredients` with local tiered filter |
| `lib/providers/firebase_providers.dart` | Modify | Update `searchByIngredients` return type |
| `lib/shared/widgets/voice_search_overlay.dart` | Rewrite | Full-screen modal, 4-state machine, mode enum, real-time chips |
| `lib/features/scan/scan_screen.dart` | Modify | Mode param, new state vars, vertical list, match badge, header |
| `test/services/ingredient_matching_test.dart` | Create | Unit tests for the matching algorithm |

---

## Task 1: Rewrite `searchByIngredients` in FirebaseService (TDD)

**Files:**
- Create: `test/services/ingredient_matching_test.dart`
- Modify: `lib/services/firebase_service.dart` (lines 582–678)

---

- [ ] **Step 1.1: Create the test file**

```dart
// test/services/ingredient_matching_test.dart
//
// Tests the matching algorithm in isolation.
// Mirrors the logic in FirebaseService.searchByIngredients so we can verify
// it before touching the service.

import 'package:flutter_test/flutter_test.dart';
import 'package:smartchefai/models/models.dart';

// ── Standalone copy of the algorithm under test ─────────────────────────────
//
// Keep this in sync with FirebaseService.searchByIngredients.
// It's here so we can test pure logic without initialising Firebase.

List<({Recipe recipe, int matchCount})> filterByIngredients(
  List<Recipe> recipes,
  List<String> ingredients,
) {
  if (ingredients.isEmpty) return [];
  final n = ingredients.length;
  final threshold = (n / 2).ceil();
  final lower = ingredients.map((i) => i.toLowerCase()).toList();

  final results = <({Recipe recipe, int matchCount})>[];
  for (final recipe in recipes) {
    final count = lower
        .where((term) =>
            recipe.ingredients.any((i) => i.toLowerCase().contains(term)))
        .length;
    if (count >= threshold) {
      results.add((recipe: recipe, matchCount: count));
    }
  }
  results.sort((a, b) => b.matchCount.compareTo(a.matchCount));
  return results;
}

// ── Test helpers ─────────────────────────────────────────────────────────────

Recipe makeRecipe(String id, List<String> ingredients) => Recipe(
      id: id,
      name: 'Test $id',
      ingredients: ingredients,
      steps: const [],
      prepTime: 10,
      cookTime: 10,
      difficulty: 'Easy',
      cuisine: 'Test',
      dietaryTags: const [],
      nutrition: const Nutrition(
        calories: 100,
        protein: '10g',
        carbs: '10g',
        fat: '5g',
        fiber: '2g',
      ),
      servings: 4,
      imageUrl: '',
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  final chickenRice = makeRecipe('r1', [
    '500g chicken breast',
    '2 cups rice',
    '1 onion',
  ]);
  final chickenOnly = makeRecipe('r2', [
    '600g chicken thighs',
    '2 garlic cloves',
  ]);
  final riceOnly = makeRecipe('r3', ['1 cup rice', '200ml coconut milk']);
  final beef = makeRecipe('r4', ['500g beef mince', '1 onion', '2 tomatoes']);

  group('filterByIngredients', () {
    test('empty ingredient list returns empty', () {
      expect(filterByIngredients([chickenRice], []), isEmpty);
    });

    test('empty recipe list returns empty', () {
      expect(filterByIngredients([], ['chicken']), isEmpty);
    });

    test('tier 1 — all ingredients present — included', () {
      final results = filterByIngredients(
        [chickenRice, beef],
        ['chicken', 'rice'],
      );
      expect(results.length, 1);
      expect(results.first.recipe.id, 'r1');
      expect(results.first.matchCount, 2);
    });

    test('tier 2 — majority present — included', () {
      // 3 ingredients → threshold = ceil(3/2) = 2
      // r1 matches chicken + rice = 2 ✓
      // r2 matches chicken + garlic = 2 ✓
      final results = filterByIngredients(
        [chickenRice, chickenOnly],
        ['chicken', 'rice', 'garlic'],
      );
      expect(results.length, 2);
    });

    test('below threshold — excluded', () {
      // 4 ingredients → threshold = 2; chickenOnly only matches chicken = 1
      final results = filterByIngredients(
        [chickenOnly],
        ['chicken', 'rice', 'tomato', 'beef'],
      );
      expect(results, isEmpty);
    });

    test('results sorted descending by matchCount', () {
      // r1: chicken+rice = 2, r2: chicken only = 1
      final results = filterByIngredients(
        [chickenOnly, chickenRice], // r2 listed first intentionally
        ['chicken', 'rice'],
      );
      expect(results.first.recipe.id, 'r1'); // 2 matches first
      expect(results.last.recipe.id, 'r2');  // 1 match second
    });

    test('case-insensitive matching', () {
      final results = filterByIngredients(
        [chickenRice],
        ['CHICKEN', 'RICE'],
      );
      expect(results.length, 1);
    });

    test('single ingredient — threshold is 1 — any match included', () {
      final results = filterByIngredients(
        [chickenRice, beef],
        ['chicken'],
      );
      expect(results.length, 1);
      expect(results.first.recipe.id, 'r1');
    });

    test('substring match works — "chicken" matches "500g chicken breast"', () {
      final recipe = makeRecipe('r5', ['500g chicken breast']);
      final results = filterByIngredients([recipe], ['chicken']);
      expect(results.length, 1);
    });

    test('matchCount field is accurate', () {
      final results = filterByIngredients([chickenRice], ['chicken', 'rice', 'onion']);
      expect(results.first.matchCount, 3);
    });
  });
}
```

- [ ] **Step 1.2: Run the tests — verify they FAIL (function not yet in service)**

```bash
flutter test test/services/ingredient_matching_test.dart --reporter expanded
```

Expected: All tests pass immediately — because `filterByIngredients` is defined directly in the test file. This confirms the algorithm is correct before we transplant it into the service. If any test fails, fix the algorithm in the test before proceeding.

- [ ] **Step 1.3: Replace `searchByIngredients` in `firebase_service.dart`**

Find the block from line 582 (`/// Search recipes by ingredients`) to line 678 (`return results;`) and replace the entire method:

```dart
  /// Search recipes by ingredients using strict local matching.
  ///
  /// Tier 1 (all N ingredients match) appears before Tier 2
  /// (>= ceil(N/2) ingredients match). Sorted descending by match count.
  /// Runs offline against [_cachedRecipes] — no API calls.
  Future<List<({Recipe recipe, int matchCount})>> searchByIngredients(
    List<String> ingredients,
  ) async {
    if (ingredients.isEmpty) return [];

    // Ensure cache is loaded.
    if (_cachedRecipes.isEmpty) {
      await getAllRecipes();
    }

    final n = ingredients.length;
    final threshold = (n / 2).ceil();
    final lower = ingredients.map((i) => i.toLowerCase()).toList();

    final results = <({Recipe recipe, int matchCount})>[];
    for (final recipe in _cachedRecipes) {
      final count = lower
          .where((term) =>
              recipe.ingredients.any((i) => i.toLowerCase().contains(term)))
          .length;
      if (count >= threshold) {
        results.add((recipe: recipe, matchCount: count));
      }
    }
    results.sort((a, b) => b.matchCount.compareTo(a.matchCount));
    return results;
  }
```

- [ ] **Step 1.4: Run the app — verify it compiles**

```bash
flutter analyze lib/services/firebase_service.dart
```

Expected: No errors on that file (the provider will have a type error — fix in Task 2).

- [ ] **Step 1.5: Commit**

```bash
git add test/services/ingredient_matching_test.dart lib/services/firebase_service.dart
git commit -m "feat: rewrite searchByIngredients — local tiered matching, no API calls"
```

---

## Task 2: Update `RecipeProvider.searchByIngredients`

**Files:**
- Modify: `lib/providers/firebase_providers.dart` (lines 152–169)

---

- [ ] **Step 2.1: Replace the method in `firebase_providers.dart`**

Find the existing `searchByIngredients` method (lines ~152–169) and replace it:

```dart
  /// Search recipes by ingredients.
  ///
  /// Returns records with match counts. Updates [_recipes] with the matched
  /// recipes for any future provider consumers (scan_screen uses the service
  /// directly and ignores this).
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
      return [];
    }
  }
```

- [ ] **Step 2.2: Verify no compile errors**

```bash
flutter analyze lib/providers/firebase_providers.dart
```

Expected: No errors.

- [ ] **Step 2.3: Commit**

```bash
git add lib/providers/firebase_providers.dart
git commit -m "feat: update RecipeProvider.searchByIngredients to match new service return type"
```

---

## Task 3: Rewrite `voice_search_overlay.dart`

**Files:**
- Rewrite: `lib/shared/widgets/voice_search_overlay.dart`

The public API (`showVoiceSearchOverlay`, `VoiceSearchService` parameter) is preserved. The only addition is the optional `mode` parameter.

---

- [ ] **Step 3.1: Replace the entire file contents**

```dart
import 'package:flutter/material.dart';
import '../../app/theme/theme.dart';
import '../../services/voice_search_service.dart';
import '../../utils/ingredient_parser.dart';

/// Determines which voice flow the overlay is serving.
enum VoiceOverlayMode { recipeSearch, ingredientInput }

/// Internal state machine for the voice overlay.
enum _VoiceState { listening, result, timeout, error }

/// Show the full-screen voice input overlay.
///
/// Returns the spoken string on Done/Search, or [null] on Cancel/back/error.
///
/// [mode] controls hint text, accent colour, done button label, and whether
/// real-time ingredient chips are shown below the visualisation.
Future<String?> showVoiceSearchOverlay({
  required BuildContext context,
  required VoiceSearchService service,
  VoiceOverlayMode mode = VoiceOverlayMode.recipeSearch,
}) {
  return showGeneralDialog<String>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, __, ___) =>
        _VoiceOverlayPage(service: service, mode: mode),
    transitionBuilder: (_, animation, __, child) => FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: child,
      ),
    ),
  );
}

// ── Overlay page ──────────────────────────────────────────────────────────────

class _VoiceOverlayPage extends StatefulWidget {
  final VoiceSearchService service;
  final VoiceOverlayMode mode;

  const _VoiceOverlayPage({required this.service, required this.mode});

  @override
  State<_VoiceOverlayPage> createState() => _VoiceOverlayPageState();
}

class _VoiceOverlayPageState extends State<_VoiceOverlayPage>
    with TickerProviderStateMixin {
  // Ring ripple controllers (staggered start)
  late final AnimationController _ring1;
  late final AnimationController _ring2;
  late final AnimationController _ring3;

  // Mic "breathe" scale
  late final AnimationController _micPulse;
  late final Animation<double> _micScale;

  // Ring fade-out when entering result/timeout/error
  late final AnimationController _ringFade;
  late final Animation<double> _ringOpacity;

  _VoiceState _voiceState = _VoiceState.listening;
  String _partialWords = '';
  String? _errorMessage;

  // Ingredient chips (ingredientInput mode only)
  List<String> _chips = [];
  Set<String> _newChips = {}; // chips that should animate this render pass

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startListening();
  }

  void _setupAnimations() {
    _ring1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _ring2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _ring2.repeat();
    });

    _ring3 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _ring3.repeat();
    });

    _micPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _micScale = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _micPulse, curve: Curves.easeInOut),
    );

    _ringFade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: 1.0, // fully visible initially
    );
    _ringOpacity = _ringFade.drive(
      Tween<double>(begin: 1.0, end: 0.0),
    );
  }

  Future<void> _startListening() async {
    setState(() {
      _voiceState = _VoiceState.listening;
      _partialWords = '';
      _errorMessage = null;
      _chips = [];
      _newChips = {};
    });

    // Reset ring fade and restart animations.
    _ringFade.value = 1.0;
    if (!_ring1.isAnimating) _ring1.repeat();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted && !_ring2.isAnimating) _ring2.repeat();
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted && !_ring3.isAnimating) _ring3.repeat();
    });
    if (!_micPulse.isAnimating) _micPulse.repeat(reverse: true);

    await widget.service.startListening(
      onPartialResult: (words) {
        if (!mounted) return;
        setState(() {
          _partialWords = words;
          if (widget.mode == VoiceOverlayMode.ingredientInput) {
            final parsed = IngredientParser.parse(words);
            _newChips = Set<String>.from(parsed).difference(Set<String>.from(_chips));
            _chips = parsed;
          }
        });
      },
      onResult: (words) {
        if (!mounted) return;
        setState(() {
          _partialWords = words;
          _voiceState = _VoiceState.result;
        });
        _stopAnimations();
      },
      onError: (message) {
        if (!mounted) return;
        setState(() {
          _voiceState = _VoiceState.error;
          _errorMessage = message;
        });
        _stopAnimations();
      },
      onDone: () {
        if (!mounted) return;
        // onResult fires before onDone for a successful capture.
        // If we're still in listening state here, it means silence timeout.
        if (_voiceState == _VoiceState.listening) {
          setState(() {
            _voiceState = _partialWords.isEmpty
                ? _VoiceState.timeout
                : _VoiceState.result;
          });
          _stopAnimations();
        }
      },
    );
  }

  void _stopAnimations() {
    _ring1.stop();
    _ring2.stop();
    _ring3.stop();
    _micPulse.stop();
    _ringFade.forward(); // 400ms fade-out
  }

  Future<void> _confirm() async {
    await widget.service.stopListening();
    if (mounted) Navigator.of(context).pop(_partialWords);
  }

  Future<void> _cancel() async {
    await widget.service.cancel();
    if (mounted) Navigator.of(context).pop(null);
  }

  @override
  void dispose() {
    _ring1.dispose();
    _ring2.dispose();
    _ring3.dispose();
    _micPulse.dispose();
    _ringFade.dispose();
    super.dispose();
  }

  // ── Mode-specific values ────────────────────────────────────────────────────

  Color get _accentColor => widget.mode == VoiceOverlayMode.recipeSearch
      ? AppColors.primaryOrange
      : AppColors.info;

  String get _hintText => widget.mode == VoiceOverlayMode.recipeSearch
      ? 'Say a recipe name…'
      : 'Say your ingredients, e.g. chicken, rice, onions';

  String get _doneLabel => widget.mode == VoiceOverlayMode.recipeSearch
      ? 'Search'
      : 'Use These Ingredients';

  String get _statusTitle {
    switch (_voiceState) {
      case _VoiceState.listening:
        return 'Listening…';
      case _VoiceState.result:
        return 'Got it!';
      case _VoiceState.timeout:
        return "Didn't catch that";
      case _VoiceState.error:
        return 'Mic unavailable';
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          color: const Color(0xFF0D0D0D).withValues(alpha: 0.95),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cancel button — always top-right
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, right: 8),
                    child: IconButton(
                      onPressed: _cancel,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                        size: 28,
                      ),
                    ),
                  ),
                ),

                // Centre content
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Status title
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          _statusTitle,
                          key: ValueKey(_voiceState),
                          style: textTheme.headlineSmall?.copyWith(
                            color: _voiceState == _VoiceState.error
                                ? Colors.redAccent
                                : Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Hint text — fades out when words arrive
                      AnimatedOpacity(
                        opacity: _partialWords.isEmpty ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            _hintText,
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium
                                ?.copyWith(color: Colors.white54),
                          ),
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Ripple rings + mic button
                      FadeTransition(
                        opacity: _ringOpacity,
                        child: SizedBox(
                          width: 300,
                          height: 300,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (_voiceState == _VoiceState.listening) ...[
                                _WaveRing(
                                  controller: _ring3,
                                  color: _accentColor,
                                  maxRadius: 144,
                                ),
                                _WaveRing(
                                  controller: _ring2,
                                  color: _accentColor,
                                  maxRadius: 112,
                                ),
                                _WaveRing(
                                  controller: _ring1,
                                  color: _accentColor,
                                  maxRadius: 80,
                                ),
                              ],
                              // Mic button
                              ScaleTransition(
                                scale: _voiceState == _VoiceState.listening
                                    ? _micScale
                                    : const AlwaysStoppedAnimation(1.0),
                                child: Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: _voiceState == _VoiceState.error
                                          ? [Colors.redAccent, Colors.red]
                                          : [
                                              _accentColor,
                                              _accentColor.withValues(alpha: 0.75),
                                            ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_voiceState == _VoiceState.error
                                                ? Colors.redAccent
                                                : _accentColor)
                                            .withValues(alpha: 0.4),
                                        blurRadius: 24,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _voiceState == _VoiceState.error
                                        ? Icons.mic_off_rounded
                                        : _voiceState == _VoiceState.listening
                                            ? Icons.mic_rounded
                                            : Icons.mic_none_rounded,
                                    color: Colors.white,
                                    size: 44,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Partial words
                      if (_partialWords.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            child: Text(
                              '"$_partialWords"',
                              key: ValueKey(_partialWords),
                              textAlign: TextAlign.center,
                              style: textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                      // Real-time ingredient chips (ingredientInput mode only)
                      if (widget.mode == VoiceOverlayMode.ingredientInput &&
                          _chips.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: _chips
                                .map((chip) => _AnimatedChip(
                                      key: ValueKey(chip),
                                      label: chip,
                                      color: _accentColor,
                                      animate: _newChips.contains(chip),
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Action buttons
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: _buildButtons(textTheme),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtons(TextTheme textTheme) {
    switch (_voiceState) {
      case _VoiceState.listening:
        return const SizedBox.shrink();

      case _VoiceState.result:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.icon(
              onPressed: _confirm,
              icon: const Icon(Icons.check_rounded, size: 20),
              label: Text(_doneLabel),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: _accentColor,
                textStyle: textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _startListening,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white30),
              ),
            ),
          ],
        );

      case _VoiceState.timeout:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.icon(
              onPressed: _startListening,
              icon: const Icon(Icons.mic_rounded, size: 20),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: _accentColor,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _cancel,
              style:
                  TextButton.styleFrom(foregroundColor: Colors.white54),
              child: const Text('Cancel'),
            ),
          ],
        );

      case _VoiceState.error:
        return FilledButton.icon(
          onPressed: _cancel,
          icon: const Icon(Icons.close_rounded, size: 20),
          label: const Text('Cancel'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            backgroundColor: Colors.redAccent,
          ),
        );
    }
  }
}

// ── Animated chip ─────────────────────────────────────────────────────────────

/// A chip that scales + fades in on first appearance.
///
/// Pass [animate: true] only for newly added chips (diff against previous list).
/// Existing chips should receive [animate: false] — Flutter preserves their
/// [State] via [ValueKey], so their controller stays at 1.0.
class _AnimatedChip extends StatefulWidget {
  final String label;
  final Color color;
  final bool animate;

  const _AnimatedChip({
    super.key,
    required this.label,
    required this.color,
    required this.animate,
  });

  @override
  State<_AnimatedChip> createState() => _AnimatedChipState();
}

class _AnimatedChipState extends State<_AnimatedChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: widget.animate ? 0.0 : 1.0,
    );
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _opacity = _ctrl.drive(CurveTween(curve: Curves.easeIn));
    if (widget.animate) _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: Chip(
          label: Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: widget.color.withValues(alpha: 0.8),
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
      ),
    );
  }
}

// ── Wave ring ─────────────────────────────────────────────────────────────────

class _WaveRing extends StatelessWidget {
  final AnimationController controller;
  final Color color;
  final double maxRadius;

  const _WaveRing({
    required this.controller,
    required this.color,
    required this.maxRadius,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => CustomPaint(
        painter: _RingPainter(
          progress: controller.value,
          color: color,
          maxRadius: maxRadius,
        ),
        size: Size(maxRadius * 2, maxRadius * 2),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double maxRadius;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.maxRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = progress * maxRadius;
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = color.withValues(alpha: opacity * 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      radius,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
```

- [ ] **Step 3.2: Verify no compile errors**

```bash
flutter analyze lib/shared/widgets/voice_search_overlay.dart
```

Expected: No errors.

- [ ] **Step 3.3: Run the app and test the search screen voice flow**

```bash
flutter run --dart-define-from-file=dart_defines/dev.json
```

Manual test:
1. Open Search screen
2. Tap the mic button
3. Verify: full-screen dark overlay appears with slide-up animation, orange accent, "Say a recipe name…" hint
4. Speak something — verify partial words appear, hint fades
5. Wait for auto-stop — verify "Got it!" state, Done/Try Again buttons appear, rings fade out
6. Tap Done — overlay closes, search is performed
7. Tap mic again → speak → tap Try Again → verify words clear and listening restarts
8. Tap mic → tap X → verify returns to search screen with no search performed

- [ ] **Step 3.4: Commit**

```bash
git add lib/shared/widgets/voice_search_overlay.dart
git commit -m "feat: rewrite voice overlay — full-screen modal, 4-state machine, VoiceOverlayMode enum"
```

---

## Task 4: Update `scan_screen.dart`

**Files:**
- Modify: `lib/features/scan/scan_screen.dart`

Changes: pass `mode:` to overlay, remove `_isListeningIngredients`, update result state vars, update `_searchRecipes`, rewrite results section (vertical list + badges + header + empty state), reset `_hasSearched` on clear.

---

- [ ] **Step 4.1: Add import and update state variables**

At the top of the file, add the `VoiceOverlayMode` import (it's in `voice_search_overlay.dart`, already imported via `widgets.dart` barrel — verify `widgets.dart` exports `voice_search_overlay.dart`):

Check `lib/shared/widgets/widgets.dart` for:
```dart
export 'voice_search_overlay.dart';
```

If missing, add that export line.

Then in `_ScanScreenState`, replace:
```dart
bool _isListeningIngredients = false;
// ...
List<Recipe> _scanRecipes = [];
```

With:
```dart
List<({Recipe recipe, int matchCount})> _scanRecipes = [];
int _totalRequested = 0;
bool _hasSearched = false;
```

- [ ] **Step 4.2: Update `_onVoiceInput`**

Remove the early-cancel guard and add `mode:` parameter. Replace the entire method:

```dart
Future<void> _onVoiceInput() async {
  final result = await showVoiceSearchOverlay(
    context: context,
    service: _voiceService,
    mode: VoiceOverlayMode.ingredientInput,
  );

  if (!mounted) return;

  if (result != null && result.isNotEmpty) {
    final parsed = IngredientParser.parse(result);

    if (parsed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Could not detect ingredients. Try saying them separated by commas.'),
        ),
      );
      return;
    }

    setState(() {
      _detectedIngredients = parsed;
      _selectedImage = null;
      _inputSource = 'voice';
      _scanRecipes = [];
      _hasSearched = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Detected ${parsed.length} ingredient${parsed.length == 1 ? '' : 's'}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
```

- [ ] **Step 4.3: Update `_searchRecipes`**

Replace the entire method:

```dart
Future<void> _searchRecipes() async {
  if (_detectedIngredients.isEmpty) return;

  // Set _totalRequested before await so it reflects post-removal chip count.
  final requested = _detectedIngredients.length;
  setState(() {
    _isSearching = true;
    _totalRequested = requested;
  });

  try {
    final results =
        await FirebaseService().searchByIngredients(_detectedIngredients);
    if (!mounted) return;
    setState(() {
      _scanRecipes = results;
      _hasSearched = true;
    });
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Could not find matching recipes. Please try again.')),
    );
  } finally {
    if (mounted) setState(() => _isSearching = false);
  }
}
```

- [ ] **Step 4.4: Update the "Scan Again / Try Again" clear action**

Find the `OutlinedButton.icon` onPressed that clears state (around line 392) and add `_hasSearched = false` and `_totalRequested = 0`:

```dart
onPressed: () {
  setState(() {
    _selectedImage = null;
    _detectedIngredients = [];
    _scanRecipes = [];
    _inputSource = '';
    _hasSearched = false;
    _totalRequested = 0;
  });
},
```

- [ ] **Step 4.5: Replace the results section (inline recipe list)**

Find the `if (_scanRecipes.isNotEmpty)` block (roughly lines 422–472) and replace it entirely. Also add the empty state just before it:

```dart
// Empty state — only shown after a completed search with zero results
if (_hasSearched && _scanRecipes.isEmpty && !_isSearching) ...[
  const Gap.xl(),
  EmptyState(
    icon: Icons.search_off,
    title: 'No recipes found',
    subtitle: 'Try removing an ingredient or scanning again.',
  ),
],

// Recipe results — vertical list with match badges
if (_scanRecipes.isNotEmpty) ...[
  const Gap.xl(),
  Row(
    children: [
      Icon(Icons.restaurant_menu, color: colorScheme.primary),
      const HGap.sm(),
      Text(
        _buildResultsHeader(),
        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    ],
  ),
  const Gap.md(),
  ListView.separated(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: _scanRecipes.length,
    separatorBuilder: (_, __) => const Gap.md(),
    itemBuilder: (context, index) {
      final match = _scanRecipes[index];
      return Stack(
        children: [
          RecipeCard(
            id: match.recipe.id,
            title: match.recipe.name,
            imageUrl: match.recipe.imageUrl,
            cookTime:
                '${match.recipe.prepTime + match.recipe.cookTime} min',
            difficulty: match.recipe.difficulty,
            rating: match.recipe.rating,
            isFavorite: context
                .watch<RecipeProvider>()
                .isFavorite(match.recipe.id),
            onTap: () => context.push(
              '/recipe/${match.recipe.id}',
              extra: match.recipe,
            ),
            onFavoriteTap: () => context
                .read<RecipeProvider>()
                .toggleFavorite(match.recipe.id),
          ),
          Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: _MatchBadge(
              matchCount: match.matchCount,
              totalRequested: _totalRequested,
            ),
          ),
        ],
      );
    },
  ),
  const Gap.lg(),
],
```

- [ ] **Step 4.6: Add `_buildResultsHeader()` helper and `_MatchBadge` widget**

Add these at the bottom of `_ScanScreenState` (before the closing `}`):

```dart
String _buildResultsHeader() {
  final exactCount =
      _scanRecipes.where((m) => m.matchCount == _totalRequested).length;
  final partialCount = _scanRecipes.length - exactCount;

  if (exactCount > 0 && partialCount > 0) {
    return '$exactCount exact · $partialCount partial';
  } else if (exactCount > 0) {
    return '$exactCount recipe${exactCount == 1 ? '' : 's'} found';
  } else {
    return '$partialCount partial match${partialCount == 1 ? '' : 'es'}';
  }
}
```

And add `_MatchBadge` as a new private widget class below `_ScanOption` (at the bottom of the file):

```dart
class _MatchBadge extends StatelessWidget {
  final int matchCount;
  final int totalRequested;

  const _MatchBadge({
    required this.matchCount,
    required this.totalRequested,
  });

  @override
  Widget build(BuildContext context) {
    final isExact = matchCount == totalRequested;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isExact
            ? AppColors.primaryOrange
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isExact ? 'All $matchCount matched' : '$matchCount of $totalRequested',
        style: TextStyle(
          color: isExact ? Colors.white : colorScheme.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
```

- [ ] **Step 4.7: Verify no compile errors**

```bash
flutter analyze lib/features/scan/scan_screen.dart
```

Expected: No errors.

- [ ] **Step 4.8: Run the full app and test the ingredient flow**

```bash
flutter run --dart-define-from-file=dart_defines/dev.json
```

Manual test — ingredient voice flow:
1. Open Scan screen (tap camera icon in bottom nav or search bar)
2. Tap "Voice Input"
3. Verify: full-screen overlay with **blue** accent, "Say your ingredients…" hint
4. Say "chicken and rice" — verify two chips appear with staggered animation
5. Tap "Use These Ingredients" — overlay closes, chips shown on scan screen
6. Tap "Find Recipes"
7. Verify: vertical list of recipes with orange "All 2 matched" or grey "1 of 2" badges
8. Verify: header shows correct count (e.g. "3 exact · 1 partial")
9. Tap "Scan Again" — verify results clear, `_hasSearched` resets, no empty state flashes

Manual test — empty state:
1. Say an unusual ingredient (e.g. "durian") that matches nothing
2. Tap "Find Recipes"
3. Verify: EmptyState widget shown ("No recipes found")

- [ ] **Step 4.9: Commit**

```bash
git add lib/features/scan/scan_screen.dart lib/shared/widgets/widgets.dart
git commit -m "feat: update scan screen — ingredient overlay mode, vertical results, match badges"
```

---

## Task 5: Final integration check

- [ ] **Step 5.1: Run full test suite**

```bash
flutter test
```

Expected: All tests pass (ingredient matching tests from Task 1).

- [ ] **Step 5.2: Run static analysis on all changed files**

```bash
flutter analyze lib/services/firebase_service.dart lib/providers/firebase_providers.dart lib/shared/widgets/voice_search_overlay.dart lib/features/scan/scan_screen.dart
```

Expected: No errors or warnings.

- [ ] **Step 5.3: Smoke test the recipe name search flow (regression check)**

Manual test:
1. From home screen, tap the search bar text area (not the mic) → goes to Search screen
2. From Search screen, tap the mic button
3. Verify: full-screen overlay with **orange** accent, "Say a recipe name…" hint, no chips
4. Speak a recipe name (e.g. "pasta")
5. Verify: words appear, "Got it!" on stop, tap "Search" → overlay closes, search runs

- [ ] **Step 5.4: Final commit if any last fixes were needed**

```bash
git add -p  # stage only what changed
git commit -m "fix: address any issues found during integration smoke test"
```
