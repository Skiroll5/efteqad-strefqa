import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart'; // Add this
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/core/theme/app_colors.dart';

/// Premium password strength indicator with compact design
/// Designed to stay visible even when keyboard is open
class PasswordStrengthIndicator extends StatefulWidget {
  final String password;
  final bool compact;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.compact = true,
  });

  @override
  State<PasswordStrengthIndicator> createState() =>
      _PasswordStrengthIndicatorState();
}

class _PasswordStrengthIndicatorState extends State<PasswordStrengthIndicator> {
  bool get isValid => widget.password.length >= 8;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // final isDark = Theme.of(context).brightness == Brightness.dark; // Unused

    // Only show if NOT valid and NOT empty (validation error style)
    if (widget.password.isEmpty || isValid) {
      return const SizedBox.shrink();
    }

    // If we are here, it means it's invalid and user has typed something
    final color = AppColors.redPrimary;
    const icon = Icons.error_outline;

    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ).animate().scale(curve: Curves.easeOutBack),
          const SizedBox(width: 6),
          Text(
            l10n.atLeast8Chars,
            style: GoogleFonts.cairo(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ).animate().fade().slideY(begin: -0.1, end: 0);
  }
}
