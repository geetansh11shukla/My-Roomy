"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.db = exports.InMemoryDatabase = void 0;
class InMemoryDatabase {
    users = new Map();
    rooms = new Map();
    holds = new Map();
    bookings = new Map();
    payments = new Map();
    extensionOffers = new Map();
    supportTickets = new Map();
    notifications = new Map();
    constructor() {
        this.seed();
    }
    seed() {
        const now = new Date().toISOString();
        // Default Demo Customer
        this.users.set('usr_customer_101', {
            uid: 'usr_customer_101',
            fullName: 'Rahul Verma',
            email: 'rahul.v@roomwala.in',
            phoneNumber: '+91 9876543210',
            role: 'customer',
            accountStatus: 'active',
            profilePhotoUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400',
            dateOfBirth: '2000-05-15',
            ageEligibilityStatus: 'eligible_18_plus',
            identityVerificationStatus: 'verified',
            preferredLanguage: 'en',
            notificationPreferences: {
                bookingUpdates: true,
                paymentUpdates: true,
                extensionOffers: true,
                whatsappConsent: true,
            },
            createdAt: now,
            updatedAt: now,
        });
        // Default Demo Owner
        this.users.set('owner_101', {
            uid: 'owner_101',
            fullName: 'Sanjay Mishra (Verified Host)',
            email: 'sanjay.host@roomwala.in',
            phoneNumber: '+91 9811223344',
            role: 'owner',
            accountStatus: 'active',
            profilePhotoUrl: '',
            ageEligibilityStatus: 'eligible_18_plus',
            identityVerificationStatus: 'verified',
            preferredLanguage: 'hi',
            notificationPreferences: {
                bookingUpdates: true,
                payoutUpdates: true,
            },
            createdAt: now,
            updatedAt: now,
        });
        // Seed Verified Rooms (Lucknow Gomti Nagar, Hazratganj, Indira Nagar)
        this.rooms.set('room_1', {
            roomId: 'room_1',
            ownerId: 'owner_101',
            title: 'Premium AC Suite near Gomti Nagar',
            description: 'Spacious air-conditioned studio with attached bath, fast Wi-Fi and keyless digital door entry. No brokerage, direct verified owner stay.',
            roomType: 'Private Room',
            country: 'India',
            state: 'Uttar Pradesh',
            city: 'Lucknow',
            locality: 'Gomti Nagar',
            address: 'Plot 42, Sector 4, Gomti Nagar Extension, Lucknow',
            latitude: 26.8522,
            longitude: 80.9995,
            photoUrls: [
                'https://images.unsplash.com/photo-1590490360182-c33d57733427?w=900',
                'https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=900',
            ],
            coverPhotoUrl: 'https://images.unsplash.com/photo-1590490360182-c33d57733427?w=900',
            amenities: ['Fast Wi-Fi', 'AC', 'Attached Washroom', 'Smart Lock', 'Power Backup'],
            maxGuests: 2,
            bedCount: 1,
            bathroomCount: 1,
            pricePerNight: 799,
            currency: 'INR',
            cleaningFee: 0,
            securityDeposit: 0,
            checkInTime: '12:00 PM',
            checkOutTime: '11:00 AM',
            houseRules: ['18+ Govt ID mandatory', 'No loud music after 10 PM'],
            cancellationPolicyId: 'flexible_24h',
            listingStatus: 'published',
            ownerVerificationStatus: 'verified',
            averageRating: 4.9,
            reviewCount: 48,
            digitalPin: 'PIN-8812',
            bookedDates: ['2026-11-15', '2026-11-16'],
            createdAt: now,
            updatedAt: now,
        });
        this.rooms.set('room_2', {
            roomId: 'room_2',
            ownerId: 'owner_101',
            title: 'Hazratganj Heritage City Studio',
            description: 'Charming modern studio room in central Lucknow. Close to metro, cafes and historic shopping lanes.',
            roomType: 'Entire Apartment',
            country: 'India',
            state: 'Uttar Pradesh',
            city: 'Lucknow',
            locality: 'Hazratganj',
            address: 'Civil Lines Road, Near Cathedral School, Hazratganj, Lucknow',
            latitude: 26.8467,
            longitude: 80.9462,
            photoUrls: [
                'https://images.unsplash.com/photo-1566665797739-1674de7a421a?w=900',
            ],
            coverPhotoUrl: 'https://images.unsplash.com/photo-1566665797739-1674de7a421a?w=900',
            amenities: ['AC', 'Attached Washroom', 'Work Desk', 'Geyser'],
            maxGuests: 3,
            bedCount: 2,
            bathroomCount: 1,
            pricePerNight: 1199,
            currency: 'INR',
            cleaningFee: 0,
            securityDeposit: 0,
            checkInTime: '12:00 PM',
            checkOutTime: '11:00 AM',
            houseRules: ['18+ Govt ID mandatory', 'No smoking in room'],
            cancellationPolicyId: 'flexible_24h',
            listingStatus: 'published',
            ownerVerificationStatus: 'verified',
            averageRating: 4.8,
            reviewCount: 32,
            digitalPin: 'PIN-3142',
            bookedDates: [],
            createdAt: now,
            updatedAt: now,
        });
        // Seed Active Booking
        const bookingId = 'RW-2026-8812';
        this.bookings.set(bookingId, {
            bookingId,
            roomId: 'room_1',
            customerId: 'usr_customer_101',
            ownerId: 'owner_101',
            roomTitleSnapshot: 'Premium AC Suite near Gomti Nagar',
            checkIn: 'Tomorrow, 12:00 PM',
            checkOut: 'In 2 Days, 11:00 AM',
            guestCount: 1,
            nightCount: 2,
            pricePerNightSnapshot: 799,
            subtotal: 1598,
            fees: 0,
            taxAmount: 80,
            discountAmount: 80,
            totalAmount: 1598,
            currency: 'INR',
            bookingStatus: 'confirmed',
            paymentStatus: 'captured',
            cancellationReason: '',
            accessPin: 'PIN-8812',
            locationUrl: 'https://maps.google.com/?q=26.8522,80.9995',
            priorityExtensionEligible: true,
            createdAt: now,
            updatedAt: now,
        });
        // Seed Active Extension Priority Offer
        this.extensionOffers.set('EXT-101', {
            offerId: 'EXT-101',
            bookingId,
            roomId: 'room_1',
            customerId: 'usr_customer_101',
            ownerId: 'owner_101',
            offeredAt: now,
            expiresAt: new Date(Date.now() + 24 * 3600 * 1000).toISOString(),
            requestedCheckIn: new Date(Date.now() + 2 * 24 * 3600 * 1000).toISOString(),
            requestedCheckOut: new Date(Date.now() + 3 * 24 * 3600 * 1000).toISOString(),
            quotedAmount: 799,
            status: 'offered',
            createdAt: now,
            updatedAt: now,
        });
    }
}
exports.InMemoryDatabase = InMemoryDatabase;
exports.db = new InMemoryDatabase();
