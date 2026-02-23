# AI Ingredient Scan — Design Document

> Feature: Replace mock ingredient detection with real Google Cloud Vision AI
> Phase: 2.1
> Date: 2026-02-20
> Status: Approved — ready for implementation

---

## Problem

The scan screen (`lib/features/scan/scan_screen.dart`) has a fully-built UI — camera picker, ingredient chips, "Find Recipes" button — but the detection is entirely fake: a 2-second `Future.delayed` followed by 6 hardcoded ingredients. After tapping "Find Recipes", the app navigates away to `/search` without passing any ingredients.

## Goal

1. Replace the fake delay with a real Google Cloud Vision API call (via a Firebase Cloud Function proxy)
2. Keep the existing editable-chip UI — the user can remove false positives before searching
3. Show matching recipe results inline in the scan screen (horizontal scroll row) instead of navigating to `/search`

---

## Architecture

```
ScanScreen
    │ XFile (camera or gallery)
    ▼
FirebaseService.analyzeImage(XFile)   [new method]
    │ base64 image + Firebase ID token
    ▼
Firebase Cloud Function: analyzeIngredients   [new function]
    │ image bytes
    ▼
Google Cloud Vision API — LABEL_DETECTION (max 20 labels)
    │ labels filtered: score ≥ 0.65, non-food blocklist removed
    ▼
List<DetectedIngredient>   [model already exists in models.dart]
    │
    ▼
ScanScreen — shows editable ingredient chips (existing UI, unchanged)
    │ user removes false positives, taps "Find Recipes"
    ▼
RecipeProvider.searchByIngredients(_detectedIngredients)   [already exists]
    │
    ▼
Inline horizontal scroll row of RecipeCards in ScanScreen   [new UI section]
    │ tap a card
    ▼
context.push('/recipe/:id', extra: recipe)   [standard navigation]
```

---

## Component 1: Firebase Cloud Function

**Name**: `analyzeIngredients`
**Type**: HTTP trigger (2nd generation)
**Reason for HTTP over Callable**: base64 of a 512×512 JPEG is ~200KB; callable functions have a 256KB limit which is too tight. HTTP functions allow up to 10MB.

### Authentication

Verify Firebase ID token from `Authorization: Bearer <token>` header on every request. Reject with 401 if missing or invalid.

### Request

```
POST https://<region>-<project-id>.cloudfunctions.net/analyzeIngredients
Authorization: Bearer <Firebase ID token>
Content-Type: application/json

{
  "imageBase64": "<base64-encoded JPEG string>"
}
```

### Processing

1. Decode base64 to image bytes
2. Call Google Cloud Vision `annotate` endpoint with `LABEL_DETECTION`, `maxResults: 20`
3. Filter response:
   - Keep labels with `score >= 0.65`
   - Remove labels in the non-food blocklist: `["Kitchen", "Tableware", "Room", "Table", "Countertop", "Wood", "Dish", "Plate", "Bowl", "Cutlery", "Furniture", "Interior design"]`
4. Return filtered list sorted by confidence descending

### Response

```json
{
  "ingredients": [
    { "name": "Tomato", "confidence": 0.94 },
    { "name": "Garlic",  "confidence": 0.87 },
    { "name": "Onion",   "confidence": 0.81 }
  ]
}
```

### Error cases

| Condition | HTTP status | Body |
|-----------|------------|------|
| Missing/invalid auth token | 401 | `{ "error": "Unauthorized" }` |
| Missing imageBase64 | 400 | `{ "error": "imageBase64 is required" }` |
| Vision API error | 500 | `{ "error": "Vision API error: <message>" }` |

### Infrastructure

- Runtime: Node.js 20
- Region: `us-central1` (same as Firestore default `nam5`)
- Timeout: 30 seconds
- Memory: 256MB
- Google Cloud Vision API must be enabled on the Firebase project

---

## Component 2: FirebaseService.analyzeImage()

**File**: `lib/services/firebase_service.dart`

New method added to the existing `FirebaseService` singleton:

```dart
Future<List<DetectedIngredient>> analyzeImage(XFile imageFile) async {
  // 1. Read image bytes
  final bytes = await imageFile.readAsBytes();

  // 2. Base64 encode
  final base64Image = base64Encode(bytes);

  // 3. Get Firebase ID token for auth
  final user = _auth.currentUser;
  if (user == null) throw Exception('Not authenticated');
  final idToken = await user.getIdToken();

  // 4. POST to Cloud Function
  final response = await _dio.post(
    'https://us-central1-smartchefai-344c5.cloudfunctions.net/analyzeIngredients',
    data: { 'imageBase64': base64Image },
    options: Options(headers: { 'Authorization': 'Bearer $idToken' }),
  );

  // 5. Parse response
  final List<dynamic> raw = response.data['ingredients'];
  return raw.map((item) => DetectedIngredient(
    name: item['name'],
    confidence: (item['confidence'] as num).toDouble(),
    bbox: BoundingBox(x1: 0, y1: 0, x2: 0, y2: 0),  // Vision labels have no bbox
  )).toList();
}
```

**Note on image compression**: `_picker.pickImage()` in `ScanScreen` already passes `maxWidth: 1024, maxHeight: 1024`. This should be reduced to `maxWidth: 512, maxHeight: 512` in the scan screen to keep base64 payload under ~200KB.

---

## Component 3: ScanScreen Changes

**File**: `lib/features/scan/scan_screen.dart`

### State additions

```dart
List<Recipe> _scanRecipes = [];
bool _isSearching = false;
```

### Change 1: Replace fake detection

Current:
```dart
// Simulate AI processing
await Future.delayed(const Duration(seconds: 2));
setState(() {
  _detectedIngredients = ['Tomatoes', 'Onion', 'Garlic', ...];
  _isProcessing = false;
});
```

Replacement:
```dart
final detected = await FirebaseService().analyzeImage(image);
if (!mounted) return;
setState(() {
  _detectedIngredients = detected.map((d) => d.name).toList();
  _isProcessing = false;
});
```

### Change 2: Fix image compression

```dart
// Change from:
maxWidth: 1024, maxHeight: 1024,
// To:
maxWidth: 512, maxHeight: 512,
```

### Change 3: Replace _searchRecipes()

Current:
```dart
void _searchRecipes() {
  if (_detectedIngredients.isEmpty) return;
  context.go('/search');
}
```

Replacement:
```dart
Future<void> _searchRecipes() async {
  if (_detectedIngredients.isEmpty) return;
  setState(() => _isSearching = true);
  await context.read<RecipeProvider>().searchByIngredients(_detectedIngredients);
  if (!mounted) return;
  setState(() {
    _scanRecipes = context.read<RecipeProvider>().recipes;
    _isSearching = false;
  });
}
```

### Change 4: Add inline results section

In the `build` method, after the ingredient chips section, add:

```dart
if (_isSearching)
  const Center(child: CircularProgressIndicator())

if (_scanRecipes.isNotEmpty) ...[
  const Gap.xl(),
  Text('${_scanRecipes.length} recipes found',
    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
  const Gap.md(),
  SizedBox(
    height: 220,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: _scanRecipes.length,
      separatorBuilder: (_, __) => const HGap.md(),
      itemBuilder: (context, index) {
        final recipe = _scanRecipes[index];
        return SizedBox(
          width: 160,
          child: RecipeCard(
            id: recipe.id,
            title: recipe.name,
            imageUrl: recipe.imageUrl,
            cookTime: '${recipe.prepTimeInt + recipe.cookTimeInt} min',
            difficulty: recipe.difficulty,
            rating: recipe.rating,
            isFavorite: context.watch<RecipeProvider>().isFavorite(recipe.id),
            onTap: () => context.push('/recipe/${recipe.id}', extra: recipe),
            onFavoriteTap: () =>
                context.read<RecipeProvider>().toggleFavorite(recipe.id),
          ),
        );
      },
    ),
  ),
]
```

---

## Files Changed

| File | Type | Change |
|------|------|--------|
| `functions/src/index.ts` (or `index.js`) | New | Cloud Function `analyzeIngredients` |
| `functions/package.json` | New | Node.js function dependencies |
| `lib/services/firebase_service.dart` | Modified | Add `analyzeImage()` method |
| `lib/features/scan/scan_screen.dart` | Modified | Real detection, inline results, fix `_searchRecipes()` |

## Files NOT Changed

- `lib/models/models.dart` — `DetectedIngredient` already exists
- `lib/providers/firebase_providers.dart` — `searchByIngredients()` already exists
- `lib/app/routes.dart` — no new routes needed
- `lib/features/search/search_screen.dart` — not used for this flow

---

## Error Handling

| Scenario | Behavior |
|----------|---------|
| User not signed in | `analyzeImage()` throws; ScanScreen shows SnackBar: "Sign in required" |
| Network error / function timeout | Dio retry (existing interceptor); if still fails, show SnackBar: "Analysis failed. Try again." |
| Vision returns 0 ingredients after filtering | Show message: "No ingredients detected. Try a clearer photo." |
| `searchByIngredients()` returns 0 recipes | Show empty state: "No recipes found for these ingredients." |

---

## Setup Steps (One-Time)

1. Enable **Google Cloud Vision API** in Google Cloud Console for project `smartchefai-344c5`
2. Create a **service account key** (or use Application Default Credentials in Cloud Functions) — Vision API calls from Cloud Functions use ADC automatically, no key needed
3. Run `firebase init functions` in the project root (Node.js 20)
4. Deploy function: `firebase deploy --only functions`

---

## Out of Scope (this phase)

- Confidence scores displayed in chip UI — chips show name only (existing `IngredientChip` widget)
- Bounding box overlays on the image — `DetectedIngredient.bbox` will be zeros (Vision label detection doesn't return bbox)
- Offline fallback for scan — requires on-device ML model (Phase 3+)
- Cost metering / rate limiting — out of scope; Google Vision free tier: 1,000 images/month

---

*Design approved: 2026-02-20 | Author: Claude Sonnet 4.6*
