import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/contracts.dart';

/// Reusable Demo / Mock Mode Notice Banner (Never implies real money or bookings)
class MockModeBanner extends StatelessWidget {
  const MockModeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!ServiceConfig.isMockMode || !ServiceConfig.isDemoBannerVisible) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      color: Colors.amber.shade900.withValues(alpha: 0.9),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.science_outlined, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              ServiceConfig.demoDisclaimer,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Generic Async State Controller Widget for Loading, Loaded, Empty, and Error states
class AsyncStateBuilder<T> extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final T? data;
  final bool Function(T data)? isEmpty;
  final VoidCallback? onRetry;
  final Widget Function(BuildContext context, T data) builder;
  final Widget? loadingWidget;
  final Widget? emptyWidget;
  final String emptyMessage;

  const AsyncStateBuilder({
    super.key,
    required this.isLoading,
    this.errorMessage,
    required this.data,
    this.isEmpty,
    this.onRetry,
    required this.builder,
    this.loadingWidget,
    this.emptyWidget,
    this.emptyMessage = 'No items found matching your criteria.',
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return loadingWidget ??
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppTheme.accentLime),
            ),
          );
    }

    if (errorMessage != null && errorMessage!.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: Icon(Icons.refresh, size: 16, color: AppTheme.navyDark),
                  label: Text(
                    'Retry',
                    style: TextStyle(
                      color: AppTheme.navyDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentLime,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (data == null || (isEmpty != null && isEmpty!(data as T))) {
      return emptyWidget ??
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    color: Colors.white.withValues(alpha: 0.3),
                    size: 54,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    emptyMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
    }

    return builder(context, data as T);
  }
}
