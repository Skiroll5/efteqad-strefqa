import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class PremiumBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isGlass;

  const PremiumBackButton({super.key, this.onPressed, this.isGlass = true});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child:
          IconButton(
            onPressed: onPressed ?? () => context.pop(),
            icon: Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.arrow_forward_ios_rounded
                  : Icons.arrow_back_ios_new_rounded,
              size: 20,
            ),
            color: isDark ? Colors.white70 : Colors.black54,
            style: IconButton.styleFrom(
              backgroundColor: isGlass
                  ? (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white.withValues(alpha: 0.8))
                  : Colors.transparent,
              padding: const EdgeInsets.all(12),
              shape: const CircleBorder(),
            ),
          ).animate().fade().slideX(
            begin: Directionality.of(context) == TextDirection.rtl ? 0.2 : -0.2,
            end: 0,
            duration: 400.ms,
            curve: Curves.easeOut,
          ),
    );
  }
}
