import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';

enum AuthMessageType { error, success }

/// Premium animated message banner for auth screens
/// Displays error/success messages with consistent styling and subtle animation
class AuthMessageBanner extends StatelessWidget {
  final String message;
  final AuthMessageType type;
  final VoidCallback? onActionPressed;
  final String? actionLabel;

  const AuthMessageBanner({
    super.key,
    required this.message,
    this.type = AuthMessageType.error,
    this.onActionPressed,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isError = type == AuthMessageType.error;

    final Color primaryColor = isError
        ? AppColors.redPrimary
        : const Color(0xFF10B981); // Emerald green for success

    final IconData icon = isError
        ? Icons.error_outline_rounded
        : Icons.check_circle_outline_rounded;

    return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: isDark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: primaryColor.withValues(alpha: isDark ? 0.3 : 0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: primaryColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: isDark
                            ? primaryColor.withValues(alpha: 0.9)
                            : primaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              if (onActionPressed != null && actionLabel != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: onActionPressed,
                    style: TextButton.styleFrom(
                      foregroundColor: primaryColor,
                      backgroundColor: primaryColor.withValues(alpha: 0.1),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    child: Text(
                      actionLabel!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        )
        .animate()
        .fade(duration: 200.ms, curve: Curves.easeOut)
        .slideY(begin: -0.1, end: 0, duration: 200.ms, curve: Curves.easeOut);
  }
}
