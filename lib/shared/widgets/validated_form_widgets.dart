import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Accessible Form Field with inline validation, clear contrast and semantic accessibility
class ValidatedFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? errorText;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool isRequired;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  const ValidatedFormField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.errorText,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.isRequired = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label${isRequired ? ", required" : ""}',
      hint: hint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              if (isRequired)
                const Text(
                  ' *',
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            enabled: enabled,
            onChanged: onChanged,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              filled: true,
              fillColor: AppTheme.surfaceNavy,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: errorText != null ? Colors.redAccent : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: errorText != null ? Colors.redAccent : AppTheme.accentLime,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.redAccent),
              ),
            ),
          ),
          if (errorText != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 14),
                const SizedBox(width: 4),
                Text(
                  errorText!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Accessible Submit Button preventing duplicate submissions with loading feedback
class AsyncSubmitButton extends StatelessWidget {
  final String label;
  final bool isSubmitting;
  final bool isEnabled;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;

  const AsyncSubmitButton({
    super.key,
    required this.label,
    required this.isSubmitting,
    this.isEnabled = true,
    required this.onPressed,
    this.backgroundColor = AppTheme.accentLime,
    this.textColor = AppTheme.navyDark,
  });

  @override
  Widget build(BuildContext context) {
    final bool canClick = isEnabled && !isSubmitting;

    return Semantics(
      button: true,
      enabled: canClick,
      label: label,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: canClick ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canClick ? backgroundColor : backgroundColor.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: isSubmitting
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.navyDark),
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    color: canClick ? textColor : textColor.withValues(alpha: 0.5),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
        ),
      ),
    );
  }
}
