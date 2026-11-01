import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum ErrorRecoveryType {
  noInternet,
  serverUnavailable,
  sessionExpired,
  permissionDenied,
  listingUnavailable,
  bookingConflict,
  holdExpired,
  paymentPending,
  paymentFailed,
  verificationRejected,
  genericUnexpected,
}

class ErrorRecoveryConfig {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final String primaryButtonLabel;
  final IconData? primaryButtonIcon;
  final String? secondaryButtonLabel;

  const ErrorRecoveryConfig({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.primaryButtonLabel,
    this.primaryButtonIcon,
    this.secondaryButtonLabel,
  });

  static ErrorRecoveryConfig fromType(ErrorRecoveryType type) {
    switch (type) {
      case ErrorRecoveryType.noInternet:
        return const ErrorRecoveryConfig(
          title: 'No Internet Connection',
          description: 'We could not reach the My Roomy network. Please check your Wi-Fi or cellular mobile data connection.',
          icon: Icons.wifi_off_rounded,
          iconColor: Colors.amberAccent,
          primaryButtonLabel: 'Try Reconnecting',
          primaryButtonIcon: Icons.refresh,
          secondaryButtonLabel: 'Open Offline Passes',
        );

      case ErrorRecoveryType.serverUnavailable:
        return const ErrorRecoveryConfig(
          title: 'My Roomy Servers Busy',
          description: 'Our real-time room lock and discovery service is temporarily experiencing high latency. Our engineers are investigating.',
          icon: Icons.cloud_off_rounded,
          iconColor: Colors.orangeAccent,
          primaryButtonLabel: 'Check Status & Retry',
          primaryButtonIcon: Icons.replay,
          secondaryButtonLabel: 'Contact Live Desk',
        );

      case ErrorRecoveryType.sessionExpired:
        return const ErrorRecoveryConfig(
          title: 'Session Expired',
          description: 'For your security and door-access protection, your active session has expired. Please sign in again with OTP.',
          icon: Icons.lock_clock_rounded,
          iconColor: lime,
          primaryButtonLabel: 'Sign In with Phone',
          primaryButtonIcon: Icons.login,
          secondaryButtonLabel: 'Cancel',
        );

      case ErrorRecoveryType.permissionDenied:
        return const ErrorRecoveryConfig(
          title: 'Permission Denied',
          description: 'Location or camera permission is required to detect nearby verified rooms and complete Aadhaar live facial match.',
          icon: Icons.security_rounded,
          iconColor: coral,
          primaryButtonLabel: 'Grant App Permissions',
          primaryButtonIcon: Icons.settings,
          secondaryButtonLabel: 'Go Back',
        );

      case ErrorRecoveryType.listingUnavailable:
        return const ErrorRecoveryConfig(
          title: 'Listing No Longer Available',
          description: 'The host has paused this room or it has just been booked by another guest. Discover similar verified rooms nearby.',
          icon: Icons.home_work_outlined,
          iconColor: Colors.amber,
          primaryButtonLabel: 'Explore Similar Rooms',
          primaryButtonIcon: Icons.search,
          secondaryButtonLabel: 'Return to Discovery',
        );

      case ErrorRecoveryType.bookingConflict:
        return const ErrorRecoveryConfig(
          title: 'Booking Dates Conflict',
          description: 'The requested check-in and check-out dates overlap with an existing confirmed stay or host maintenance window.',
          icon: Icons.event_busy_rounded,
          iconColor: coral,
          primaryButtonLabel: 'Select Different Dates',
          primaryButtonIcon: Icons.calendar_month,
          secondaryButtonLabel: 'View Other Rooms',
        );

      case ErrorRecoveryType.holdExpired:
        return const ErrorRecoveryConfig(
          title: 'Temporary Hold Expired',
          description: 'The 10-minute payment reservation window has expired. The room has been unlocked for other prospective guests.',
          icon: Icons.timer_off_outlined,
          iconColor: Colors.orange,
          primaryButtonLabel: 'Re-Hold This Room',
          primaryButtonIcon: Icons.lock_outline,
          secondaryButtonLabel: 'Back to Room Details',
        );

      case ErrorRecoveryType.paymentPending:
        return const ErrorRecoveryConfig(
          title: 'Payment Under Verification',
          description: 'Your UPI/Card transaction is awaiting bank clearing. Please do not re-pay. We will update your booking status within 5 minutes.',
          icon: Icons.hourglass_top_rounded,
          iconColor: Colors.blueAccent,
          primaryButtonLabel: 'Check Payment Status',
          primaryButtonIcon: Icons.sync,
          secondaryButtonLabel: 'View My Bookings',
        );

      case ErrorRecoveryType.paymentFailed:
        return const ErrorRecoveryConfig(
          title: 'Payment Unsuccessful',
          description: 'The bank or UPI provider rejected the transaction. No funds were captured. You can retry with an alternate UPI ID or card.',
          icon: Icons.payment_outlined,
          iconColor: coral,
          primaryButtonLabel: 'Retry Payment',
          primaryButtonIcon: Icons.replay,
          secondaryButtonLabel: 'Change Payment Method',
        );

      case ErrorRecoveryType.verificationRejected:
        return const ErrorRecoveryConfig(
          title: 'Identity Verification Needs Attention',
          description: 'Government ID verification was not approved because the uploaded document was blurry or name mismatched.',
          icon: Icons.badge_outlined,
          iconColor: coral,
          primaryButtonLabel: 'Re-submit Government ID',
          primaryButtonIcon: Icons.camera_alt,
          secondaryButtonLabel: 'Support Desk Assistance',
        );

      case ErrorRecoveryType.genericUnexpected:
return const ErrorRecoveryConfig(
          title: 'Unexpected Error Occurred',
          description: 'Something didn\'t work as expected. Our telemetry team has logged the event. Tap below to refresh.',
          icon: Icons.error_outline_rounded,
          iconColor: coral,
          primaryButtonLabel: 'Reload Screen',
          primaryButtonIcon: Icons.refresh,
          secondaryButtonLabel: 'Return Home',
        );
    }
  }
}

class ErrorRecoveryScreen extends StatelessWidget {
  final ErrorRecoveryType errorType;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSecondaryAction;
  final String? customMessage;

  const ErrorRecoveryScreen({
    super.key,
    required this.errorType,
    this.onPrimaryAction,
    this.onSecondaryAction,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    final config = ErrorRecoveryConfig.fromType(errorType);

    return Scaffold(
      backgroundColor: navy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.close, color: textWhite),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Circular Animated Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: config.iconColor.withValues(alpha: 0.12),
                  border: Border.all(color: config.iconColor.withValues(alpha: 0.35), width: 2),
                ),
                child: Center(
                  child: Icon(config.icon, size: 50, color: config.iconColor),
                ),
              ),

              const SizedBox(height: 28),

              // Title
              Text(
                config.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: textWhite,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 14),

              // Description
              Text(
                customMessage ?? config.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: muted,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              // Escrow & Zero-Broker Guarantee Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, color: lime, size: 16),
                    SizedBox(width: 8),
                    Text(
                      '100% Protected by My Roomy Escrow',
                      style: TextStyle(color: textWhite, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Primary Recovery Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: lime,
                    foregroundColor: navy,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    if (onPrimaryAction != null) {
                      onPrimaryAction!();
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  icon: Icon(config.primaryButtonIcon ?? Icons.arrow_forward, size: 20),
                  label: Text(
                    config.primaryButtonLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),

              if (config.secondaryButtonLabel != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textWhite,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      if (onSecondaryAction != null) {
                        onSecondaryAction!();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: Text(
                      config.secondaryButtonLabel!,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

