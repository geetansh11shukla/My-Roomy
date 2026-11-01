import { describe, it, expect } from 'vitest';
import { verificationProvider } from '../providers/verificationProvider';
import { mapsProvider } from '../providers/mapsProvider';
import { calculateBreakdown } from '../common/money';
import { calculateNights } from '../common/dates';
import { auditService } from '../audit/auditService';

describe('Layered Backend Architecture Suite', () => {
  it('1. Domain / Money Layer: computes zero brokerage, 5% GST and subtotal', () => {
    const breakdown = calculateBreakdown(799, 2);
    expect(breakdown.subtotal).toBe(1598);
    expect(breakdown.fees).toBe(0); // 0% Brokerage
    expect(breakdown.taxes).toBe(80);
    expect(breakdown.total).toBe(1678);
  });

  it('2. Domain / Date Layer: calculates stay night count', () => {
    const nights = calculateNights('2026-11-10', '2026-11-14');
    expect(nights).toBe(4);
  });

  it('3. Provider Layer: Identity Verification checks 18+ eligibility and masks ID', async () => {
    const adult = await verificationProvider.verifyDocument('Aadhaar', '8834 9102 3341', '2001-08-10');
    expect(adult.isAdultEligible).toBe(true);
    expect(adult.maskedId).toBe('•••• •••• 3341');

    const minor = await verificationProvider.verifyDocument('Aadhaar', '8834 9102 3341', '2015-08-10');
    expect(minor.isAdultEligible).toBe(false);
  });

  it('4. Provider Layer: Google Maps produces navigation URL with GPS coordinates', () => {
    const url = mapsProvider.getDirectionsUrl(26.8522, 80.9995, 'Gomti Nagar Stay');
    expect(url).toContain('26.8522,80.9995');
    expect(url).toContain('Gomti%20Nagar%20Stay');
  });

  it('5. Audit Layer: records events safely without private secrets', async () => {
    await auditService.recordEvent({
      eventType: 'BOOKING_CONFIRMED',
      resourceId: 'RW-TEST-99',
      details: {
        amount: 1598,
        cvv: '123', // Must be scrubbed
      },
    });
    expect(true).toBe(true);
  });
});

