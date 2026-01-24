import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';

enum AuthMessageType { error, success, warning }

/// Premium animated message banner for auth screens
/// Displays error/success/warning messages with glassmorphism styling and subtle animation
class AuthMessageBanner extends StatelessWidget {
  final String message;
  final AuthMessageType type;
  final VoidCallback? onActionPressed;
  final String? actionLabel;
  final VoidCallback? onDismiss;

  const AuthMessageBanner({
    super.key,
    required this.message,
    this.type = AuthMessageType.error,
    this.onActionPressed,
    this.actionLabel,
    this.onDismiss,
  });

  Color get _primaryColor {
    switch (type) {
      case AuthMessageType.error:
        return AppColors.redPrimary;
      case AuthMessageType.success:
        return const Color(0xFF10B981); // Emerald green
      case AuthMessageType.warning:
        return Colors.amber;
    }
  }

  IconData get _icon {
    switch (type) {
      case AuthMessageType.error:
        return Icons.error_outline_rounded;
      case AuthMessageType.success:
        return Icons.check_circle_outline_rounded;
      case AuthMessageType.warning:
        return Icons.warning_amber_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _primaryColor.withValues(alpha: isDark ? 0.2 : 0.12),
                    _primaryColor.withValues(alpha: isDark ? 0.1 : 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _primaryColor.withValues(alpha: isDark ? 0.4 : 0.25),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Animated icon
                      Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _primaryColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(_icon, color: _primaryColor, size: 16),
                          )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.05, 1.05),
                            duration: 1.seconds,
                          ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            message,
                            style: TextStyle(
                              color: isDark
                                  ? _primaryColor.withValues(alpha: 0.95)
                                  : _primaryColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),

                      if (onDismiss != null)
                        GestureDetector(
                          onTap: onDismiss,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: _primaryColor.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                    ],
                  ),

                  if (onActionPressed != null && actionLabel != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onActionPressed,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _primaryColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                actionLabel!,
                                style: TextStyle(
                                  color: _primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        )
        .animate()
        .fade(duration: 250.ms, curve: Curves.easeOut)
        .slideY(begin: -0.15, end: 0, duration: 250.ms, curve: Curves.easeOut)
        .shake(
          delay: 100.ms,
          duration: 300.ms,
          hz: 3,
          offset: const Offset(2, 0),
        );
  }
}
