import { IPaymentGateway, paymentGateway } from './services/paymentService';
import { IWhatsAppMessenger, whatsAppMessenger } from './services/whatsappService';
import { IMapsProvider, mapsProvider } from './providers/mapsProvider';
import { IIdentityVerificationProvider, verificationProvider } from './providers/verificationProvider';
import {
  IRoomRepository,
  IBookingRepository,
  IUserRepository,
  IExtensionOfferRepository,
} from './repositories/interfaces';
import {
  FirestoreRoomRepository,
  FirestoreBookingRepository,
  FirestoreUserRepository,
  FirestoreExtensionOfferRepository,
} from './repositories/firestoreRepositories';
import { IAuditService, auditService } from './audit/auditService';

export interface ServiceContainer {
  paymentGateway: IPaymentGateway;
  whatsAppMessenger: IWhatsAppMessenger;
  mapsProvider: IMapsProvider;
  verificationProvider: IIdentityVerificationProvider;
  roomRepo: IRoomRepository;
  bookingRepo: IBookingRepository;
  userRepo: IUserRepository;
  extensionOfferRepo: IExtensionOfferRepository;
  auditService: IAuditService;
}

export const container: ServiceContainer = {
  paymentGateway,
  whatsAppMessenger,
  mapsProvider,
  verificationProvider,
  roomRepo: new FirestoreRoomRepository(),
  bookingRepo: new FirestoreBookingRepository(),
  userRepo: new FirestoreUserRepository(),
  extensionOfferRepo: new FirestoreExtensionOfferRepository(),
  auditService,
};
