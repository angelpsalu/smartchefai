# SmartChef AI — App Features & How It Works

> A simple guide to everything SmartChef AI can do and the technology behind it.

---

## What Is SmartChef AI?

SmartChef AI is a recipe discovery and meal planning app. You can search 100+ recipes, scan ingredients with your phone camera to find what to cook, plan your weekly meals, track nutrition, and auto-generate grocery lists — all in one app.

**Available on**: Android phones/tablets and Web browsers.

---

## Features

### 1. 🔐 User Account

**What it does**: Create an account to save your favorites, meal plans, and preferences across devices.

**How to sign up**:
- Email + password registration
- Google Sign-In (one-tap login with your Google account)
- Password reset via email if you forget it

**What gets saved to your account**:
- Favorite recipes
- Meal plans
- Grocery lists
- Cooking stats (recipes cooked, streak)
- Dietary preferences & allergies
- Profile photo
- Dark/light mode preference

**Technology**: Firebase Authentication handles secure login. Your data is stored in Google's Cloud Firestore database and only you can access your own data.

---

### 2. 🏠 Home Screen

**What it does**: Your main dashboard showing all recipes, daily nutrition progress, and quick access to everything.

**What you see**:
- Personalized greeting ("Good Morning, Martin!")
- **Nutrition Goals Card** — 4 progress rings showing how much of your daily Calories, Protein, Carbs, and Fat you've consumed today
- **Category chips** — tap a cuisine type (Italian, Thai, Indian, etc.) to filter recipes
- **Recipe grid** — all 100+ recipes with photos, cook time, difficulty, and cuisine tags

**Technology**: Recipes load instantly from a built-in database of 100 recipes. In the background, the app checks for any new recipes from the cloud.

---

### 3. 🔍 Recipe Search

**What it does**: Find recipes by typing a name, ingredient, or cuisine — or just speak it.

**How it works**:
- Type in the search box (keyboard only opens when you tap the box)
- Tap the **microphone button** to search by voice
- See your recent searches listed below the search box
- Results show up to 50 matching recipes

**Voice search**: Uses your phone's built-in speech recognition — works offline, no internet needed for the voice part.

**Technology**: Search checks recipe names, cuisines, and ingredient lists. Voice recognition uses the `speech_to_text` library (on-device, not sent to any server).

---

### 4. 📸 Ingredient Scanner (AI-Powered)

**What it does**: Take a photo of ingredients on your counter and the app identifies them, then finds recipes you can make.

**How it works**:
1. Tap the **camera button** (center of bottom navigation)
2. Take a photo or pick one from your gallery
3. AI identifies food items in the photo (e.g., "tomato", "chicken", "garlic")
4. Results appear as chips — you can remove any wrong ones
5. Tap "Find Recipes" to see what you can cook with those ingredients

**How accurate is it?** The AI only keeps results it's at least 65% confident about, and filters out non-food items. It knows 80+ food categories including vegetables, fruits, meats, dairy, grains, herbs, and spices.

**Technology**: Google Cloud Vision API analyzes the photo. The image is compressed before sending to save bandwidth. The API key is secured and never exposed in the app code. Free tier allows 1,000 scans per month.

---

### 5. 🍽️ Recipe Details

**What it does**: Full recipe view with everything you need to cook.

**What you see** (3 tabs):
- **Ingredients tab** — ingredient list with a servings adjuster (change from 4 servings to 2, quantities auto-update). "Add to Grocery List" button adds all ingredients.
- **Instructions tab** — numbered step-by-step cooking directions. "Start Cooking" button tracks your cooking stats.
- **Nutrition tab** — calories, protein, carbs, fat, and fiber per serving

**Other actions**:
- ❤️ **Favorite** — tap the heart to save the recipe
- 📤 **Share** — send recipe link to friends via any app (WhatsApp, Messages, etc.)
- 📅 **Add to Meal Plan** — pick a day (Monday–Sunday) and a meal slot (Breakfast, Lunch, Dinner, or Snack)

**Technology**: Recipe data comes from a local database of 100 curated recipes. Images are cached on your device so they load instantly after the first time. Sharing creates a web link (`smartchefai.web.app/recipe/...`).

---

### 6. 📅 Meal Planner

**What it does**: Plan your entire week's meals across 4 time slots per day.

**How it works**:
1. Go to the **Planner** tab in bottom navigation
2. Each day (Monday–Sunday) is an expandable card
3. Each day has **4 meal slots**: Breakfast, Lunch, Dinner, Snack
4. Tap an empty slot → a recipe picker appears
5. Recipes are sorted with **smart suggestions** first:
   - Breakfast slot → pancakes, eggs, smoothies, oatmeal appear at the top
   - Lunch slot → salads, sandwiches, soups appear first
   - Dinner slot → all recipes qualify
   - Snack slot → desserts, cookies, fruit dishes appear first

**Smart suggestions**: The app uses keyword matching to figure out which recipes belong to which meal. For example, if a recipe name contains "pancake", "egg", or "smoothie", it's suggested for breakfast.

**Technology**: Meal plans are saved to your cloud account (Firestore) and persist across app restarts. The keyword-based classification runs locally — no internet needed for suggestions.

---

### 7. 🛒 Grocery List

**What it does**: Automatically generates a categorized shopping list from your meal plan, or lets you add items manually.

**How it works**:
- **Auto-generate**: In the Planner's Grocery tab, tap "Generate from Meal Plan" — all ingredients from your planned meals become a shopping list
- **Manual add**: Add individual items with name, quantity, and unit
- **Check off items** as you shop
- **Clear completed** removes checked items

**Smart categorization**: Items are automatically sorted into sections:
- 🥬 **Produce** — vegetables, fruits, herbs
- 🥛 **Dairy & Eggs** — milk, cheese, yogurt, eggs
- 🥩 **Meat & Seafood** — chicken, beef, fish, shrimp
- 🍞 **Bakery** — bread, flour, tortillas
- 🧂 **Spices & Herbs** — salt, pepper, cumin, basil
- 🥫 **Pantry** — everything else (oil, rice, pasta, cans)

Each item shows which recipe it came from (e.g., "from Spaghetti Carbonara").

**Technology**: Ingredient categorization uses keyword matching (e.g., "chicken" → Meat, "tomato" → Produce). The list syncs to your cloud account automatically and is also saved locally for offline access.

---

### 8. 📊 Nutrition Tracking

**What it does**: Tracks your daily food intake and shows progress toward your nutrition goals.

**How it works**:
1. Set your daily goals (tap the settings icon on the Nutrition Goals card on the home screen):
   - Calories (default: 2,000)
   - Protein (default: 50g)
   - Carbs (default: 250g)
   - Fat (default: 65g)
2. When you tap "Start Cooking" on any recipe, that recipe's nutrition is logged for today
3. The 4 progress rings on the home screen fill up as you cook

**Technology**: Daily intake is stored locally on your device (resets each day). Goals are saved to your cloud account. Nutrition data comes from each recipe's pre-calculated values.

---

### 9. ❤️ Favorites

**What it does**: Save recipes you love for quick access later.

**How it works**:
- Tap the ❤️ heart icon on any recipe card or detail page
- View all favorites from the Favorites screen
- Favorites persist across app restarts (saved locally + synced to cloud)

**Technology**: Favorite IDs are stored both locally (SharedPreferences) and in the cloud (Firestore). This means favorites work even offline.

---

### 10. 👤 Profile & Settings

**What it does**: Manage your account, appearance, and preferences.

**What you can configure**:
- **Profile photo** — upload from camera or gallery (stored securely in Firebase Storage, max 5MB)
- **Dark mode** — toggle between light and dark themes
- **Notifications** — enable/disable (toggle saved locally)
- **Language** — choose from English, Spanish, French, German, Italian, Portuguese
- **Dietary preferences** — set your diet type (Vegetarian, Vegan, Keto, Gluten-Free, etc.)
- **Allergies** — mark allergens (Peanuts, Dairy, Shellfish, Eggs, etc.)

**Cooking stats shown**:
- Total recipes cooked
- Current cooking streak (consecutive days)
- Member since date

**Support links**:
- Help & FAQ → opens web page
- Send Feedback → opens email
- Rate the App → opens Play Store listing

---

### 11. 🎓 Onboarding Tour

**What it does**: A 4-page introduction shown on first app launch.

**Pages**:
1. **Discover Recipes** — browse 100+ recipes from around the world
2. **Smart Detection** — scan ingredients with your camera
3. **Voice Search** — search hands-free while cooking
4. **Personalized Experience** — set dietary preferences and get tailored results

Shown only once. Can be skipped.

---

## Technology Summary

| Component | Technology | What It Does |
|-----------|-----------|--------------|
| **App framework** | Flutter | Runs on Android and Web from one codebase |
| **User accounts** | Firebase Authentication | Secure login with email or Google |
| **Database** | Cloud Firestore | Stores recipes, user data, meal plans, grocery lists |
| **Photo storage** | Firebase Storage | Stores profile photos securely |
| **Ingredient scanner** | Google Cloud Vision API | AI identifies food items in photos |
| **Recipe data** | Local JSON + TheMealDB API | 100 built-in recipes + online backup source |
| **Voice search** | speech_to_text | On-device speech recognition (no data sent externally) |
| **Image caching** | cached_network_image | Recipe photos load instantly after first view |
| **Local storage** | SharedPreferences | Saves favorites, settings, grocery list for offline use |

---

## Data & Privacy

- **Your data is yours** — only you can read/write your own user data, meal plans, grocery lists, and nutrition goals
- **Photos** — profile photos are stored in Firebase Storage under your user ID; only you can access them
- **Ingredient scanning** — photos are sent to Google Cloud Vision API for analysis but are not stored by Google
- **Voice search** — processed entirely on your device; audio is not sent to any server
- **No ads, no tracking** — the app does not include any advertising or analytics SDKs

---

## Offline Support

The app works without internet for most features:

| Feature | Offline? | Notes |
|---------|----------|-------|
| Browse recipes | ✅ Yes | 100 recipes stored locally |
| View favorites | ✅ Yes | Favorite IDs cached locally |
| Grocery list | ✅ Yes | Saved locally, syncs when online |
| Dark mode / settings | ✅ Yes | Stored on device |
| Ingredient scanner | ❌ No | Requires internet (Cloud Vision API) |
| Meal plan sync | ❌ No | Requires internet for cloud save |
| Sign in / Sign up | ❌ No | Requires internet |
| Voice search | ✅ Yes | On-device speech recognition |

---

*SmartChef AI v1.0.0 — Last updated: 2026-02-23*
