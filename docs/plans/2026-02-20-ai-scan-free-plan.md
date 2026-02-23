# AI Scan Free Plan Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the Cloud Function call in `FirebaseService.analyzeImage()` with a direct Google Cloud Vision REST API call so scan works on the Firebase Spark (free) plan.

**Architecture:** `analyzeImage()` now POSTs to `https://vision.googleapis.com/v1/images:annotate?key={API_KEY}` directly via Dio. A new `_filterLabels()` Dart method replicates the TypeScript filter logic (score ≥ 0.65, non-food blocklist). Firebase ID token auth is removed — no longer needed. The scan screen, providers, routes, and `functions/` directory are untouched.

**Tech Stack:** Flutter 3.x, Dart, `dio` package (already in pubspec.yaml), Google Cloud Vision REST API v1, `dart:convert` base64

**Design doc:** `docs/plans/2026-02-20-ai-scan-free-plan-design.md`

---

## Prerequisites (one-time, do before Task 1)

1. **Enable Cloud Vision API** for project `smartchefai-344c5`:
   ```
   https://console.cloud.google.com/apis/library/vision.googleapis.com?project=smartchefai-344c5
   ```
   Click **Enable**.

2. **Create an API key**:
   ```
   https://console.cloud.google.com/apis/credentials?project=smartchefai-344c5
   ```
   Click **Create Credentials → API key**. Copy the key.

3. **Restrict the key** (important — prevents abuse if key is extracted from APK):
   - Click the key → **Application restrictions → Android apps**
   - Add: Package name `com.example.smartchefai`
   - Add your debug SHA-1 (run `cd android && ./gradlew signingReport` to get it)

4. Have the API key ready to paste into the code in Task 1.

---

## Task 1: Replace analyzeImage() with direct Vision REST API call

**Files:**
- Modify: `lib/services/firebase_service.dart` (the `analyzeIngredients` section around line 100)

The existing `analyzeImage()` method calls a Cloud Function that requires Firebase Blaze plan. We are replacing it with a direct call to the Google Cloud Vision REST API.

**Step 1: Read the current implementation**

Open `lib/services/firebase_service.dart`. Find the `// ==================== AI IMAGE ANALYSIS ====================` section (around line 100). It currently has:
- `_analyzeFunctionUrl` constant
- `analyzeImage(XFile imageFile)` method that POSTs to the Cloud Function with a Firebase ID token

**Step 2: Replace the AI IMAGE ANALYSIS section**

Replace the entire section from `// ==================== AI IMAGE ANALYSIS ====================` up to (but not including) `// ==================== AUTHENTICATION ====================` with the following:

```dart
// ==================== AI IMAGE ANALYSIS ====================

// Google Cloud Vision REST API key.
// IMPORTANT: Restrict this key in Cloud Console:
// APIs & Services → Credentials → key → Application restrictions → Android apps
// Add package: com.example.smartchefai + your debug/release SHA-1 fingerprint.
static const String _visionApiKey = 'YOUR_API_KEY_HERE';

static const String _visionApiUrl =
    'https://vision.googleapis.com/v1/images:annotate';

static const Set<String> _nonFoodBlocklist = {
  'Kitchen', 'Tableware', 'Room', 'Table', 'Countertop',
  'Wood', 'Dish', 'Plate', 'Bowl', 'Cutlery', 'Furniture',
  'Interior design', 'Hardwood', 'Wall', 'Floor', 'Ceiling',
  'Light', 'Lighting', 'Textile', 'Shelf',
};

/// Analyze an image for food ingredients using Google Cloud Vision.
///
/// Returns detected ingredients sorted by confidence descending.
/// Throws on network error or invalid API key.
Future<List<DetectedIngredient>> analyzeImage(XFile imageFile) async {
  final bytes = await imageFile.readAsBytes();
  final base64Image = base64Encode(bytes);

  final response = await _dio.post<Map<String, dynamic>>(
    _visionApiUrl,
    queryParameters: {'key': _visionApiKey},
    data: {
      'requests': [
        {
          'image': {'content': base64Image},
          'features': [
            {'type': 'LABEL_DETECTION', 'maxResults': 20}
          ],
        }
      ]
    },
    options: Options(receiveTimeout: const Duration(seconds: 30)),
  );

  if (response.data == null) {
    throw Exception('Empty response from Vision API');
  }

  final responses =
      response.data!['responses'] as List<dynamic>? ?? [];
  if (responses.isEmpty) return [];

  final labels =
      (responses.first as Map<String, dynamic>)['labelAnnotations']
          as List<dynamic>? ??
          [];

  return _filterLabels(labels);
}

List<DetectedIngredient> _filterLabels(List<dynamic> labels) {
  final filtered = labels
      .map((l) => l as Map<String, dynamic>)
      .where(
          (l) => (l['score'] as num? ?? 0).toDouble() >= 0.65)
      .where((l) =>
          !_nonFoodBlocklist
              .contains(l['description'] as String? ?? ''))
      .map((l) => DetectedIngredient(
            name: l['description'] as String,
            confidence: (l['score'] as num).toDouble(),
            bbox: BoundingBox(x1: 0, y1: 0, x2: 0, y2: 0),
          ))
      .toList();
  filtered.sort((a, b) => b.confidence.compareTo(a.confidence));
  return filtered;
}

```

**Step 3: Paste your API key**

Replace `'YOUR_API_KEY_HERE'` with the actual API key you created in Prerequisites step 2.

**Step 4: Verify the file compiles**

```bash
flutter analyze lib/services/firebase_service.dart
```

Expected: `No issues found!`

If you see `XFile is not defined` — the import `package:image_picker/image_picker.dart` should already be there (added in the previous session). If missing, add it after the other imports.

**Step 5: Run full lib analysis**

```bash
flutter analyze lib/
```

Expected: `No issues found!`

**Step 6: Commit**

```bash
git add lib/services/firebase_service.dart
git commit -m "feat(scan): replace Cloud Function call with direct Vision REST API"
```

---

## Task 2: Smoke test the change

**Purpose:** Verify the Vision API call works end-to-end before considering this done.

**Step 1: Run the app**

```bash
flutter run
```

**Step 2: Sign in and open scan screen**

Log in, tap the camera icon in the bottom nav.

**Step 3: Pick a food photo from gallery**

Choose a photo with clearly visible food (vegetables, fruit, a meal).

Expected:
- "Analyzing ingredients..." overlay appears
- After 3–8 seconds, ingredient chips appear with real food names (NOT "Tomatoes, Onion, Garlic, Bell Pepper, Olive Oil, Basil")
- If the API key is invalid/missing: SnackBar "Analysis failed: ..."
- If no food detected: SnackBar "No ingredients detected. Try a clearer photo."

**Step 4: Test "Find Recipes"**

Tap Find Recipes — horizontal scroll of recipe cards should appear inline.

**Step 5: Confirm it's not the old mock**

The old mock always returned exactly these 6: `Tomatoes, Onion, Garlic, Bell Pepper, Olive Oil, Basil`. If you see different names (or fewer, or more), the real API is working.

---

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `Analysis failed: 400` | API key not yet enabled for Vision API | Enable Vision API in Cloud Console |
| `Analysis failed: 403` | API key restriction mismatch | Check package name + SHA-1 match exactly, or temporarily remove restrictions to test |
| `Analysis failed: Connection error` | No internet | Check device connectivity |
| Chips appear but all say "Food" or "Ingredient" | Normal — Vision gives category labels for ambiguous images | Try a photo with clearly identifiable individual ingredients |
| App builds but `flutter analyze` shows `_visionApiKey` unused warning | You left `YOUR_API_KEY_HERE` as the value | Paste the real key |
