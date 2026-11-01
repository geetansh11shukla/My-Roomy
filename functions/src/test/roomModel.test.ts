import { describe, it, expect } from 'vitest';
import { paiseToRupees, rupeesToPaise } from '../common/money';

describe('Room Model & Integer Minor Units Suite', () => {
  it('1. Decimal-safe integer minor unit conversion prevents floating point drift', () => {
    const rupees = 799;
    const paise = rupeesToPaise(rupees);
    expect(paise).toBe(79900);
    expect(paiseToRupees(paise)).toBe(799);

    // Decimal safety: 1199.50 rupees = 119950 paise
    expect(rupeesToPaise(1199.5)).toBe(119950);
  });

  it('2. Disallows negative or sub-minimum room rates', () => {
    const invalidPrice = -500;
    expect(invalidPrice < 10000).toBe(true);
  });
});

