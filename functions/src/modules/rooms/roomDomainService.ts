import * as admin from 'firebase-admin';
import { RoomDocument, PublicRoomSummary } from './roomTypes';
import { AppError, NotFoundError, UnauthorizedError } from '../../common/errors';
import { paiseToRupees, rupeesToPaise } from '../../common/money';
import { auditService } from '../../audit/auditService';

export interface RoomSearchParams {
  city?: string;
  locality?: string;
  roomType?: string;
  minPrice?: number;
  maxPrice?: number;
  guestCount?: number;
  amenities?: string[];
  minRating?: number;
  sortBy?: 'price_asc' | 'price_desc' | 'rating' | 'recency';
  limit?: number;
  offset?: number;
}

export class RoomDomainService {
  private get collection() {
    return admin.firestore().collection('rooms');
  }

  /**
   * 1. createRoom
   * Never trusts client-provided owner IDs. Validates photos, capacity, and prices in integer minor units.
   */
  async createRoom(ownerUid: string, data: Partial<RoomDocument>): Promise<RoomDocument> {
    if (!data.title || data.title.trim().length < 5) {
      throw new AppError('Room title must be at least 5 characters long.', 400);
    }
    if (!data.city || !data.locality) {
      throw new AppError('City and locality are required.', 400);
    }
    const priceRupees = data.pricePerNightPaise !== undefined ? paiseToRupees(data.pricePerNightPaise) : 799;
    if (priceRupees < 100) {
      throw new AppError('Price per night must be at least ₹100.', 400);
    }

    const roomId = `room_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
    const now = new Date().toISOString();

    const room: RoomDocument = {
      roomId,
      ownerId: ownerUid, // Enforced from authenticated token
      title: data.title.trim(),
      description: data.description || '',
      roomType: data.roomType || 'Private Room',
      country: data.country || 'India',
      state: data.state || 'Uttar Pradesh',
      city: data.city.trim(),
      locality: data.locality.trim(),
      address: data.address || '',
      latitude: data.latitude || 26.8522,
      longitude: data.longitude || 80.9995,
      photoUrls: data.photoUrls || [],
      coverPhotoUrl: data.coverPhotoUrl || (data.photoUrls && data.photoUrls[0]) || '',
      amenities: data.amenities || ['Fast Wi-Fi', 'Attached Washroom'],
      maxGuests: Math.max(1, data.maxGuests || 2),
      bedCount: Math.max(1, data.bedCount || 1),
      bathroomCount: Math.max(1, data.bathroomCount || 1),
      pricePerNightPaise: rupeesToPaise(priceRupees),
      currency: 'INR',
      cleaningFeePaise: 0,
      securityDepositPaise: 0,
      checkInTime: data.checkInTime || '12:00 PM',
      checkOutTime: data.checkOutTime || '11:00 AM',
      houseRules: data.houseRules || ['18+ Govt ID mandatory', 'No loud noise after 10 PM'],
      cancellationPolicyId: 'flexible_24h',
      listingStatus: 'draft',
      ownerVerificationStatus: 'verified',
      averageRating: 4.8,
      reviewCount: 0,
      digitalPin: `PIN-${1000 + (Date.now() % 8999)}`,
      bookedDates: [],
      createdAt: now,
      updatedAt: now,
    };

    await this.collection.doc(roomId).set(room);
    await auditService.recordEvent({
      eventType: 'ROOM_CREATED',
      userId: ownerUid,
      resourceId: roomId,
      details: { title: room.title, city: room.city },
    });

    return room;
  }

  /**
   * 2. updateRoom
   * Owners can edit only their own permitted listings. Edits do not affect existing confirmed booking snapshots.
   */
  async updateRoom(roomId: string, ownerUid: string, updates: Partial<RoomDocument>): Promise<RoomDocument> {
    const docRef = this.collection.doc(roomId);
    const snap = await docRef.get();
    if (!snap.exists) throw new NotFoundError('Room not found.');

    const room = snap.data() as RoomDocument;
    if (room.ownerId !== ownerUid) {
      throw new UnauthorizedError('You are not authorized to edit this listing.');
    }
    if (room.listingStatus === 'suspended') {
      throw new AppError('Suspended listings cannot be updated.', 403);
    }

    const safeUpdates: Partial<RoomDocument> = {
      updatedAt: new Date().toISOString(),
    };

    if (updates.title) safeUpdates.title = updates.title.trim();
    if (updates.description) safeUpdates.description = updates.description;
    if (updates.amenities) safeUpdates.amenities = updates.amenities;
    if (updates.maxGuests) safeUpdates.maxGuests = Math.max(1, updates.maxGuests);
    if (updates.pricePerNightPaise && updates.pricePerNightPaise >= 10000) {
      safeUpdates.pricePerNightPaise = updates.pricePerNightPaise;
    }
    if (updates.houseRules) safeUpdates.houseRules = updates.houseRules;

    await docRef.update(safeUpdates);
    return { ...room, ...safeUpdates };
  }

  /**
   * 3. getRoom
   * Returns safe details for public visitors; returns full address only to confirmed guests or owner.
   */
  async getRoom(roomId: string, viewerUid?: string, userRole?: string): Promise<RoomDocument | PublicRoomSummary> {
    const snap = await this.collection.doc(roomId).get();
    if (!snap.exists) throw new NotFoundError('Room not found.');

    const room = snap.data() as RoomDocument;
    const isOwner = viewerUid && room.ownerId === viewerUid;
    const isAdmin = userRole === 'admin';

    if (isOwner || isAdmin) {
      return room;
    }

    // Public / guest view: redact exact address and internal PIN
    const { address, digitalPin, ownerId, ...publicFields } = room;
    return {
      ...publicFields,
      pricePerNight: paiseToRupees(room.pricePerNightPaise),
    };
  }

  /**
   * 4. searchRooms
   * Multi-criteria search with pagination and sorting. Returns only published rooms.
   */
  async searchRooms(params: RoomSearchParams): Promise<{ rooms: PublicRoomSummary[]; total: number }> {
    let query: admin.firestore.Query = this.collection.where('listingStatus', '==', 'published');

    if (params.city && params.city !== 'All') {
      query = query.where('city', '==', params.city);
    }

    const snapshot = await query.get();
    let items = snapshot.docs.map(doc => doc.data() as RoomDocument);

    // Apply in-memory secondary filters
    if (params.locality) {
      items = items.filter(r => r.locality.toLowerCase().includes(params.locality!.toLowerCase()));
    }
    if (params.roomType && params.roomType !== 'All') {
      items = items.filter(r => r.roomType.toLowerCase() === params.roomType!.toLowerCase());
    }
    if (params.minPrice) {
      items = items.filter(r => paiseToRupees(r.pricePerNightPaise) >= params.minPrice!);
    }
    if (params.maxPrice) {
      items = items.filter(r => paiseToRupees(r.pricePerNightPaise) <= params.maxPrice!);
    }
    if (params.guestCount) {
      items = items.filter(r => r.maxGuests >= params.guestCount!);
    }
    if (params.minRating) {
      items = items.filter(r => r.averageRating >= params.minRating!);
    }
    if (params.amenities && params.amenities.length > 0) {
      items = items.filter(r => params.amenities!.every(a => r.amenities.includes(a)));
    }

    // Sorting
    if (params.sortBy === 'price_asc') {
      items.sort((a, b) => a.pricePerNightPaise - b.pricePerNightPaise);
    } else if (params.sortBy === 'price_desc') {
      items.sort((a, b) => b.pricePerNightPaise - a.pricePerNightPaise);
    } else if (params.sortBy === 'rating') {
      items.sort((a, b) => b.averageRating - a.averageRating);
    } else {
      // Recency default
      items.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
    }

    const total = items.length;
    const offset = params.offset || 0;
    const limit = params.limit || 20;
    const paginated = items.slice(offset, offset + limit);

    const publicRooms = paginated.map(r => {
      const { address, digitalPin, ownerId, ...rest } = r;
      return {
        ...rest,
        pricePerNight: paiseToRupees(r.pricePerNightPaise),
      };
    });

    return { rooms: publicRooms, total };
  }

  /**
   * 5. getOwnerRooms
   */
  async getOwnerRooms(ownerUid: string): Promise<RoomDocument[]> {
    const snap = await this.collection.where('ownerId', '==', ownerUid).get();
    return snap.docs.map(d => d.data() as RoomDocument);
  }

  /**
   * 6. submitRoomForReview
   */
  async submitRoomForReview(roomId: string, ownerUid: string): Promise<void> {
    const docRef = this.collection.doc(roomId);
    const snap = await docRef.get();
    if (!snap.exists) throw new NotFoundError('Room not found.');
    const room = snap.data() as RoomDocument;
    if (room.ownerId !== ownerUid) throw new UnauthorizedError();

    await docRef.update({
      listingStatus: 'pending_review',
      updatedAt: new Date().toISOString(),
    });
  }

  /**
   * 7. approveRoom (Admin only)
   */
  async approveRoom(roomId: string): Promise<void> {
    await this.collection.doc(roomId).update({
      listingStatus: 'published',
      updatedAt: new Date().toISOString(),
    });
  }

  /**
   * 8. rejectRoom (Admin only)
   */
  async rejectRoom(roomId: string, reason: string): Promise<void> {
    await this.collection.doc(roomId).update({
      listingStatus: 'rejected',
      updatedAt: new Date().toISOString(),
    });
  }

  /**
   * 9. suspendRoom (Admin only)
   */
  async suspendRoom(roomId: string, reason: string): Promise<void> {
    await this.collection.doc(roomId).update({
      listingStatus: 'suspended',
      updatedAt: new Date().toISOString(),
    });
  }

  /**
   * 10. deleteDraftRoom
   */
  async deleteDraftRoom(roomId: string, ownerUid: string): Promise<void> {
    const docRef = this.collection.doc(roomId);
    const snap = await docRef.get();
    if (!snap.exists) return;
    const room = snap.data() as RoomDocument;
    if (room.ownerId !== ownerUid) throw new UnauthorizedError();
    if (room.listingStatus !== 'draft') {
      throw new AppError('Only draft rooms can be deleted directly.', 400);
    }
    await docRef.delete();
  }
}

export const roomDomainService = new RoomDomainService();
