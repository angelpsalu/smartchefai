# AI Ingredient Scan — Free Plan Design (Direct Cloud Vision API)

> Feature: Replace Cloud Function call with direct Cloud Vision REST API call
> Phase: 2.1 (revised)
> Date: 2026-02-20
> Status: Approved — ready for implementation

---

## Problem

The `analyzeIngredients` Cloud Function we built requires Firebase Blaze (pay-as-you-go) plan to deploy. The project is on the free Spark plan and must stay there.

## Goal

Replace `FirebaseService.analyzeImage()` — currently POSTing to the Cloud Function — with a direct call to the Google Cloud Vision REST API from Flutter. Everything else (scan screen UI, ingredient chips, inline recipe results) stays unchanged.

---

## Architecture

```
ScanScreen
    │ XFile (camera or gallery)
    ▼
FirebaseService.analyzeImage(XFile)   [updated — no longer calls Cloud Function]
    │ base64 image + API key in URL
    ▼
https://vision.googleapis.com/v1/images:annotate?key={API_KEY}
    │ LABEL_DETECTION, maxResults: 20
    ▼
_filterLabels()   [new Dart method — same logic as TypeScript ingredientFilter.ts]
    │ score >= 0.65, non-food blocklist
    ▼
List<DetectedIngredient>   [unchanged model]
    │
    ▼
ScanScreen — chips, inline results   [unchanged]
```

**Free tier**: 1,000 label detection calls/month from Google Cloud Vision.

---

## Component: Updated FirebaseService.analyzeImage()

**File**: `lib/services/firebase_service.dart`

### What changes

- Remove: Firebase ID token fetch (`user.getIdToken()`)
- Remove: POST to `_analyzeFunctionUrl` with `Authorization` header
- Add: POST to Vision REST API with `?key=` query parameter
- Add: `_filterLabels()` Dart method (replicates TypeScript `filterLabels`)
- Remove: `_analyzeFunctionUrl` constant
- Add: `_visionApiKey` constant (set by developer from Cloud Console)

### Vision API Request

```
POST https://vision.googleapis.com/v1/images:annotate?key={API_KEY}
Content-Type: application/json

{
  "requests": [
    {
      "image": { "content": "<base64-encoded JPEG>" },
      "features": [{ "type": "LABEL_DETECTION", "maxResults": 20 }]
    }
  ]
}
```

### Vision API Response

```json
{
  "responses": [
    {
      "labelAnnotations": [
        { "description": "Tomato", "score": 0.94 },
        { "description": "Garlic",  "score": 0.87 }
      ]
    }
  ]
}
```

### New Dart implementation

```dart
static const String _visionApiKey = 'YOUR_API_KEY_HERE';
static const String _visionApiUrl =
    'https://vision.googleapis.com/v1/images:annotate';

static const Set<String> _nonFoodBlocklist = {
  'Kitchen', 'Tableware', 'Room', 'Table', 'Countertop',
  'Wood', 'Dish', 'Plate', 'Bowl', 'Cutlery', 'Furniture',
  'Interior design', 'Hardwood', 'Wall', 'Floor', 'Ceiling',
  'Light', 'Lighting', 'Textile', 'Shelf',
};

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
          'features': [{'type': 'LABEL_DETECTION', 'maxResults': 20}],
        }
      ]
    },
  );

  if (response.data == null) {
    throw Exception('Empty response from Vision API');
  }

  final responses = response.data!['responses'] as List<dynamic>? ?? [];
  if (responses.isEmpty) return [];

  final labels = (responses.first as Map<String, dynamic>)['labelAnnotations']
      as List<dynamic>? ?? [];

  return _filterLabels(labels);
}

List<DetectedIngredient> _filterLabels(List<dynamic> labels) {
  return labels
      .map((l) => l as Map<String, dynamic>)
      .where((l) => (l['score'] as num? ?? 0).toDouble() >= 0.65)
      .where((l) => !_nonFoodBlocklist.contains(l['description'] as String? ?? ''))
      .map((l) => DetectedIngredient(
            name: l['description'] as String,
            confidence: (l['score'] as num).toDouble(),
            bbox: BoundingBox(x1: 0, y1: 0, x2: 0, y2: 0),
          ))
      .toList()
    ..sort((a, b) => b.confidence.compareTo(a.confidence));
}
```

### Auth note

No Firebase ID token needed — the Vision API key is passed as a URL query parameter. The auth check (`if (user == null) throw`) is **removed** since Vision API doesn't require Firebase auth.

---

## API Key Security

- The key is stored as a constant in Dart source (`_visionApiKey`)
- **Required**: Restrict the key in Cloud Console to prevent abuse:
  - **APIs & Services → Credentials → your key → Application restrictions**
  - Set to **Android apps**
  - Add: Package name `com.example.smartchefai` + SHA-1 debug fingerprint
- This makes the key useless if extracted from the APK (only works from your app)

---

## Files Changed

| File | Type | Change |
|------|------|--------|
| `lib/services/firebase_service.dart` | Modified | Replace Cloud Function call with direct Vision REST API; add `_filterLabels()` |

## Files NOT Changed

- `lib/features/scan/scan_screen.dart` — `analyzeImage()` signature unchanged
- `functions/` — kept as-is for future Blaze upgrade
- All other files

---

## Error Handling

| Scenario | Behavior |
|----------|----------|
| API key missing / invalid | Dio throws 403; ScanScreen shows SnackBar: "Analysis failed: ..." |
| Network error | Existing Dio retry interceptor handles; then SnackBar |
| Vision returns 0 labels after filter | `_detectedIngredients` empty; ScanScreen shows "No ingredients detected" SnackBar |
| Vision API 400 (bad image) | Dio throws; ScanScreen shows SnackBar |

---

## One-Time Setup Steps

1. Enable **Cloud Vision API**: `console.cloud.google.com/apis/library/vision.googleapis.com?project=smartchefai-344c5`
2. Create **API key**: `console.cloud.google.com/apis/credentials?project=smartchefai-344c5` → **Create Credentials → API key**
3. **Restrict the key**: Application restrictions → Android apps → add package + SHA-1
4. Paste the key into `_visionApiKey` constant in `firebase_service.dart`

---

*Design approved: 2026-02-20 | Author: Claude Sonnet 4.6*
