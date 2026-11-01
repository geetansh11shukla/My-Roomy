export function calculateNights(checkIn: string, checkOut: string): number {
  const dIn = new Date(checkIn);
  const dOut = new Date(checkOut);
  const diffMs = dOut.getTime() - dIn.getTime();
  const days = Math.round(diffMs / (1000 * 3600 * 24));
  return days > 0 ? days : 1;
}

export function isDateConflict(targetDateStr: string, bookedDates: string[]): boolean {
  return bookedDates.includes(targetDateStr);
}

