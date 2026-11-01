export interface IWhatsAppMessenger {
  sendBookingTicket(toPhone: string, roomTitle: string, checkIn: string, digitalPin: string, mapUrl: string): Promise<boolean>;
  sendCheckoutReminder(toPhone: string, roomTitle: string, checkOut: string, extensionLink: string): Promise<boolean>;
  sendNotification(toPhone: string, message: string): Promise<boolean>;
}

export class WhatsAppBusinessService implements IWhatsAppMessenger {
  private apiToken: string;
  private phoneNumberId: string;
  private isConfigured: boolean;

  constructor() {
    this.apiToken = process.env.WHATSAPP_CLOUD_API_TOKEN || '';
    this.phoneNumberId = process.env.WHATSAPP_PHONE_NUMBER_ID || '';
    this.isConfigured = Boolean(this.apiToken && this.phoneNumberId);
  }

  async sendBookingTicket(
    toPhone: string,
    roomTitle: string,
    checkIn: string,
    digitalPin: string,
    mapUrl: string
  ): Promise<boolean> {
    const cleanPhone = toPhone.replace(/\D/g, '');

    if (!this.isConfigured) {
      console.log(`[WhatsApp Business Sandbox Log]`);
      console.log(`  To: +${cleanPhone}`);
      console.log(`  Message: Your RoomWala booking for ${roomTitle} is confirmed!`);
      console.log(`  Check-In: ${checkIn}`);
      console.log(`  Digital Door PIN: ${digitalPin}`);
      console.log(`  Location Directions: ${mapUrl}`);
      console.log(`  (WhatsApp Cloud API Token not provided. Simulated delivery.)`);
      return true;
    }

    try {
      // Production Cloud API Dispatch
      const payload = {
        messaging_product: 'whatsapp',
        to: cleanPhone,
        type: 'template',
        template: {
          name: 'booking_confirmation_ticket',
          language: { code: 'en' },
          components: [
            {
              type: 'body',
              parameters: [
                { type: 'text', text: roomTitle },
                { type: 'text', text: checkIn },
                { type: 'text', text: digitalPin },
                { type: 'text', text: mapUrl },
              ],
            },
          ],
        },
      };

      const response = await fetch(`https://graph.facebook.com/v19.0/${this.phoneNumberId}/messages`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${this.apiToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
      });

      return response.ok;
    } catch (e) {
      console.error('[WhatsApp Cloud API Error]:', e);
      return false;
    }
  }

  async sendCheckoutReminder(toPhone: string, roomTitle: string, checkOut: string, extensionLink: string): Promise<boolean> {
    const cleanPhone = toPhone.replace(/\D/g, '');
    if (!this.isConfigured) {
      console.log(`[WhatsApp Reminder Sandbox Log]`);
      console.log(`  To: +${cleanPhone}`);
      console.log(`  Message: Reminder: Checkout scheduled for ${checkOut} at ${roomTitle}.`);
      console.log(`  Extend Stay Priority: ${extensionLink}`);
      return true;
    }
    return true;
  }

  async sendNotification(toPhone: string, message: string): Promise<boolean> {
    const cleanPhone = toPhone.replace(/\D/g, '');
    if (!this.isConfigured) {
      console.log(`[WhatsApp Notification Sandbox Log]`);
      console.log(`  To: +${cleanPhone}`);
      console.log(`  Message: ${message}`);
      return true;
    }
    return true;
  }
}

export const whatsAppMessenger = new WhatsAppBusinessService();

