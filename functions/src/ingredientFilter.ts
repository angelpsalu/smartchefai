export interface VisionLabel {
  description: string;
  score: number;
}

export interface DetectedIngredient {
  name: string;
  confidence: number;
}

const NON_FOOD_BLOCKLIST = new Set([
  'Kitchen', 'Tableware', 'Room', 'Table', 'Countertop',
  'Wood', 'Dish', 'Plate', 'Bowl', 'Cutlery', 'Furniture',
  'Interior design', 'Hardwood', 'Wall', 'Floor', 'Ceiling',
  'Light', 'Lighting', 'Textile', 'Shelf',
]);

export function filterLabels(labels: VisionLabel[]): DetectedIngredient[] {
  return labels
    .filter(l => l.score >= 0.65)
    .filter(l => !NON_FOOD_BLOCKLIST.has(l.description))
    .sort((a, b) => b.score - a.score)
    .map(l => ({ name: l.description, confidence: l.score }));
}
