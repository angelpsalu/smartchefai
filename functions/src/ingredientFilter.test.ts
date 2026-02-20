import { filterLabels, VisionLabel } from './ingredientFilter';

const label = (description: string, score: number): VisionLabel =>
  ({ description, score });

describe('filterLabels', () => {
  it('keeps labels with score >= 0.65', () => {
    const result = filterLabels([
      label('Tomato', 0.94),
      label('Garlic', 0.65),   // boundary — should be kept
      label('Onion', 0.64),    // just below — should be dropped
    ]);
    expect(result.map(r => r.name)).toEqual(['Tomato', 'Garlic']);
  });

  it('removes blocklisted non-food labels', () => {
    const result = filterLabels([
      label('Tomato', 0.90),
      label('Kitchen', 0.95),   // blocklisted — should be dropped
      label('Tableware', 0.88), // blocklisted — should be dropped
      label('Plate', 0.85),     // blocklisted — should be dropped
    ]);
    expect(result.map(r => r.name)).toEqual(['Tomato']);
  });

  it('returns empty array when no labels pass filter', () => {
    const result = filterLabels([
      label('Kitchen', 0.99),
      label('Table', 0.99),
    ]);
    expect(result).toEqual([]);
  });

  it('preserves confidence scores', () => {
    const result = filterLabels([label('Basil', 0.87)]);
    expect(result[0].confidence).toBeCloseTo(0.87);
  });

  it('returns labels sorted by confidence descending', () => {
    const result = filterLabels([
      label('Basil', 0.70),
      label('Tomato', 0.94),
      label('Garlic', 0.82),
    ]);
    expect(result.map(r => r.name)).toEqual(['Tomato', 'Garlic', 'Basil']);
  });
});
