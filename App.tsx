import React, { useState } from 'react';
import {
  StyleSheet,
  Text,
  View,
  SafeAreaView,
  ScrollView,
  TextInput,
  TouchableOpacity,
  Image,
  FlatList,
  Modal,
  Alert,
  Linking,
} from 'react-native';
import { StatusBar } from 'expo-status-bar';
import { Ionicons, MaterialIcons, FontAwesome5 } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { Room, Booking, MOCK_ROOMS } from './src/types';
import { theme } from './src/theme';
import { getLiveLocationUrl, generateWhatsAppReceiptPayload, validateGuestIdentity } from './src/services/bookingService';

export default function App() {
  const [rooms, setRooms] = useState<Room[]>(MOCK_ROOMS);
  const [selectedCity, setSelectedCity] = useState<string>('All');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [activeTab, setActiveTab] = useState<'explore' | 'myBookings'>('explore');

  // Selected Room Modal
  const [selectedRoom, setSelectedRoom] = useState<Room | null>(null);

  // Booking Flow State
  const [bookingModalVisible, setBookingModalVisible] = useState(false);
  const [checkInDays, setCheckInDays] = useState(2);
  const [guestName, setGuestName] = useState('Rahul Kumar');
  const [guestPhone, setGuestPhone] = useState('9876543210');
  const [guestAge, setGuestAge] = useState('24');
  const [idType, setIdType] = useState<'Aadhaar Card' | 'Driving License' | 'Voter ID' | 'Passport'>('Aadhaar Card');
  const [idNumber, setIdNumber] = useState('8834 9102 3341');
  const [paymentProcessing, setPaymentProcessing] = useState(false);

  // Active User Bookings
  const [userBookings, setUserBookings] = useState<Booking[]>([]);
  const [confirmedBooking, setConfirmedBooking] = useState<Booking | null>(null);
  const [ticketModalVisible, setTicketModalVisible] = useState(false);

  // Filtered rooms
  const filteredRooms = rooms.filter((r) => {
    const matchesCity = selectedCity === 'All' || r.city.toLowerCase() === selectedCity.toLowerCase();
    const matchesSearch =
      r.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      r.area.toLowerCase().includes(searchQuery.toLowerCase()) ||
      r.city.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesCity && matchesSearch;
  });

  // Calculate booking pricing
  const calculateTotal = (room: Room, days: number) => {
    let subtotal = room.pricePerDay * days;
    if (days >= 30) {
      const discount = (subtotal * room.monthlyDiscountPercent) / 100;
      subtotal -= discount;
    }
    const taxes = Math.round(subtotal * 0.05); // 5% GST
    return { subtotal, taxes, grandTotal: subtotal + taxes };
  };

  // Handle Online Payment & Instant Booking Confirmation
  const handleProceedPayment = () => {
    if (!selectedRoom) return;

    // 1. Strict Age & ID Validation
    const ageNum = parseInt(guestAge, 10);
    const idValidation = validateGuestIdentity(ageNum, idType, idNumber);
    if (!idValidation.valid) {
      Alert.alert('Verification Issue', idValidation.error);
      return;
    }

    if (!guestName.trim() || guestPhone.trim().length < 10) {
      Alert.alert('Details Missing', 'Please enter full guest name and a valid 10-digit mobile number.');
      return;
    }

    setPaymentProcessing(true);

    // Simulate instant secure payment processing (Razorpay/UPI)
    setTimeout(() => {
      setPaymentProcessing(false);
      const bookingId = `RW-${Math.floor(100000 + Math.random() * 900000)}`;
      const accessCode = `RW${Math.floor(1000 + Math.random() * 9000)}`;
      const { grandTotal } = calculateTotal(selectedRoom, checkInDays);

      const today = new Date();
      const checkInDate = today.toISOString().split('T')[0];
      const checkOut = new Date(today);
      checkOut.setDate(today.getDate() + checkInDays);
      const checkOutDate = checkOut.toISOString().split('T')[0];

      const newBooking: Booking = {
        bookingId,
        roomId: selectedRoom.id,
        roomTitle: selectedRoom.title,
        roomAddress: selectedRoom.address,
        roomLocationUrl: getLiveLocationUrl(selectedRoom.latitude, selectedRoom.longitude, selectedRoom.title),
        customerName: guestName,
        customerPhone: guestPhone,
        customerAge: ageNum,
        idProofType: idType,
        idNumber: idNumber,
        idVerified: true,
        checkInDate,
        checkOutDate,
        totalDays: checkInDays,
        amountPaid: grandTotal,
        paymentMethod: 'UPI',
        paymentId: `pay_${Math.random().toString(36).substring(7).toUpperCase()}`,
        status: 'Confirmed',
        accessCode,
        priorityExtensionEligible: true,
        extensionDeadline: '24 hours prior to checkout',
        createdAt: new Date().toLocaleTimeString(),
      };

      // 2. Lock room date slot immediately so nobody else can double book it
      setRooms((prev) =>
        prev.map((r) =>
          r.id === selectedRoom.id
            ? { ...r, isInstantAvailable: false, bookedDates: [...r.bookedDates, checkInDate] }
            : r
        )
      );

      setUserBookings((prev) => [newBooking, ...prev]);
      setConfirmedBooking(newBooking);
      setBookingModalVisible(false);
      setTicketModalVisible(true);
    }, 1500);
  };

  // Open WhatsApp with automated pass
  const openWhatsAppDispatch = (booking: Booking) => {
    const matchedRoom = rooms.find((r) => r.id === booking.roomId) || MOCK_ROOMS[0];
    const { customerWhatsAppLink } = generateWhatsAppReceiptPayload(booking, matchedRoom);
    Linking.openURL(customerWhatsAppLink).catch(() => {
      Alert.alert('WhatsApp', 'WhatsApp is not installed or web link unavailable.');
    });
  };

  // Extend Stay Handler
  const handleExtendStay = (booking: Booking, extraDays: number) => {
    const additionalCost = 850 * extraDays;
    Alert.alert(
      'Stay Extension Priority Lock',
      `RoomWala VIP Priority: Extend ${extraDays} more days for ₹${additionalCost}? Your room will remain locked exclusively for you.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Confirm & Pay',
          onPress: () => {
            setUserBookings((prev) =>
              prev.map((b) =>
                b.bookingId === booking.bookingId
                  ? { ...b, totalDays: b.totalDays + extraDays, amountPaid: b.amountPaid + additionalCost, status: 'Extended' }
                  : b
              )
            );
            Alert.alert('🎉 Extension Confirmed', `Your booking ${booking.bookingId} has been successfully extended for ${extraDays} more days! Updated ticket dispatched to WhatsApp.`);
          },
        },
      ]
    );
  };

  return (
    <SafeAreaView style={styles.safeArea}>
      <StatusBar style="light" />

      {/* Top Header */}
      <View style={styles.header}>
        <View>
          <View style={styles.brandRow}>
            <LinearGradient
              colors={['#FF3366', '#FF6584']}
              style={styles.logoBadge}
            >
              <Ionicons name="home" size={18} color="#FFFFFF" />
            </LinearGradient>
            <Text style={styles.headerTitle}>Room<Text style={styles.headerHighlight}>Wala</Text></Text>
            <View style={styles.proTag}>
              <Text style={styles.proTagText}>2.0</Text>
            </View>
          </View>
          <Text style={styles.headerSubtitle}>Instant verified rooms • No owner chat</Text>
        </View>

        <TouchableOpacity
          style={[styles.bookingTabBtn, activeTab === 'myBookings' && styles.bookingTabBtnActive]}
          onPress={() => setActiveTab(activeTab === 'explore' ? 'myBookings' : 'explore')}
        >
          <Ionicons
            name={activeTab === 'explore' ? 'ticket-outline' : 'compass-outline'}
            size={18}
            color={activeTab === 'myBookings' ? '#FF3366' : '#FFFFFF'}
          />
          <Text style={styles.bookingTabBtnText}>
            {activeTab === 'explore' ? `Passes (${userBookings.length})` : 'Explore'}
          </Text>
        </TouchableOpacity>
      </View>

      {activeTab === 'explore' ? (
        <ScrollView style={styles.container} showsVerticalScrollIndicator={false}>
          {/* Search Bar */}
          <View style={styles.searchContainer}>
            <Ionicons name="search" size={20} color={theme.colors.textSecondary} style={{ marginRight: 8 }} />
            <TextInput
              style={styles.searchInput}
              placeholder="Search location (e.g. Delhi, Lajpat Nagar, Metro)..."
              placeholderTextColor={theme.colors.textMuted}
              value={searchQuery}
              onChangeText={setSearchQuery}
            />
            {searchQuery.length > 0 && (
              <TouchableOpacity onPress={() => setSearchQuery('')}>
                <Ionicons name="close-circle" size={18} color={theme.colors.textMuted} />
              </TouchableOpacity>
            )}
          </View>

          {/* City Selection Pills */}
          <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.cityPillsRow}>
            {['All', 'Delhi', 'Noida', 'Gurgaon', 'Bangalore', 'Mumbai'].map((city) => (
              <TouchableOpacity
                key={city}
                style={[styles.cityPill, selectedCity === city && styles.cityPillActive]}
                onPress={() => setSelectedCity(city)}
              >
                <Text style={[styles.cityPillText, selectedCity === city && styles.cityPillTextActive]}>
                  {city}
                </Text>
              </TouchableOpacity>
            ))}
          </ScrollView>

          {/* Quick Notice Banner */}
          <LinearGradient
            colors={['rgba(255, 51, 102, 0.15)', 'rgba(59, 130, 246, 0.15)']}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 0 }}
            style={styles.featureBanner}
          >
            <View style={styles.bannerIconCircle}>
              <FontAwesome5 name="bolt" size={16} color="#FF3366" />
            </View>
            <View style={{ flex: 1, marginLeft: 10 }}>
              <Text style={styles.bannerTitle}>Instant Slot Locking Active</Text>
              <Text style={styles.bannerDesc}>
                Room book karte hi Live Location & Entry Pass sidha aapke WhatsApp par aayegi. Owner call/chat ki koi jhanjhat nahi!
              </Text>
            </View>
          </LinearGradient>

          {/* Room Listings Section */}
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>
              {selectedCity === 'All' ? 'Available Rooms' : `Rooms in ${selectedCity}`}
            </Text>
            <Text style={styles.sectionCount}>{filteredRooms.length} verified</Text>
          </View>

          {filteredRooms.map((room) => (
            <TouchableOpacity
              key={room.id}
              activeOpacity={0.88}
              style={styles.roomCard}
              onPress={() => setSelectedRoom(room)}
            >
              <View style={styles.imageContainer}>
                <Image source={{ uri: room.images[0] }} style={styles.roomImage} />
                <LinearGradient
                  colors={['transparent', 'rgba(11, 13, 20, 0.95)']}
                  style={styles.imageOverlay}
                />
                
                {/* Instant Badge */}
                <View style={styles.instantBadge}>
                  <View style={styles.greenPulse} />
                  <Text style={styles.instantBadgeText}>Instant Ready</Text>
                </View>

                {/* Rating Badge */}
                <View style={styles.ratingBadge}>
                  <Ionicons name="star" size={13} color="#F59E0B" />
                  <Text style={styles.ratingText}>{room.rating}</Text>
                  <Text style={styles.reviewText}>({room.reviewCount})</Text>
                </View>

                {/* Price in Overlay */}
                <View style={styles.priceOverlay}>
                  <Text style={styles.priceNumber}>₹{room.pricePerDay}</Text>
                  <Text style={styles.pricePer}>/ day</Text>
                </View>
              </View>

              <View style={styles.cardContent}>
                <View style={styles.typeRow}>
                  <Text style={styles.roomTypeBadge}>{room.roomType}</Text>
                  <Text style={styles.roomAreaText}>📍 {room.area}</Text>
                </View>

                <Text style={styles.roomCardTitle} numberOfLines={1}>{room.title}</Text>

                {/* Amenities Badges */}
                <View style={styles.amenitiesRow}>
                  {room.amenities.slice(0, 3).map((item, idx) => (
                    <View key={idx} style={styles.amenityChip}>
                      <Text style={styles.amenityChipText}>{item}</Text>
                    </View>
                  ))}
                  {room.amenities.length > 3 && (
                    <View style={styles.amenityChip}>
                      <Text style={styles.amenityChipText}>+{room.amenities.length - 3} more</Text>
                    </View>
                  )}
                </View>

                {/* Footer Action */}
                <View style={styles.cardFooter}>
                  <View style={styles.kycNotice}>
                    <Ionicons name="shield-checkmark" size={14} color="#10B981" />
                    <Text style={styles.kycNoticeText}> 18+ Govt ID Verified Host</Text>
                  </View>

                  <TouchableOpacity
                    style={styles.bookQuickBtn}
                    onPress={() => {
                      setSelectedRoom(room);
                      setBookingModalVisible(true);
                    }}
                  >
                    <Text style={styles.bookQuickBtnText}>Book Room</Text>
                    <Ionicons name="chevron-forward" size={14} color="#FFFFFF" />
                  </TouchableOpacity>
                </View>
              </View>
            </TouchableOpacity>
          ))}
          <View style={{ height: 40 }} />
        </ScrollView>
      ) : (
        /* My Bookings / Digital Passes Screen */
        <ScrollView style={styles.container}>
          <View style={styles.passesHeader}>
            <Text style={styles.passesTitle}>My Room Passes & Tickets</Text>
            <Text style={styles.passesSubtitle}>
              Live digital room passes, WhatsApp delivery links, and Stay Extension priority.
            </Text>
          </View>

          {userBookings.length === 0 ? (
            <View style={styles.emptyContainer}>
              <Ionicons name="ticket-outline" size={64} color={theme.colors.textMuted} />
              <Text style={styles.emptyTitle}>Abhi Koi Booking Nahi Hai</Text>
              <Text style={styles.emptyDesc}>
                Aapne abhi koi room book nahi kiya hai. Explore section me jakar Delhi ya anya city me verified room book karein.
              </Text>
              <TouchableOpacity
                style={styles.exploreEmptyBtn}
                onPress={() => setActiveTab('explore')}
              >
                <Text style={styles.exploreEmptyBtnText}>Explore Rooms</Text>
              </TouchableOpacity>
            </View>
          ) : (
            userBookings.map((b) => (
              <View key={b.bookingId} style={styles.ticketCard}>
                <LinearGradient
                  colors={['#1E2235', '#161924']}
                  style={styles.ticketCardGradient}
                >
                  <View style={styles.ticketTopRow}>
                    <View>
                      <Text style={styles.ticketIdLabel}>BOOKING PASS</Text>
                      <Text style={styles.ticketIdVal}>{b.bookingId}</Text>
                    </View>
                    <View style={styles.ticketStatusBadge}>
                      <Text style={styles.ticketStatusText}>{b.status.toUpperCase()}</Text>
                    </View>
                  </View>

                  <Text style={styles.ticketRoomTitle}>{b.roomTitle}</Text>
                  <Text style={styles.ticketAddress}>📌 {b.roomAddress}</Text>

                  {/* Access Pin Box */}
                  <View style={styles.accessCodeBox}>
                    <View>
                      <Text style={styles.accessCodeLabel}>Digital Entry PIN</Text>
                      <Text style={styles.accessCodeVal}>{b.accessCode}</Text>
                    </View>
                    <TouchableOpacity
                      style={styles.mapPinBtn}
                      onPress={() => Linking.openURL(b.roomLocationUrl)}
                    >
                      <Ionicons name="navigate" size={16} color="#FFFFFF" />
                      <Text style={styles.mapPinBtnText}>Live Map</Text>
                    </TouchableOpacity>
                  </View>

                  {/* Dates & Guest info */}
                  <View style={styles.ticketInfoRow}>
                    <View>
                      <Text style={styles.infoRowLabel}>Check-In Date</Text>
                      <Text style={styles.infoRowVal}>{b.checkInDate}</Text>
                    </View>
                    <View>
                      <Text style={styles.infoRowLabel}>Total Stay</Text>
                      <Text style={styles.infoRowVal}>{b.totalDays} Days</Text>
                    </View>
                    <View>
                      <Text style={styles.infoRowLabel}>Amount Paid</Text>
                      <Text style={styles.infoRowVal}>₹{b.amountPaid}</Text>
                    </View>
                  </View>

                  {/* WhatsApp Pass Button */}
                  <TouchableOpacity
                    style={styles.whatsAppPassBtn}
                    onPress={() => openWhatsAppDispatch(b)}
                  >
                    <FontAwesome5 name="whatsapp" size={18} color="#FFFFFF" />
                    <Text style={styles.whatsAppPassBtnText}>Send Pass to WhatsApp</Text>
                  </TouchableOpacity>

                  {/* Stay Extension Priority Section */}
                  <View style={styles.extensionContainer}>
                    <View style={styles.extensionHeader}>
                      <Ionicons name="sparkles" size={16} color="#F59E0B" />
                      <Text style={styles.extensionTitle}>Stay Extension Priority Lock</Text>
                    </View>
                    <Text style={styles.extensionDesc}>
                      Kyunki aap is room me stay kar rahe hain, is room ko aage badhane ke liye aapko pehli preference hai!
                    </Text>
                    <View style={styles.extensionActionsRow}>
                      <TouchableOpacity
                        style={styles.extendOptionBtn}
                        onPress={() => handleExtendStay(b, 2)}
                      >
                        <Text style={styles.extendOptionText}>+2 Din Extend</Text>
                      </TouchableOpacity>
                      <TouchableOpacity
                        style={styles.extendOptionBtn}
                        onPress={() => handleExtendStay(b, 7)}
                      >
                        <Text style={styles.extendOptionText}>+1 Hafta Extend</Text>
                      </TouchableOpacity>
                      <TouchableOpacity
                        style={[styles.extendOptionBtn, { borderColor: '#10B981' }]}
                        onPress={() => handleExtendStay(b, 30)}
                      >
                        <Text style={[styles.extendOptionText, { color: '#10B981' }]}>+1 Month (25% OFF)</Text>
                      </TouchableOpacity>
                    </View>
                  </View>
                </LinearGradient>
              </View>
            ))
          )}
          <View style={{ height: 40 }} />
        </ScrollView>
      )}

      {/* ROOM DETAILS MODAL */}
      {selectedRoom && !bookingModalVisible && (
        <Modal
          visible={!!selectedRoom}
          animationType="slide"
          transparent={false}
          onRequestClose={() => setSelectedRoom(null)}
        >
          <SafeAreaView style={styles.safeArea}>
            <ScrollView style={styles.container}>
              {/* Image banner with back button */}
              <View style={styles.modalImageContainer}>
                <Image source={{ uri: selectedRoom.images[0] }} style={styles.modalHeroImage} />
                <TouchableOpacity
                  style={styles.modalCloseBtn}
                  onPress={() => setSelectedRoom(null)}
                >
                  <Ionicons name="arrow-back" size={22} color="#FFFFFF" />
                </TouchableOpacity>
                <View style={styles.modalPricePill}>
                  <Text style={styles.modalPriceText}>₹{selectedRoom.pricePerDay} / day</Text>
                </View>
              </View>

              <View style={styles.modalContent}>
                <View style={styles.typeRow}>
                  <Text style={styles.roomTypeBadge}>{selectedRoom.roomType}</Text>
                  <Text style={styles.roomAreaText}>📍 {selectedRoom.area}</Text>
                </View>
                <Text style={styles.modalTitle}>{selectedRoom.title}</Text>
                <Text style={styles.modalAddress}>{selectedRoom.address}</Text>

                {/* Rating & Reviews */}
                <View style={styles.ratingRow}>
                  <Ionicons name="star" size={16} color="#F59E0B" />
                  <Text style={styles.modalRatingText}>
                    {selectedRoom.rating} • {selectedRoom.reviewCount} Reviews • 100% Instant Available
                  </Text>
                </View>

                {/* Zero Chat Policy Notice */}
                <View style={styles.policyNoticeBox}>
                  <Ionicons name="flash" size={18} color="#FF3366" />
                  <View style={{ flex: 1, marginLeft: 10 }}>
                    <Text style={styles.policyTitle}>RoomWala Direct Dispatch Guarantee</Text>
                    <Text style={styles.policyDesc}>
                      Aapko room owner ko phone ya message karne ki zaroorat nahi hai. Payment karte hi Live GPS Location aur Digital Key Pass seedhe aapke WhatsApp par aa jayenge.
                    </Text>
                  </View>
                </View>

                {/* Amenities */}
                <Text style={styles.subSectionTitle}>What this room offers</Text>
                <View style={styles.modalAmenitiesGrid}>
                  {selectedRoom.amenities.map((item, idx) => (
                    <View key={idx} style={styles.modalAmenityItem}>
                      <Ionicons name="checkmark-circle" size={16} color="#10B981" />
                      <Text style={styles.modalAmenityLabel}>{item}</Text>
                    </View>
                  ))}
                </View>

                {/* House Rules */}
                <Text style={styles.subSectionTitle}>Important Rules & KYC</Text>
                {selectedRoom.houseRules.map((rule, idx) => (
                  <View key={idx} style={styles.ruleItem}>
                    <Ionicons name="information-circle-outline" size={16} color="#94A3B8" />
                    <Text style={styles.ruleText}>{rule}</Text>
                  </View>
                ))}

                <View style={{ height: 100 }} />
              </View>
            </ScrollView>

            {/* Bottom Floating Bar */}
            <View style={styles.modalBottomBar}>
              <View>
                <Text style={styles.barPriceLabel}>Total for 1 Day</Text>
                <Text style={styles.barPriceVal}>₹{selectedRoom.pricePerDay}</Text>
              </View>
              <TouchableOpacity
                style={styles.barBookBtn}
                onPress={() => setBookingModalVisible(true)}
              >
                <Text style={styles.barBookBtnText}>Instant Rent Now</Text>
                <Ionicons name="shield-checkmark" size={16} color="#FFFFFF" style={{ marginLeft: 6 }} />
              </TouchableOpacity>
            </View>
          </SafeAreaView>
        </Modal>
      )}

      {/* BOOKING & KYC CHECKOUT MODAL */}
      {selectedRoom && (
        <Modal
          visible={bookingModalVisible}
          animationType="slide"
          transparent={false}
          onRequestClose={() => setBookingModalVisible(false)}
        >
          <SafeAreaView style={styles.safeArea}>
            <View style={styles.modalHeader}>
              <TouchableOpacity onPress={() => setBookingModalVisible(false)}>
                <Ionicons name="close" size={24} color="#FFFFFF" />
              </TouchableOpacity>
              <Text style={styles.modalHeaderTitle}>Instant Booking & ID Check</Text>
              <View style={{ width: 24 }} />
            </View>

            <ScrollView style={styles.container}>
              {/* Room summary header */}
              <View style={styles.checkoutSummaryCard}>
                <Image source={{ uri: selectedRoom.images[0] }} style={styles.summaryThumbnail} />
                <View style={{ flex: 1, marginLeft: 12 }}>
                  <Text style={styles.summaryRoomTitle} numberOfLines={1}>{selectedRoom.title}</Text>
                  <Text style={styles.summaryRoomArea}>{selectedRoom.area}</Text>
                  <Text style={styles.summaryRoomPrice}>₹{selectedRoom.pricePerDay} / day</Text>
                </View>
              </View>

              {/* Step 1: Stay Duration */}
              <Text style={styles.checkoutSectionTitle}>1. Kitne Dino Ke Liye Chahiye?</Text>
              <View style={styles.daysSelectorRow}>
                {[1, 2, 5, 10, 30].map((days) => (
                  <TouchableOpacity
                    key={days}
                    style={[styles.daySelectBtn, checkInDays === days && styles.daySelectBtnActive]}
                    onPress={() => setCheckInDays(days)}
                  >
                    <Text style={[styles.daySelectText, checkInDays === days && styles.daySelectTextActive]}>
                      {days === 30 ? '1 Month (25% OFF)' : `${days} Day${days > 1 ? 's' : ''}`}
                    </Text>
                  </TouchableOpacity>
                ))}
              </View>

              {/* Step 2: KYC & 18+ Verification */}
              <Text style={styles.checkoutSectionTitle}>2. Guest Identity & 18+ Age Check</Text>
              <View style={styles.kycNoticeCard}>
                <Ionicons name="shield-half" size={20} color="#3B82F6" />
                <Text style={styles.kycNoticeCardText}>
                  Room security & legal compliance ke liye guest ki age kam se kam 18 saal honi chahiye aur valid government ID zaroori hai.
                </Text>
              </View>

              <View style={styles.inputGroup}>
                <Text style={styles.inputLabel}>Full Name (As per Govt ID)</Text>
                <TextInput
                  style={styles.textInput}
                  value={guestName}
                  onChangeText={setGuestName}
                  placeholder="Rahul Kumar"
                  placeholderTextColor="#64748B"
                />
              </View>

              <View style={styles.inputRow}>
                <View style={{ flex: 1, marginRight: 8 }}>
                  <Text style={styles.inputLabel}>Age (Minimum 18+)</Text>
                  <TextInput
                    style={styles.textInput}
                    value={guestAge}
                    onChangeText={setGuestAge}
                    keyboardType="numeric"
                    placeholder="24"
                    placeholderTextColor="#64748B"
                  />
                </View>
                <View style={{ flex: 1.5 }}>
                  <Text style={styles.inputLabel}>WhatsApp Mobile No.</Text>
                  <TextInput
                    style={styles.textInput}
                    value={guestPhone}
                    onChangeText={setGuestPhone}
                    keyboardType="phone-pad"
                    placeholder="9876543210"
                    placeholderTextColor="#64748B"
                  />
                </View>
              </View>

              {/* ID Type selector */}
              <Text style={styles.inputLabel}>Select Govt ID Proof</Text>
              <View style={styles.idTypeRow}>
                {(['Aadhaar Card', 'Driving License', 'Voter ID', 'Passport'] as const).map((type) => (
                  <TouchableOpacity
                    key={type}
                    style={[styles.idTypeBtn, idType === type && styles.idTypeBtnActive]}
                    onPress={() => setIdType(type)}
                  >
                    <Text style={[styles.idTypeText, idType === type && styles.idTypeTextActive]}>{type}</Text>
                  </TouchableOpacity>
                ))}
              </View>

              <View style={styles.inputGroup}>
                <Text style={styles.inputLabel}>{idType} Number</Text>
                <TextInput
                  style={styles.textInput}
                  value={idNumber}
                  onChangeText={setIdNumber}
                  placeholder="Enter Document ID Number"
                  placeholderTextColor="#64748B"
                />
              </View>

              {/* Price Breakdown */}
              <Text style={styles.checkoutSectionTitle}>3. Payment Summary</Text>
              {(() => {
                const { subtotal, taxes, grandTotal } = calculateTotal(selectedRoom, checkInDays);
                return (
                  <View style={styles.fareBreakdownCard}>
                    <View style={styles.fareRow}>
                      <Text style={styles.fareLabel}>Room Rent ({checkInDays} Days)</Text>
                      <Text style={styles.fareVal}>₹{subtotal}</Text>
                    </View>
                    <View style={styles.fareRow}>
                      <Text style={styles.fareLabel}>Taxes & Escrow Fee (5%)</Text>
                      <Text style={styles.fareVal}>₹{taxes}</Text>
                    </View>
                    <View style={styles.divider} />
                    <View style={styles.fareRow}>
                      <Text style={styles.totalFareLabel}>Total Amount Payable</Text>
                      <Text style={styles.totalFareVal}>₹{grandTotal}</Text>
                    </View>
                  </View>
                );
              })()}

              <View style={{ height: 110 }} />
            </ScrollView>

            {/* Pay Button */}
            <View style={styles.checkoutBottomBar}>
              <TouchableOpacity
                style={styles.payNowBtn}
                onPress={handleProceedPayment}
                disabled={paymentProcessing}
              >
                <LinearGradient
                  colors={['#FF3366', '#FF5376']}
                  style={styles.payBtnGradient}
                >
                  <Text style={styles.payBtnText}>
                    {paymentProcessing ? 'Locking Slot & Verifying ID...' : 'Pay & Confirm Instant Booking'}
                  </Text>
                  <Ionicons name="lock-closed" size={16} color="#FFFFFF" style={{ marginLeft: 8 }} />
                </LinearGradient>
              </TouchableOpacity>
            </View>
          </SafeAreaView>
        </Modal>
      )}

      {/* TICKET CONFIRMATION PASS MODAL */}
      {confirmedBooking && (
        <Modal
          visible={ticketModalVisible}
          animationType="fade"
          transparent={true}
          onRequestClose={() => setTicketModalVisible(false)}
        >
          <View style={styles.ticketBackdrop}>
            <View style={styles.ticketDialog}>
              <View style={styles.ticketSuccessIcon}>
                <Ionicons name="checkmark-circle" size={54} color="#10B981" />
              </View>
              <Text style={styles.ticketSuccessTitle}>Booking Confirmed & Locked!</Text>
              <Text style={styles.ticketSuccessSub}>
                Room slot ab kisi doosre user ke liye book nahi ho sakta.
              </Text>

              <View style={styles.ticketDialogBody}>
                <Text style={styles.passLabel}>PASS ID: {confirmedBooking.bookingId}</Text>
                <Text style={styles.passRoomName}>{confirmedBooking.roomTitle}</Text>
                <Text style={styles.passPinLabel}>Digital Entry PIN</Text>
                <Text style={styles.passPinCode}>{confirmedBooking.accessCode}</Text>

                <TouchableOpacity
                  style={styles.whatsAppDialogBtn}
                  onPress={() => openWhatsAppDispatch(confirmedBooking)}
                >
                  <FontAwesome5 name="whatsapp" size={18} color="#FFFFFF" style={{ marginRight: 8 }} />
                  <Text style={styles.whatsAppDialogBtnText}>Open Live Location on WhatsApp</Text>
                </TouchableOpacity>

                <TouchableOpacity
                  style={styles.viewPassesDialogBtn}
                  onPress={() => {
                    setTicketModalVisible(false);
                    setSelectedRoom(null);
                    setActiveTab('myBookings');
                  }}
                >
                  <Text style={styles.viewPassesDialogBtnText}>Go to My Passes & Stay Extension</Text>
                </TouchableOpacity>
              </View>
            </View>
          </View>
        </Modal>
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: theme.colors.background,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.cardBorder,
  },
  brandRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  logoBadge: {
    width: 28,
    height: 28,
    borderRadius: 8,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 8,
  },
  headerTitle: {
    fontSize: 22,
    fontWeight: '800',
    color: '#FFFFFF',
    letterSpacing: -0.5,
  },
  headerHighlight: {
    color: '#FF3366',
  },
  proTag: {
    backgroundColor: 'rgba(255, 51, 102, 0.2)',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 6,
    marginLeft: 6,
  },
  proTagText: {
    color: '#FF3366',
    fontSize: 10,
    fontWeight: '700',
  },
  headerSubtitle: {
    fontSize: 12,
    color: theme.colors.textMuted,
    marginTop: 2,
  },
  bookingTabBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#1E2235',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
  },
  bookingTabBtnActive: {
    borderColor: '#FF3366',
    backgroundColor: 'rgba(255, 51, 102, 0.1)',
  },
  bookingTabBtnText: {
    color: '#FFFFFF',
    fontSize: 12,
    fontWeight: '600',
    marginLeft: 6,
  },
  container: {
    flex: 1,
    paddingHorizontal: 16,
  },
  searchContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#161924',
    borderRadius: 12,
    paddingHorizontal: 14,
    height: 48,
    marginTop: 14,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.08)',
  },
  searchInput: {
    flex: 1,
    color: '#FFFFFF',
    fontSize: 14,
  },
  cityPillsRow: {
    marginTop: 12,
    marginBottom: 10,
  },
  cityPill: {
    paddingHorizontal: 14,
    paddingVertical: 7,
    borderRadius: 20,
    backgroundColor: '#161924',
    marginRight: 8,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.08)',
  },
  cityPillActive: {
    backgroundColor: '#FF3366',
    borderColor: '#FF3366',
  },
  cityPillText: {
    color: '#94A3B8',
    fontSize: 13,
    fontWeight: '600',
  },
  cityPillTextActive: {
    color: '#FFFFFF',
  },
  featureBanner: {
    flexDirection: 'row',
    borderRadius: 14,
    padding: 12,
    marginVertical: 10,
    borderWidth: 1,
    borderColor: 'rgba(255, 51, 102, 0.3)',
    alignItems: 'center',
  },
  bannerIconCircle: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: 'rgba(255, 51, 102, 0.2)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  bannerTitle: {
    color: '#FFFFFF',
    fontSize: 13,
    fontWeight: '700',
  },
  bannerDesc: {
    color: '#CBD5E1',
    fontSize: 11,
    lineHeight: 16,
    marginTop: 2,
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 8,
    marginBottom: 12,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: '#FFFFFF',
  },
  sectionCount: {
    fontSize: 12,
    color: '#94A3B8',
  },
  roomCard: {
    backgroundColor: '#161924',
    borderRadius: 16,
    marginBottom: 16,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.08)',
  },
  imageContainer: {
    width: '100%',
    height: 180,
    position: 'relative',
  },
  roomImage: {
    width: '100%',
    height: '100%',
  },
  imageOverlay: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 0,
    height: 80,
  },
  instantBadge: {
    position: 'absolute',
    top: 12,
    left: 12,
    backgroundColor: 'rgba(11, 13, 20, 0.85)',
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#10B981',
  },
  greenPulse: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: '#10B981',
    marginRight: 5,
  },
  instantBadgeText: {
    color: '#10B981',
    fontSize: 11,
    fontWeight: '700',
  },
  ratingBadge: {
    position: 'absolute',
    top: 12,
    right: 12,
    backgroundColor: 'rgba(11, 13, 20, 0.85)',
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 12,
  },
  ratingText: {
    color: '#FFFFFF',
    fontSize: 12,
    fontWeight: '700',
    marginLeft: 4,
  },
  reviewText: {
    color: '#94A3B8',
    fontSize: 10,
    marginLeft: 2,
  },
  priceOverlay: {
    position: 'absolute',
    bottom: 10,
    left: 14,
    flexDirection: 'row',
    alignItems: 'baseline',
  },
  priceNumber: {
    color: '#FFFFFF',
    fontSize: 22,
    fontWeight: '800',
  },
  pricePer: {
    color: '#CBD5E1',
    fontSize: 12,
    marginLeft: 4,
  },
  cardContent: {
    padding: 14,
  },
  typeRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 6,
  },
  roomTypeBadge: {
    color: '#FF3366',
    fontSize: 11,
    fontWeight: '700',
    backgroundColor: 'rgba(255, 51, 102, 0.15)',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
    marginRight: 8,
  },
  roomAreaText: {
    color: '#94A3B8',
    fontSize: 12,
  },
  roomCardTitle: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '700',
    marginBottom: 8,
  },
  amenitiesRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 6,
    marginBottom: 12,
  },
  amenityChip: {
    backgroundColor: 'rgba(255, 255, 255, 0.05)',
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 6,
  },
  amenityChipText: {
    color: '#CBD5E1',
    fontSize: 11,
  },
  cardFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    borderTopWidth: 1,
    borderTopColor: 'rgba(255, 255, 255, 0.06)',
    paddingTop: 10,
  },
  kycNotice: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  kycNoticeText: {
    color: '#10B981',
    fontSize: 11,
    fontWeight: '600',
  },
  bookQuickBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FF3366',
    paddingHorizontal: 14,
    paddingVertical: 7,
    borderRadius: 8,
  },
  bookQuickBtnText: {
    color: '#FFFFFF',
    fontSize: 12,
    fontWeight: '700',
    marginRight: 2,
  },
  modalImageContainer: {
    height: 260,
    width: '100%',
    position: 'relative',
  },
  modalHeroImage: {
    width: '100%',
    height: '100%',
  },
  modalCloseBtn: {
    position: 'absolute',
    top: 16,
    left: 16,
    backgroundColor: 'rgba(0,0,0,0.6)',
    width: 36,
    height: 36,
    borderRadius: 18,
    justifyContent: 'center',
    alignItems: 'center',
  },
  modalPricePill: {
    position: 'absolute',
    bottom: 16,
    right: 16,
    backgroundColor: 'rgba(11, 13, 20, 0.9)',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#FF3366',
  },
  modalPriceText: {
    color: '#FFFFFF',
    fontWeight: '700',
    fontSize: 14,
  },
  modalContent: {
    padding: 16,
  },
  modalTitle: {
    color: '#FFFFFF',
    fontSize: 20,
    fontWeight: '800',
    marginTop: 4,
  },
  modalAddress: {
    color: '#94A3B8',
    fontSize: 13,
    marginTop: 4,
  },
  ratingRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginVertical: 10,
  },
  modalRatingText: {
    color: '#CBD5E1',
    fontSize: 12,
    marginLeft: 6,
  },
  policyNoticeBox: {
    flexDirection: 'row',
    backgroundColor: 'rgba(255, 51, 102, 0.1)',
    borderWidth: 1,
    borderColor: 'rgba(255, 51, 102, 0.3)',
    borderRadius: 12,
    padding: 12,
    marginVertical: 12,
  },
  policyTitle: {
    color: '#FF3366',
    fontWeight: '700',
    fontSize: 13,
  },
  policyDesc: {
    color: '#CBD5E1',
    fontSize: 11,
    marginTop: 4,
    lineHeight: 16,
  },
  subSectionTitle: {
    color: '#FFFFFF',
    fontSize: 15,
    fontWeight: '700',
    marginTop: 14,
    marginBottom: 8,
  },
  modalAmenitiesGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  modalAmenityItem: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#161924',
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 8,
    marginRight: 6,
    marginBottom: 6,
  },
  modalAmenityLabel: {
    color: '#E2E8F0',
    fontSize: 12,
    marginLeft: 6,
  },
  ruleItem: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 6,
  },
  ruleText: {
    color: '#94A3B8',
    fontSize: 12,
    marginLeft: 8,
  },
  modalBottomBar: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    backgroundColor: '#161924',
    borderTopWidth: 1,
    borderTopColor: 'rgba(255, 255, 255, 0.1)',
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingVertical: 14,
  },
  barPriceLabel: {
    color: '#94A3B8',
    fontSize: 11,
  },
  barPriceVal: {
    color: '#FFFFFF',
    fontSize: 20,
    fontWeight: '800',
  },
  barBookBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FF3366',
    paddingHorizontal: 20,
    paddingVertical: 12,
    borderRadius: 12,
  },
  barBookBtnText: {
    color: '#FFFFFF',
    fontWeight: '700',
    fontSize: 14,
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 14,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255, 255, 255, 0.1)',
  },
  modalHeaderTitle: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '700',
  },
  checkoutSummaryCard: {
    flexDirection: 'row',
    backgroundColor: '#161924',
    padding: 12,
    borderRadius: 12,
    marginVertical: 12,
  },
  summaryThumbnail: {
    width: 60,
    height: 60,
    borderRadius: 8,
  },
  summaryRoomTitle: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '700',
  },
  summaryRoomArea: {
    color: '#94A3B8',
    fontSize: 12,
    marginTop: 2,
  },
  summaryRoomPrice: {
    color: '#FF3366',
    fontSize: 13,
    fontWeight: '700',
    marginTop: 4,
  },
  checkoutSectionTitle: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '700',
    marginTop: 14,
    marginBottom: 8,
  },
  daysSelectorRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  daySelectBtn: {
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 8,
    backgroundColor: '#161924',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
    marginRight: 6,
    marginBottom: 6,
  },
  daySelectBtnActive: {
    backgroundColor: '#FF3366',
    borderColor: '#FF3366',
  },
  daySelectText: {
    color: '#CBD5E1',
    fontSize: 12,
    fontWeight: '600',
  },
  daySelectTextActive: {
    color: '#FFFFFF',
  },
  kycNoticeCard: {
    flexDirection: 'row',
    backgroundColor: 'rgba(59, 130, 246, 0.1)',
    padding: 10,
    borderRadius: 8,
    marginBottom: 10,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: 'rgba(59, 130, 246, 0.3)',
  },
  kycNoticeCardText: {
    color: '#93C5FD',
    fontSize: 11,
    marginLeft: 8,
    flex: 1,
    lineHeight: 16,
  },
  inputGroup: {
    marginBottom: 12,
  },
  inputRow: {
    flexDirection: 'row',
    marginBottom: 12,
  },
  inputLabel: {
    color: '#94A3B8',
    fontSize: 12,
    marginBottom: 4,
  },
  textInput: {
    backgroundColor: '#161924',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 8,
    color: '#FFFFFF',
    fontSize: 13,
  },
  idTypeRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 6,
    marginBottom: 10,
  },
  idTypeBtn: {
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 6,
    backgroundColor: '#161924',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
    marginRight: 6,
    marginBottom: 6,
  },
  idTypeBtnActive: {
    backgroundColor: 'rgba(59, 130, 246, 0.2)',
    borderColor: '#3B82F6',
  },
  idTypeText: {
    color: '#94A3B8',
    fontSize: 11,
  },
  idTypeTextActive: {
    color: '#60A5FA',
    fontWeight: '700',
  },
  fareBreakdownCard: {
    backgroundColor: '#161924',
    padding: 14,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.08)',
  },
  fareRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 6,
  },
  fareLabel: {
    color: '#94A3B8',
    fontSize: 12,
  },
  fareVal: {
    color: '#CBD5E1',
    fontSize: 12,
  },
  divider: {
    height: 1,
    backgroundColor: 'rgba(255, 255, 255, 0.08)',
    marginVertical: 8,
  },
  totalFareLabel: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '700',
  },
  totalFareVal: {
    color: '#FF3366',
    fontSize: 16,
    fontWeight: '800',
  },
  checkoutBottomBar: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    backgroundColor: '#161924',
    padding: 16,
    borderTopWidth: 1,
    borderTopColor: 'rgba(255, 255, 255, 0.1)',
  },
  payNowBtn: {
    borderRadius: 12,
    overflow: 'hidden',
  },
  payBtnGradient: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    paddingVertical: 14,
  },
  payBtnText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '700',
  },
  ticketBackdrop: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.85)',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  ticketDialog: {
    backgroundColor: '#161924',
    width: '100%',
    borderRadius: 20,
    padding: 20,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
  },
  ticketSuccessIcon: {
    marginBottom: 10,
  },
  ticketSuccessTitle: {
    color: '#FFFFFF',
    fontSize: 18,
    fontWeight: '800',
    textAlign: 'center',
  },
  ticketSuccessSub: {
    color: '#94A3B8',
    fontSize: 12,
    textAlign: 'center',
    marginTop: 4,
    marginBottom: 14,
  },
  ticketDialogBody: {
    width: '100%',
    backgroundColor: '#0B0D14',
    padding: 14,
    borderRadius: 12,
    alignItems: 'center',
  },
  passLabel: {
    color: '#10B981',
    fontSize: 12,
    fontWeight: '700',
  },
  passRoomName: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '700',
    marginTop: 2,
    textAlign: 'center',
  },
  passPinLabel: {
    color: '#94A3B8',
    fontSize: 11,
    marginTop: 10,
  },
  passPinCode: {
    color: '#FF3366',
    fontSize: 24,
    fontWeight: '800',
    letterSpacing: 2,
  },
  whatsAppDialogBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#25D366',
    width: '100%',
    justifyContent: 'center',
    paddingVertical: 12,
    borderRadius: 10,
    marginTop: 14,
  },
  whatsAppDialogBtnText: {
    color: '#FFFFFF',
    fontSize: 13,
    fontWeight: '700',
  },
  viewPassesDialogBtn: {
    paddingVertical: 10,
    marginTop: 6,
  },
  viewPassesDialogBtnText: {
    color: '#94A3B8',
    fontSize: 12,
    textDecorationLine: 'underline',
  },
  passesHeader: {
    marginVertical: 14,
  },
  passesTitle: {
    color: '#FFFFFF',
    fontSize: 20,
    fontWeight: '800',
  },
  passesSubtitle: {
    color: '#94A3B8',
    fontSize: 12,
    marginTop: 4,
    lineHeight: 16,
  },
  emptyContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 60,
    paddingHorizontal: 20,
  },
  emptyTitle: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '700',
    marginTop: 12,
  },
  emptyDesc: {
    color: '#94A3B8',
    fontSize: 12,
    textAlign: 'center',
    marginTop: 6,
    lineHeight: 18,
  },
  exploreEmptyBtn: {
    backgroundColor: '#FF3366',
    paddingHorizontal: 20,
    paddingVertical: 10,
    borderRadius: 8,
    marginTop: 16,
  },
  exploreEmptyBtnText: {
    color: '#FFFFFF',
    fontSize: 13,
    fontWeight: '700',
  },
  ticketCard: {
    borderRadius: 16,
    overflow: 'hidden',
    marginBottom: 16,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.08)',
  },
  ticketCardGradient: {
    padding: 16,
  },
  ticketTopRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  ticketIdLabel: {
    color: '#94A3B8',
    fontSize: 10,
    fontWeight: '700',
  },
  ticketIdVal: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '800',
  },
  ticketStatusBadge: {
    backgroundColor: 'rgba(16, 185, 129, 0.15)',
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 6,
    borderWidth: 1,
    borderColor: '#10B981',
  },
  ticketStatusText: {
    color: '#10B981',
    fontSize: 10,
    fontWeight: '700',
  },
  ticketRoomTitle: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '700',
  },
  ticketAddress: {
    color: '#94A3B8',
    fontSize: 12,
    marginTop: 2,
  },
  accessCodeBox: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: 'rgba(0,0,0,0.3)',
    padding: 10,
    borderRadius: 8,
    marginVertical: 10,
  },
  accessCodeLabel: {
    color: '#94A3B8',
    fontSize: 10,
  },
  accessCodeVal: {
    color: '#FF3366',
    fontSize: 18,
    fontWeight: '800',
  },
  mapPinBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#3B82F6',
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 6,
  },
  mapPinBtnText: {
    color: '#FFFFFF',
    fontSize: 11,
    fontWeight: '700',
    marginLeft: 4,
  },
  ticketInfoRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    backgroundColor: 'rgba(255, 255, 255, 0.03)',
    padding: 10,
    borderRadius: 8,
    marginBottom: 10,
  },
  infoRowLabel: {
    color: '#94A3B8',
    fontSize: 10,
  },
  infoRowVal: {
    color: '#FFFFFF',
    fontSize: 12,
    fontWeight: '700',
    marginTop: 2,
  },
  whatsAppPassBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#25D366',
    paddingVertical: 10,
    borderRadius: 8,
    marginBottom: 12,
  },
  whatsAppPassBtnText: {
    color: '#FFFFFF',
    fontSize: 13,
    fontWeight: '700',
    marginLeft: 6,
  },
  extensionContainer: {
    backgroundColor: 'rgba(245, 158, 11, 0.08)',
    borderWidth: 1,
    borderColor: 'rgba(245, 158, 11, 0.3)',
    borderRadius: 10,
    padding: 10,
  },
  extensionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  extensionTitle: {
    color: '#F59E0B',
    fontSize: 12,
    fontWeight: '700',
    marginLeft: 4,
  },
  extensionDesc: {
    color: '#CBD5E1',
    fontSize: 10,
    marginVertical: 4,
    lineHeight: 14,
  },
  extensionActionsRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 6,
    marginTop: 4,
  },
  extendOptionBtn: {
    backgroundColor: 'rgba(255, 255, 255, 0.05)',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.15)',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 6,
    marginRight: 6,
  },
  extendOptionText: {
    color: '#FFFFFF',
    fontSize: 11,
    fontWeight: '600',
  },
});
