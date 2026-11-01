export interface Room {
  id: string;
  title: string;
  city: string;
  area: string;
  pricePerDay: number;
  monthlyDiscountPercent: number;
  rating: number;
  reviewCount: number;
  images: string[];
  isInstantAvailable: boolean;
  bookedDates: string[]; // YYYY-MM-DD
  amenities: string[];
  houseRules: string[];
  address: string;
  latitude: number;
  longitude: number;
  ownerName: string;
  ownerWhatsApp: string;
  roomType: 'Single Room' | '1 RK' | '1 BHK' | 'Shared Room';
  minStayDays: number;
}

export interface Booking {
  bookingId: string;
  roomId: string;
  roomTitle: string;
  roomAddress: string;
  roomLocationUrl: string;
  customerName: string;
  customerPhone: string;
  customerAge: number;
  idProofType: 'Aadhaar Card' | 'Driving License' | 'Voter ID' | 'Passport';
  idNumber: string;
  idVerified: boolean;
  checkInDate: string; // YYYY-MM-DD
  checkOutDate: string; // YYYY-MM-DD
  totalDays: number;
  amountPaid: number;
  paymentMethod: 'UPI' | 'Card' | 'NetBanking';
  paymentId: string;
  status: 'Confirmed' | 'Active' | 'Completed' | 'Extended';
  accessCode: string;
  priorityExtensionEligible: boolean;
  extensionDeadline: string;
  createdAt: string;
}

export const MOCK_ROOMS: Room[] = [
  {
    id: 'room-delhi-01',
    title: 'Modern Cozy Studio near Metro',
    city: 'Delhi',
    area: 'Lajpat Nagar IV, South Delhi',
    pricePerDay: 850,
    monthlyDiscountPercent: 25,
    rating: 4.85,
    reviewCount: 42,
    images: [
      'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=800&q=80'
    ],
    isInstantAvailable: true,
    bookedDates: ['2026-11-01', '2026-11-02'],
    amenities: ['High-speed Wi-Fi', 'Air Conditioning', 'Geyser', 'Attached Washroom', 'Metro 300m', 'RO Water'],
    houseRules: ['Age 18+ valid ID mandatory', 'No loud noise after 10 PM', 'No smoking inside'],
    address: 'C-24, Ground Floor, Lajpat Nagar IV, New Delhi 110024',
    latitude: 28.5677,
    longitude: 77.2433,
    ownerName: 'Vikram Sharma',
    ownerWhatsApp: '+919876543210',
    roomType: 'Single Room',
    minStayDays: 1,
  },
  {
    id: 'room-delhi-02',
    title: 'Peaceful Private Room with Balcony',
    city: 'Delhi',
    area: 'Hauz Khas Village',
    pricePerDay: 1150,
    monthlyDiscountPercent: 20,
    rating: 4.92,
    reviewCount: 89,
    images: [
      'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?auto=format&fit=crop&w=800&q=80'
    ],
    isInstantAvailable: true,
    bookedDates: [],
    amenities: ['Lush Green View', 'Balcony', 'Wi-Fi 100Mbps', 'Refrigerator', 'Power Backup'],
    houseRules: ['18+ age requirement', 'Govt ID check at digital check-in', 'Couples allowed'],
    address: 'Plot 12A, Deer Park Road, Hauz Khas, New Delhi 110016',
    latitude: 28.5494,
    longitude: 77.1994,
    ownerName: 'Anita Gupta',
    ownerWhatsApp: '+919811223344',
    roomType: '1 RK',
    minStayDays: 2,
  },
  {
    id: 'room-noida-01',
    title: 'Furnished Executive Room near Cyber Park',
    city: 'Noida',
    area: 'Sector 62, Electronic City',
    pricePerDay: 750,
    monthlyDiscountPercent: 30,
    rating: 4.78,
    reviewCount: 31,
    images: [
      'https://images.unsplash.com/photo-1595526114035-0d45ed16cfbf?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=800&q=80'
    ],
    isInstantAvailable: true,
    bookedDates: ['2026-10-30'],
    amenities: ['Work Desk & Chair', 'AC', 'Daily Housekeeping', 'Elevator', 'Metro connectivity'],
    houseRules: ['Valid Photo ID mandatory', 'Strictly Non-smoking'],
    address: 'B-Block, Sector 62, Near Fortis Hospital, Noida 201309',
    latitude: 28.6279,
    longitude: 77.3653,
    ownerName: 'Ramesh Verma',
    ownerWhatsApp: '+919988776655',
    roomType: 'Single Room',
    minStayDays: 1,
  },
  {
    id: 'room-gurgaon-01',
    title: 'Spacious 1 BHK Flat in DLF Phase 3',
    city: 'Gurgaon',
    area: 'DLF Phase 3, Cyber City',
    pricePerDay: 1450,
    monthlyDiscountPercent: 20,
    rating: 4.90,
    reviewCount: 65,
    images: [
      'https://images.unsplash.com/photo-1560185007-cde436f6a4d0?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1502005229762-ee1b2b8ab32f?auto=format&fit=crop&w=800&q=80'
    ],
    isInstantAvailable: true,
    bookedDates: [],
    amenities: ['Smart TV', 'Modular Kitchen', 'Washing Machine', 'High Security Guard', 'Car Parking'],
    houseRules: ['ID mandatory for all guests', 'Family or Working professionals only'],
    address: 'U Block, DLF Phase 3, Gurugram 122002',
    latitude: 28.4986,
    longitude: 77.0945,
    ownerName: 'Kunal Kapoor',
    ownerWhatsApp: '+919712345678',
    roomType: '1 BHK',
    minStayDays: 3,
  }
];
