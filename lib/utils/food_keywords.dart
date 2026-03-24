/// Allowlist of food-related keywords. A word is considered food-related if it
/// contains (or is contained by) one of these keywords.
const Set<String> kFoodKeywords = {
  // Generic food categories
  'food', 'vegetable', 'fruit', 'ingredient', 'produce', 'grocery',
  'cuisine', 'dish', 'meal', 'recipe', 'cooking', 'spice', 'herb',
  'meat', 'fish', 'seafood', 'dairy', 'grain', 'nut', 'legume',
  'staple food', 'whole food', 'superfood', 'natural food',
  // Vegetables
  'tomato', 'carrot', 'broccoli', 'onion', 'garlic', 'pepper',
  'cucumber', 'celery', 'spinach', 'lettuce', 'cabbage', 'cauliflower',
  'potato', 'corn', 'pea', 'zucchini', 'eggplant', 'asparagus',
  'kale', 'radish', 'beet', 'mushroom', 'artichoke', 'leek',
  'scallion', 'shallot', 'fennel', 'pumpkin', 'squash', 'bok choy',
  'arugula', 'watercress', 'endive', 'chili', 'jalapeño', 'ginger',
  // Fruits
  'apple', 'banana', 'orange', 'lemon', 'lime', 'strawberry',
  'blueberry', 'raspberry', 'grape', 'watermelon', 'mango',
  'pineapple', 'avocado', 'peach', 'pear', 'cherry', 'plum',
  'kiwi', 'papaya', 'coconut', 'pomegranate', 'fig', 'apricot',
  'grapefruit', 'melon', 'berry', 'citrus',
  // Proteins
  'chicken', 'beef', 'pork', 'lamb', 'turkey', 'duck', 'salmon',
  'tuna', 'shrimp', 'crab', 'lobster', 'egg', 'tofu', 'tempeh',
  'sausage', 'bacon', 'ham', 'poultry', 'prawn',
  // Dairy
  'cheese', 'milk', 'butter', 'cream', 'yogurt', 'mozzarella',
  'cheddar', 'parmesan', 'feta', 'ricotta',
  // Grains & Starches
  'rice', 'pasta', 'bread', 'noodle', 'flour', 'oat', 'wheat',
  'barley', 'quinoa', 'couscous', 'tortilla', 'cereal',
  // Herbs & Spices
  'basil', 'oregano', 'cilantro', 'parsley', 'mint', 'thyme',
  'rosemary', 'sage', 'dill', 'turmeric', 'cumin', 'paprika',
  'cinnamon', 'coriander', 'cardamom', 'clove', 'nutmeg',
  // Legumes & Nuts
  'bean', 'lentil', 'chickpea', 'peanut', 'almond', 'walnut',
  'cashew', 'pecan', 'hazelnut', 'pistachio',
  // Condiments & Others
  'olive', 'oil', 'vinegar', 'sauce', 'soup', 'salad', 'honey',
  'jam', 'chocolate', 'sugar', 'salt', 'stock', 'broth',
};

/// Multi-word ingredients that should NOT be split during voice parsing.
const Set<String> kCompoundIngredients = {
  'olive oil', 'soy sauce', 'sour cream', 'cream cheese',
  'peanut butter', 'coconut milk', 'coconut oil', 'sesame oil',
  'fish sauce', 'hot sauce', 'tomato paste', 'tomato sauce',
  'green beans', 'green onion', 'bell pepper', 'black pepper',
  'chili pepper', 'sweet potato', 'brown sugar', 'brown rice',
  'balsamic vinegar', 'red wine', 'white wine',
  'lemon juice', 'lime juice', 'orange juice',
  'maple syrup', 'vanilla extract', 'bok choy',
  'soy milk', 'almond milk', 'oat milk',
  'black bean', 'kidney bean', 'green pea',
  'red onion', 'white onion', 'spring onion',
  'garlic powder', 'onion powder', 'chili powder',
  'bay leaf', 'star anise',
};

/// Generic food categories too vague to be useful as individual ingredients.
/// These are valid for Vision API label matching but should be filtered out
/// from voice input results.
const Set<String> kGenericFoodCategories = {
  'food', 'vegetable', 'fruit', 'ingredient', 'produce', 'grocery',
  'cuisine', 'dish', 'meal', 'recipe', 'cooking',
  'staple food', 'whole food', 'superfood', 'natural food',
};
