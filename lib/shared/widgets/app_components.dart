import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/room_model.dart';
import '../../models/booking_model.dart';

// ==========================================
// 1. APP HEADER & APP BAR
// ==========================================
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = false,
    this.onBack,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: navy,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textWhite, size: 20),
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            )
          : null,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: textWhite,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: -0.3,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: const TextStyle(
                color: muted,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// ==========================================
// 2. PRIMARY & SECONDARY BUTTONS
// ==========================================
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final IconData? icon;
  final double height;
  final Color? customColor;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.icon,
    this.height = 50,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    if (isSecondary) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: customColor ?? textWhite,
            side: BorderSide(color: (customColor ?? Colors.white).withValues(alpha: 0.24)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: lime, strokeWidth: 2),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: customColor ?? textWhite, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        color: customColor ?? textWhite,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
        ),
      );
    }

    return SizedBox(
      height: height,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: customColor ?? lime,
          foregroundColor: navy,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: navy, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: navy, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      color: navy,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ==========================================
// 3. APP CARD & CONTAINERS
// ==========================================
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final Border? border;
  final double borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.color,
    this.border,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          child: cardContent,
        ),
      );
    }
    return cardContent;
  }
}

// ==========================================
// 4. PRICE LABEL & RATING INDICATOR
// ==========================================
class AppPriceLabel extends StatelessWidget {
  final int amount;
  final String period;
  final double fontSize;
  final bool showBrokerageFreeBadge;

  const AppPriceLabel({
    super.key,
    required this.amount,
    this.period = '/night',
    this.fontSize = 20,
    this.showBrokerageFreeBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showBrokerageFreeBadge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              color: greenAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '0% BROKERAGE',
              style: TextStyle(color: greenAccent, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '₹$amount',
              style: TextStyle(
                color: lime,
                fontWeight: FontWeight.w900,
                fontSize: fontSize,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              period,
              style: TextStyle(
                color: muted,
                fontSize: fontSize * 0.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class AppRatingIndicator extends StatelessWidget {
  final double rating;
  final int? reviewsCount;
  final double size;

  const AppRatingIndicator({
    super.key,
    required this.rating,
    this.reviewsCount,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: surfaceLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: Colors.amber, size: size + 2),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              color: textWhite,
              fontWeight: FontWeight.bold,
              fontSize: size,
            ),
          ),
          if (reviewsCount != null) ...[
            const SizedBox(width: 3),
            Text(
              '($reviewsCount)',
              style: TextStyle(
                color: muted,
                fontSize: size * 0.9,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ==========================================
// 5. AMENITY CHIP & FILTER CHIP
// ==========================================
class AppAmenityChip extends StatelessWidget {
  final String label;
  final IconData? icon;

  const AppAmenityChip({
    super.key,
    required this.label,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon ?? Icons.check_circle_outline, color: lime, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: textWhite, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class AppFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;
  final IconData? icon;

  const AppFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: isSelected,
      onSelected: (_) => onSelected(),
      label: Text(label),
      avatar: icon != null ? Icon(icon, size: 14, color: isSelected ? navy : textWhite) : null,
      selectedColor: lime,
      backgroundColor: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? lime : Colors.white12),
      ),
      labelStyle: TextStyle(
        color: isSelected ? navy : textWhite,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }
}

// ==========================================
// 6. STATUS BADGE
// ==========================================
enum AppStatusType { confirmed, pending, completed, cancelled, rejected, active }

class AppStatusBadge extends StatelessWidget {
  final String label;
  final AppStatusType type;

  const AppStatusBadge({
    super.key,
    required this.label,
    this.type = AppStatusType.confirmed,
  });

  Color get _color {
    switch (type) {
      case AppStatusType.confirmed:
      case AppStatusType.active:
        return greenAccent;
      case AppStatusType.pending:
        return Colors.orangeAccent;
      case AppStatusType.completed:
        return Colors.blueAccent;
      case AppStatusType.cancelled:
      case AppStatusType.rejected:
        return coral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: _color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ==========================================
// 7. INPUT FIELDS & PASSWORD / OTP
// ==========================================
class AppInputField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;

  const AppInputField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: muted, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          onChanged: onChanged,
          readOnly: readOnly,
          onTap: onTap,
          style: const TextStyle(color: textWhite, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: muted.withValues(alpha: 0.5), fontSize: 14),
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: lime, size: 20) : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: lime, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: coral),
            ),
          ),
        ),
      ],
    );
  }
}

class AppPasswordField extends StatefulWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;

  const AppPasswordField({
    super.key,
    this.controller,
    this.label = 'Password',
    this.hint = 'Enter secure password',
    this.validator,
  });

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return AppInputField(
      controller: widget.controller,
      label: widget.label,
      hint: widget.hint,
      prefixIcon: Icons.lock_outline,
      obscureText: _obscure,
      validator: widget.validator,
      suffixIcon: IconButton(
        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: muted, size: 20),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    );
  }
}

class AppOtpField extends StatelessWidget {
  final List<TextEditingController> controllers;
  final void Function(String)? onCompleted;

  const AppOtpField({
    super.key,
    required this.controllers,
    this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(controllers.length, (index) {
        return SizedBox(
          width: 48,
          height: 56,
          child: TextFormField(
            controller: controllers[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: const TextStyle(color: lime, fontSize: 22, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: lime, width: 2)),
            ),
            onChanged: (val) {
              if (val.isNotEmpty && index < controllers.length - 1) {
                FocusScope.of(context).nextFocus();
              } else if (val.isEmpty && index > 0) {
                FocusScope.of(context).previousFocus();
              }
              if (onCompleted != null && controllers.every((c) => c.text.isNotEmpty)) {
                onCompleted!(controllers.map((c) => c.text).join());
              }
            },
          ),
        );
      }),
    );
  }
}

// ==========================================
// 8. SEARCH BAR & LOCATION SELECTOR
// ==========================================
class AppSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final VoidCallback? onTap;
  final void Function(String)? onChanged;
  final VoidCallback? onFilterTap;

  const AppSearchBar({
    super.key,
    this.controller,
    this.hint = 'Search by locality, area or landmark...',
    this.onTap,
    this.onChanged,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: TextField(
        controller: controller,
        readOnly: onTap != null,
        onTap: onTap,
        onChanged: onChanged,
        style: const TextStyle(color: textWhite, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: muted, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: lime, size: 20),
          suffixIcon: onFilterTap != null
              ? IconButton(
                  icon: const Icon(Icons.tune_rounded, color: lime, size: 20),
                  onPressed: onFilterTap,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class AppLocationSelector extends StatelessWidget {
  final String currentCity;
  final VoidCallback onTap;

  const AppLocationSelector({
    super.key,
    required this.currentCity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, color: lime, size: 16),
            const SizedBox(width: 4),
            Text(currentCity, style: const TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, color: muted, size: 16),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 9. GUEST COUNTER & DATE RANGE SELECTOR
// ==========================================
class AppGuestCounter extends StatelessWidget {
  final String label;
  final String? subtitle;
  final int count;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const AppGuestCounter({
    super.key,
    required this.label,
    this.subtitle,
    required this.count,
    this.min = 0,
    this.max = 10,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 14)),
            if (subtitle != null) Text(subtitle!, style: const TextStyle(color: muted, fontSize: 12)),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: muted, size: 24),
              onPressed: count > min ? () => onChanged(count - 1) : null,
            ),
            SizedBox(
              width: 32,
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(color: lime, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: lime, size: 24),
              onPressed: count < max ? () => onChanged(count + 1) : null,
            ),
          ],
        ),
      ],
    );
  }
}

class AppDateRangeSelector extends StatelessWidget {
  final String checkInDate;
  final String checkOutDate;
  final int nights;
  final VoidCallback onTap;

  const AppDateRangeSelector({
    super.key,
    required this.checkInDate,
    required this.checkOutDate,
    required this.nights,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_outlined, color: lime, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('STAY DATES', style: TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('$checkInDate – $checkOutDate', style: const TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: lime.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
              child: Text('$nights Night${nights > 1 ? 's' : ''}', style: const TextStyle(color: lime, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 10. SECTION HEADER & PROFILE AVATAR
// ==========================================
class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: textWhite,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: -0.3,
          ),
        ),
        if (actionText != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
            child: Text(actionText!, style: const TextStyle(color: lime, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }
}

class AppProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final bool isVerified;
  final VoidCallback? onTap;

  const AppProfileAvatar({
    super.key,
    this.imageUrl,
    this.radius = 24,
    this.isVerified = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: surfaceLight,
          backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
          child: imageUrl == null ? Icon(Icons.person, color: lime, size: radius * 1.1) : null,
        ),
        if (isVerified)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: navy, shape: BoxShape.circle),
              child: const Icon(Icons.verified, color: lime, size: 14),
            ),
          ),
      ],
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatar);
    }
    return avatar;
  }
}

// ==========================================
// 11. HORIZONTAL & VERTICAL ROOM CARDS
// ==========================================
class AppRoomCard extends StatelessWidget {
  final RoomModel room;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback onSave;

  const AppRoomCard({
    super.key,
    required this.room,
    required this.isSaved,
    required this.onTap,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    room.imageUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(height: 120, color: surfaceLight, child: const Icon(Icons.hotel, color: muted)),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(isSaved ? Icons.favorite : Icons.favorite_border, color: isSaved ? coral : Colors.white, size: 16),
                      onPressed: onSave,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(room.title, style: const TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('${room.locality}, ${room.city}', style: const TextStyle(color: muted, fontSize: 11), maxLines: 1),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('₹${room.pricePerNight}/n', style: const TextStyle(color: lime, fontWeight: FontWeight.bold, fontSize: 13)),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 12),
                          const SizedBox(width: 2),
                          Text('${room.rating}', style: const TextStyle(color: textWhite, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppHorizontalRoomCard extends StatelessWidget {
  final RoomModel room;
  final VoidCallback onTap;

  const AppHorizontalRoomCard({
    super.key,
    required this.room,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                room.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(width: 80, height: 80, color: surfaceLight, child: const Icon(Icons.hotel, color: muted)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(room.title, style: const TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('${room.locality}, ${room.city}', style: const TextStyle(color: muted, fontSize: 12)),
                  const SizedBox(height: 6),
                  Text('₹${room.pricePerNight} / night', style: const TextStyle(color: lime, fontWeight: FontWeight.w900, fontSize: 14)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: muted, size: 14),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 12. SUMMARY, TICKET CARD & EXTENSION OFFER CARD
// ==========================================
class AppBookingSummary extends StatelessWidget {
  final RoomModel room;
  final String checkInDate;
  final String checkOutDate;
  final int nights;
  final int guests;
  final int totalAmount;

  const AppBookingSummary({
    super.key,
    required this.room,
    required this.checkInDate,
    required this.checkOutDate,
    required this.nights,
    required this.guests,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(room.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(room.title, style: const TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('${room.locality}, ${room.city}', style: const TextStyle(color: muted, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 24),
          _buildRow('Check-in', checkInDate),
          const SizedBox(height: 6),
          _buildRow('Check-out', checkOutDate),
          const SizedBox(height: 6),
          _buildRow('Guests', '$guests Guests'),
          const SizedBox(height: 6),
          _buildRow('Total Paid (Escrow)', '₹$totalAmount', isHighlight: true),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: muted, fontSize: 13)),
        Text(value, style: TextStyle(color: isHighlight ? lime : textWhite, fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500, fontSize: 13)),
      ],
    );
  }
}

class AppPaymentSummary extends StatelessWidget {
  final int subtotal;
  final int taxes;
  final int platformFee;
  final int discount;
  final int grandTotal;

  const AppPaymentSummary({
    super.key,
    required this.subtotal,
    required this.taxes,
    required this.platformFee,
    required this.discount,
    required this.grandTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
      child: Column(
        children: [
          _row('Room Subtotal', '₹$subtotal'),
          const SizedBox(height: 8),
          _row('GST (5%)', '₹$taxes'),
          const SizedBox(height: 8),
          _row('Verified Stay Platform Fee', '₹$platformFee'),
          const SizedBox(height: 8),
          _row('Direct Booking Savings', '-₹$discount', color: greenAccent),
          const Divider(color: Colors.white12, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL PAYABLE', style: TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 14)),
              Text('₹$grandTotal', style: const TextStyle(color: lime, fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String title, String val, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: muted, fontSize: 13)),
        Text(val, style: TextStyle(color: color ?? textWhite, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class AppTicketCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback? onDirectionsTap;

  const AppTicketCard({
    super.key,
    required this.booking,
    this.onDirectionsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lime.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: surfaceLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DIGITAL STAY PASS', style: TextStyle(color: lime, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                    Text(booking.roomTitle, style: const TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: greenAccent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                  child: const Text('CONFIRMED', style: TextStyle(color: greenAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('DOOR PIN CODE', style: TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.bold)),
                        Text(booking.accessPin, style: const TextStyle(color: lime, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      ],
                    ),
                    if (onDirectionsTap != null)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: surfaceLight, foregroundColor: textWhite),
                        onPressed: onDirectionsTap,
                        icon: const Icon(Icons.navigation_outlined, size: 16, color: lime),
                        label: const Text('Directions', style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Check-in: ${booking.checkIn}', style: const TextStyle(color: muted, fontSize: 12)),
                    Text('Check-out: ${booking.checkOut}', style: const TextStyle(color: muted, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AppExtensionOfferCard extends StatelessWidget {
  final String roomTitle;
  final String currentCheckOut;
  final String proposedCheckOut;
  final int additionalAmount;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const AppExtensionOfferCard({
    super.key,
    required this.roomTitle,
    required this.currentCheckOut,
    required this.proposedCheckOut,
    required this.additionalAmount,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lime.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lock_clock, color: lime, size: 20),
              SizedBox(width: 8),
              Text('STAY EXTENSION PRIORITY', style: TextStyle(color: lime, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Extend your stay in $roomTitle until $proposedCheckOut for only ₹$additionalAmount (Zero Brokerage).', style: const TextStyle(color: textWhite, fontSize: 13, height: 1.4)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: muted, side: const BorderSide(color: Colors.white24)),
                  onPressed: onDecline,
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: lime, foregroundColor: navy),
                  onPressed: onAccept,
                  child: const Text('Accept Priority', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 13. REVIEW CARD & NOTIFICATION TILE
// ==========================================
class AppReviewCard extends StatelessWidget {
  final String author;
  final String date;
  final double rating;
  final String comment;

  const AppReviewCard({
    super.key,
    required this.author,
    required this.date,
    required this.rating,
    required this.comment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(author, style: const TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 13)),
              AppRatingIndicator(rating: rating, size: 12),
            ],
          ),
          const SizedBox(height: 2),
          Text(date, style: const TextStyle(color: muted, fontSize: 11)),
          const SizedBox(height: 8),
          Text(comment, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }
}

class AppNotificationTile extends StatelessWidget {
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final bool isUnread;
  final VoidCallback onTap;

  const AppNotificationTile({
    super.key,
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    this.isUnread = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isUnread ? surfaceLight : surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isUnread ? lime.withValues(alpha: 0.3) : Colors.white10),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: lime.withValues(alpha: 0.15),
          child: Icon(icon, color: lime, size: 20),
        ),
        title: Text(title, style: const TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(message, style: const TextStyle(color: muted, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(time, style: TextStyle(color: muted.withValues(alpha: 0.6), fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 14. BOTTOM SHEET & IMAGE GALLERY
// ==========================================
class AppBottomSheetContainer extends StatelessWidget {
  final String title;
  final Widget child;

  const AppBottomSheetContainer({
    super.key,
    required this.title,
    required this.child,
  });

  static Future<T?> show<T>(BuildContext context, {required String title, required Widget child}) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AppBottomSheetContainer(title: title, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(color: textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close, color: muted, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class AppImageGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const AppImageGallery({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  State<AppImageGallery> createState() => _AppImageGalleryState();
}

class _AppImageGalleryState extends State<AppImageGallery> {
  late PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: _currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: textWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('${_currentIndex + 1} / ${widget.images.length}', style: const TextStyle(color: textWhite, fontSize: 14)),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (context, index) {
          return Center(
            child: InteractiveViewer(
              child: Image.network(widget.images[index], fit: BoxFit.contain),
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// 15. PROGRESS, PAGINATION & CONFIRM DIALOG
// ==========================================
class AppUploadProgress extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String statusText;

  const AppUploadProgress({
    super.key,
    required this.progress,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(statusText, style: const TextStyle(color: textWhite, fontSize: 13, fontWeight: FontWeight.bold)),
              Text('${(progress * 100).toInt()}%', style: const TextStyle(color: lime, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: surfaceLight,
            valueColor: const AlwaysStoppedAnimation<Color>(lime),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

class AppLoadMorePagination extends StatelessWidget {
  final bool hasMore;
  final bool isLoading;
  final VoidCallback onLoadMore;

  const AppLoadMorePagination({
    super.key,
    required this.hasMore,
    required this.isLoading,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text('You have reached the end of listings', style: TextStyle(color: muted, fontSize: 12)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: isLoading
            ? const CircularProgressIndicator(color: lime, strokeWidth: 2)
            : OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: onLoadMore,
                icon: const Icon(Icons.arrow_downward, size: 16, color: lime),
                label: const Text('Load More Rooms', style: TextStyle(color: textWhite, fontSize: 13)),
              ),
      ),
    );
  }
}

class AppConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final bool isDestructive;

  const AppConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    required this.onConfirm,
    this.isDestructive = false,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AppConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        onConfirm: () => Navigator.pop(ctx, true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDestructive ? coral.withValues(alpha: 0.5) : Colors.white12),
      ),
      title: Text(title, style: const TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 18)),
      content: Text(message, style: const TextStyle(color: muted, fontSize: 13, height: 1.4)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel, style: const TextStyle(color: textWhite)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isDestructive ? coral : lime,
            foregroundColor: isDestructive ? textWhite : navy,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: onConfirm,
          child: Text(confirmLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

// ==========================================
// 16. SHIMMER SKELETON & EMPTY / ERROR STATES
// ==========================================
class AppSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const AppSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(
              const Color(0xFF1B2130),
              const Color(0xFF262E42),
              _controller.value,
            ),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surface,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white10),
              ),
              child: Icon(icon, color: lime, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: textWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: muted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: lime,
                  foregroundColor: navy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: onAction,
                child: Text(actionLabel!, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AppErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const AppErrorState({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: coral.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, color: coral, size: 42),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(color: textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 13)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: lime, foregroundColor: navy),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
