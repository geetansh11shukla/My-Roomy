export type TicketPriority = 'low' | 'medium' | 'high' | 'urgent';
export type TicketStatus = 'open' | 'in_progress' | 'waiting_user' | 'resolved' | 'closed';

export interface SupportTicketDocument {
  ticketId: string;
  userId: string;
  bookingId: string | null;
  category: 'booking' | 'payment' | 'host' | 'cancellation' | 'app_bug' | 'general';
  subject: string;
  description: string;
  attachmentUrls: string[];
  priority: TicketPriority;
  status: TicketStatus;
  assignedAdminId: string | null;
  resolution: string | null;
  createdAt: string;
  updatedAt: string;
  resolvedAt: string | null;
}

export interface SupportReply {
  replyId: string;
  ticketId: string;
  senderId: string;
  senderRole: 'customer' | 'owner' | 'admin';
  message: string;
  attachmentUrls: string[];
  createdAt: string;
}

export interface ReportDocument {
  reportId: string;
  reporterId: string;
  targetType: 'room' | 'user';
  targetId: string;
  reportCategory: 'misleading_listing' | 'fraud' | 'harassment' | 'property_damage' | 'other';
  description: string;
  evidenceReferences: string[];
  reviewStatus: 'pending' | 'under_review' | 'action_taken' | 'dismissed';
  assignedReviewer: string | null;
  resolution: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface CreateSupportTicketInput {
  userId: string;
  bookingId?: string | null;
  category: SupportTicketDocument['category'];
  subject: string;
  description: string;
  attachmentUrls?: string[];
  priority?: TicketPriority;
}

export interface CreateReportInput {
  reporterId: string;
  targetType: 'room' | 'user';
  targetId: string;
  reportCategory: ReportDocument['reportCategory'];
  description: string;
  evidenceReferences?: string[];
}

