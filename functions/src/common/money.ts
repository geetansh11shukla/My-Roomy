export function rupeesToPaise(rupees: number): number {
  return Math.round(rupees * 100);
}

export function paiseToRupees(paise: number): number {
  return Math.round(paise / 100);
}

export function calculateBreakdown(pricePerNight: number, nights: number) {
  const subtotal = pricePerNight * nights;
  const taxes = Math.round(subtotal * 0.05); // 5% GST
  const fees = 0; // 0% Brokerage Guarantee
  const total = subtotal + taxes + fees;
  return { subtotal, taxes, fees, total };
}

