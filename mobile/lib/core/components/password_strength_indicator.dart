import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  int _previousStrengthCount = 0;

  bool get hasMinLength => widget.password.length >= 8;
  bool get hasUppercase => widget.password.contains(RegExp(r'[A-Z]'));
  bool get hasLowercase => widget.password.contains(RegExp(r'[a-z]'));
  bool get hasDigits => widget.password.contains(RegExp(r'[0-9]'));

  int get strengthCount {
    int count = 0;
    if (hasMinLength) count++;
    if (hasUppercase) count++;
    if (hasLowercase) count++;
    if (hasDigits) count++;
    return count;
  }

  double get strengthPercent => strengthCount / 4.0;

  String getStrengthLabel(AppLocalizations l10n) {
    if (strengthCount <= 1) return l10n.atLeast8Chars;
    if (strengthCount <= 2) return l10n.atLeast1Upper;
    if (strengthCount <= 3) return l10n.atLeast1Digit;
    return l10n.password;
  }

  Color get strengthColor {
    if (strengthCount <= 1) return AppColors.redPrimary;
    if (strengthCount <= 2) return Colors.orange;
    if (strengthCount <= 3) return Colors.amber;
    return const Color(0xFF10B981); // Emerald Green
  }

  IconData get strengthIcon {
    if (strengthCount <= 1) return Icons.shield_outlined;
    if (strengthCount <= 2) return Icons.shield_outlined;
    if (strengthCount <= 3) return Icons.shield;
    return Icons.verified_user_rounded;
  }

  @override
  void didUpdateWidget(PasswordStrengthIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Haptic feedback when strength level changes
    final newStrength = strengthCount;
    if (newStrength != _previousStrengthCount) {
      if (newStrength > _previousStrengthCount) {
        HapticFeedback.lightImpact();
      }
      _previousStrengthCount = newStrength;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.compact) {
      return _buildCompactIndicator(l10n, isDark);
    }
    return _buildExpandedIndicator(l10n, isDark);
  }

  /// Compact single-line indicator - ideal when keyboard is open
  Widget _buildCompactIndicator(AppLocalizations l10n, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: strengthColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Strength icon with animation
          AnimatedContainer(
                duration: 200.ms,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: strengthColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(strengthIcon, size: 14, color: strengthColor),
              )
              .animate(key: ValueKey(strengthCount))
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                duration: 200.ms,
                curve: Curves.easeOutBack,
              ),

          const SizedBox(width: 10),

          // Progress bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Strength segments
                Row(
                  children: List.generate(4, (index) {
                    final isActive = index < strengthCount;
                    return Expanded(
                      child:
                          Container(
                                margin: EdgeInsets.only(
                                  right: index < 3 ? 3 : 0,
                                ),
                                height: 4,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
                                  color: isActive
                                      ? strengthColor
                                      : (isDark
                                            ? Colors.white12
                                            : Colors.grey.shade200),
                                  boxShadow: isActive
                                      ? [
                                          BoxShadow(
                                            color: strengthColor.withValues(
                                              alpha: 0.4,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ]
                                      : null,
                                ),
                              )
                              .animate(key: ValueKey('seg_${index}_$isActive'))
                              .fade(duration: 150.ms)
                              .scaleX(
                                begin: isActive ? 0.5 : 1,
                                end: 1,
                                duration: 200.ms,
                                curve: Curves.easeOut,
                              ),
                    );
                  }),
                ),

                const SizedBox(height: 4),

                // Requirements chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildMiniChip('8+', hasMinLength, isDark),
                      _buildMiniChip('A-Z', hasUppercase, isDark),
                      _buildMiniChip('a-z', hasLowercase, isDark),
                      _buildMiniChip('0-9', hasDigits, isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildMiniChip(String label, bool isMet, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isMet
            ? strengthColor.withValues(alpha: 0.15)
            : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isMet
              ? strengthColor.withValues(alpha: 0.3)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isMet) Icon(Icons.check, size: 10, color: strengthColor),
          if (isMet) const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
              color: isMet
                  ? strengthColor
                  : (isDark ? Colors.white38 : Colors.black38),
            ),
          ),
        ],
      ),
    );
  }

  /// Expanded indicator with full requirement labels
  Widget _buildExpandedIndicator(AppLocalizations l10n, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with strength icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: strengthColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(strengthIcon, size: 20, color: strengthColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$strengthCount/4',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: strengthColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: strengthPercent,
                        backgroundColor: isDark
                            ? Colors.white10
                            : Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(strengthColor),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Requirements Grid
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildRequirementChip(l10n.atLeast8Chars, hasMinLength, isDark),
              _buildRequirementChip(l10n.atLeast1Upper, hasUppercase, isDark),
              _buildRequirementChip(l10n.atLeast1Lower, hasLowercase, isDark),
              _buildRequirementChip(l10n.atLeast1Digit, hasDigits, isDark),
            ],
          ),
        ],
      ),
    ).animate().fade(duration: 200.ms);
  }

  Widget _buildRequirementChip(String label, bool isMet, bool isDark) {
    return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isMet
                ? strengthColor.withValues(alpha: 0.1)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.shade50),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isMet
                  ? strengthColor.withValues(alpha: 0.3)
                  : (isDark ? Colors.white12 : Colors.grey.shade200),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isMet ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 14,
                color: isMet
                    ? strengthColor
                    : (isDark ? Colors.white38 : Colors.black38),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
                  color: isMet
                      ? (isDark ? Colors.white : Colors.black87)
                      : (isDark ? Colors.white38 : Colors.black38),
                ),
              ),
            ],
          ),
        )
        .animate(target: isMet ? 1 : 0)
        .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: 150.ms,
        );
  }
}
