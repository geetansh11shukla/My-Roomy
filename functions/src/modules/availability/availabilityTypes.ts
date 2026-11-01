export type RoomBlockReason = 'maintenance' | 'owner_block' | 'other';
export type RoomBlockStatus = 'active' | 'released';
export type BookingHoldStatus = 'active' | 'converted' | 'expired' | 'released';

export interface RoomBlockDocument {
  blockId: string;
  roomId: string;
  startDate: string; // YYYY-MM-DD
  endDate: string; // YYYY-MM-DD
  reason: RoomBlockReason;
  createdBy: string;
  status: RoomBlockStatus;
  createdAt: string;
  updatedAt: string;
}

export interface BookingHoldDocument {
  holdId: string;
  roomId: string;
  customerId: string;
  checkIn: string; // YYYY-MM-DD
  checkOut: string; // YYYY-MM-DD
  status: BookingHoldStatus;
  expiresAt: string; // ISO Timestamp (10 mins)
  idempotencyKey?: string;
  createdAt: string;
  updatedAt: string;
}

export interface RoomDateLockDocument {
  lockId: string; // deterministic format: `${roomId}_${dateStr}` (YYYY-MM-DD)
  roomId: string;
  date: string; // YYYY-MM-DD
  lockType: 'hold' | 'booking' | 'block';
  holderId: string; // holdId, bookingId, or blockId
  expiresAt?: string; // only for holds
  createdAt: string;
}

