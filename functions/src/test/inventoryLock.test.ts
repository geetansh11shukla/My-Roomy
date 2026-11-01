import { describe, it, expect } from 'vitest';
import { inventoryLockService } from '../modules/availability/inventoryLockService';

describe('Availability & Atomic Inventory Locking Suite', () => {
  it('1. Half-open date range interval logic: check-in inclusive, check-out exclusive', () => {
    const nights = inventoryLockService.generateNightlyDates('2026-11-01', '2026-11-04');
    expect(nights).toEqual(['2026-11-01', '2026-11-02', '2026-11-03']);
    expect(nights.includes('2026-11-04')).toBe(false); // Checkout day is not locked
  });

  it('2. Back-to-back reservation compatibility: new stay can begin on previous checkout date', () => {
    const stayA = inventoryLockService.generateNightlyDates('2026-11-01', '2026-11-03');
    const stayB = inventoryLockService.generateNightlyDates('2026-11-03', '2026-11-05');

    // No overlapping dates between stayA [Nov 1, Nov 2] and stayB [Nov 3, Nov 4]
    const hasOverlap = stayA.some(dA => stayB.includes(dA));
    expect(hasOverlap).toBe(false);
  });

  it('3. Conflicting interval detection: requestedStart < existingEnd AND requestedEnd > existingStart', () => {
    // Conflict case: Nov 2 to Nov 4 overlaps with Nov 1 to Nov 3
    const conflict = inventoryLockService.hasIntervalConflict(
      '2026-11-02',
      '2026-11-04',
      '2026-11-01',
      '2026-11-03'
    );
    expect(conflict).toBe(true);

    // Non-conflict case: Nov 3 to Nov 5 back-to-back with Nov 1 to Nov 3
    const nonConflict = inventoryLockService.hasIntervalConflict(
      '2026-11-03',
      '2026-11-05',
      '2026-11-01',
      '2026-11-03'
    );
    expect(nonConflict).toBe(false);
  });
});

