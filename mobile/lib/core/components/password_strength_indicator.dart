import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/core/theme/app_colors.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final bool compact;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.compact = true,
  });

  bool get hasMinLength => password.length >= 8;
  bool get hasUppercase => password.contains(RegExp(r'[A-Z]'));
  bool get hasLowercase => password.contains(RegExp(r'[a-z]'));
  bool get hasDigits => password.contains(RegExp(r'[0-9]'));

  int get strengthCount {
    int count = 0;
    if (hasMinLength) count++;
    if (hasUppercase) count++;
    if (hasLowercase) count++;
    if (hasDigits) count++;
    return count;
  }

  double get strengthPercent => strengthCount / 4.0;

  Color get strengthColor {
    if (strengthCount <= 1) return AppColors.redPrimary;
    if (strengthCount <= 2) return Colors.orange;
    if (strengthCount <= 3) return Colors.yellow[700]!;
    return const Color(0xFF10B981); // Emerald Green
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress Bar
        Stack(
          children: [
            Container(
              height: 4,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey[200],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            AnimatedFractionallySizedBox(
              duration: 300.ms,
              curve: Curves.easeOut,
              widthFactor: strengthPercent == 0 ? 0.05 : strengthPercent,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: strengthColor,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: strengthColor.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Requirements Row/Grid
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            _buildChip(l10n.atLeast8Chars, hasMinLength, isDark),
            _buildChip(l10n.atLeast1Upper, hasUppercase, isDark),
            _buildChip(l10n.atLeast1Lower, hasLowercase, isDark),
            _buildChip(l10n.atLeast1Digit, hasDigits, isDark),
          ],
        ),
      ],
    ).animate().fade();
  }

  Widget _buildChip(String label, bool isMet, bool isDark) {
    final color = isMet
        ? (isDark ? Colors.white : Colors.black87)
        : (isDark ? Colors.white38 : Colors.black38);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isMet ? Icons.check : Icons.circle,
          size: isMet ? 14 : 4,
          color: isMet
              ? strengthColor
              : (isDark ? Colors.white24 : Colors.black26),
        ).animate(target: isMet ? 1 : 0).scale(),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
