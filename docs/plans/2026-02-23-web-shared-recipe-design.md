# Web Shared Recipe Links — Design Document

**Date:** 2026-02-23  
**Feature:** Phase 2.4 — Unauthenticated Recipe Access on Web  
**Status:** Approved, ready for implementation

---

## Problem

The GoRouter auth redirect blocks all unauthenticated users from `/recipe/:id`, redirecting them to `/get-started`. This means shared recipe links are useless for non-signed-in users on web.

## Scope

Allow unauthenticated users to open a shared `/recipe/:id` URL on web and see a clean read-only recipe view — image, description, ingredients, instructions, nutrition — without favorites, cooking tracker, or grocery features.

Out of scope: unauthenticated access to any other route; any sign-in upsell UI.

---

## Design

### 1. Firestore Rule Change

Make recipe reads public. Recipe catalog data is not user-sensitive — it's shared content.

```
match /recipes/{recipeId} {
  allow read: if true;   // was: if request.auth != null
  allow write: if false;
}
```

### 2. Router Redirect Exemption

Add `/recipe/` to the exempt-from-redirect paths in `routes.dart`:

```dart
final isPublicRecipe = state.uri.path.startsWith('/recipe/');
if (!isSignedIn && !isGoingToAuth && !isPublicRecipe) {
  return '/get-started';
}
```

The signed-in-to-auth-screen redirect is unaffected.

### 3. Route Builder — Handle Direct URL Load

The recipe route currently passes data via `state.extra`. On a direct web URL load, `extra` is null.

When `extra == null`, render a `_RecipeLoaderWidget` inline in the route builder:
- Shows a centered `CircularProgressIndicator` while loading
- Calls `FirebaseService().getRecipe(state.pathParameters['id']!)`
- On success: renders `RecipeDetailScreen(recipe: recipe)`
- On null result: renders error scaffold with "Recipe not found" message

When `extra != null` (normal in-app navigation): renders `RecipeDetailScreen` directly as before.

`_RecipeLoaderWidget` is a private `StatefulWidget` defined in `routes.dart`. No new files.

### 4. RecipeDetailScreen — Hide Auth-Gated Actions

Use `FirebaseService().isSignedIn` (existing bool getter) to conditionally render actions.

When not signed in, hide:
- **Favorite button** — the `IconButton` in the hero area AppBar
- **"Start Cooking" button** — `GradientButton` in the header section
- **"Add to Grocery List" button** — in the Ingredients tab

Everything else renders normally: hero image, title, description, rating, time cards, servings adjuster (display only), ingredients list, instructions, nutrition tab.

---

## Files Changed

| Action | File | Change |
|--------|------|--------|
| MODIFY | `firestore.rules` | Recipe read rule: `if true` |
| MODIFY | `lib/app/routes.dart` | Add `isPublicRecipe` exempt; add `_RecipeLoaderWidget`; update builder |
| MODIFY | `lib/features/recipe_detail/recipe_detail_screen.dart` | Conditionally hide favorite, Start Cooking, Add to Grocery buttons |

---

## Error Handling

- Recipe ID not found in Firestore: show simple "Recipe not found" scaffold with back button
- Firestore network error: same "Recipe not found" scaffold (no retry UI — YAGNI)
- `state.pathParameters['id']` missing: already handled by GoRouter path matching
