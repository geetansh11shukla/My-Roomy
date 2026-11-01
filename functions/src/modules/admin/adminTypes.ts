export interface AdminDashboardMetrics {
  registeredCustomers: number;
  registeredOwners: number;
  activeListings: number;
  pendingRoomApprovals: number;
  confirmedBookings: number;
  cancelledBookings: number;
  grossPaymentVolumePaise: number;
  reconciliationDiscrepanciesCount: number;
  pendingRefundsCount: number;
  pendingIdentityReviewsCount: number;
  openSupportTicketsCount: number;
  activeExtensionOffersCount: number;
  expiredExtensionOffersCount: number;
  computedAt: string;
}

export interface AdminUserQueryFilters {
  role?: 'customer' | 'owner' | 'admin';
  accountStatus?: 'active' | 'suspended' | 'pending_deletion' | 'deleted';
  limit?: number;
}

export interface AdminRoomApprovalAction {
  roomId: string;
  adminId: string;
  action: 'approve' | 'reject';
  rejectionReason?: string;
}

export interface AdminRefundReviewInput {
  refundId: string;
  adminId: string;
  action: 'approve' | 'reject';
  notes?: string;
}

export interface AppConfigDocument {
  configId: string;
  platformFeePercentage: number;
  defaultGstPercentage: number;
  minBookingAdvanceHours: number;
  defaultCancellationPolicyId: string;
  extensionOfferDiscountPercent: number;
  maintenanceMode: boolean;
  updatedBy: string;
  updatedAt: string;
}

