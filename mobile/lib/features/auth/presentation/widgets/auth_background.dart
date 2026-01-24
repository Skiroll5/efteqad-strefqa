import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Clean, professional background for auth screens
class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : const Color(0xFFF8F9FA),
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Professional, subtle gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        AppColors.vineyardBrown, // Deep warm black/brown
                        const Color(0xFF100B08), // Even darker bottom
                      ]
                    : [
                        const Color(
                          0xFFF0F4F8,
                        ), // Keep light mode clean for now, or adapt if requested
                        const Color(0xFFFFFFFF),
                      ],
              ),
            ),
          ),

          // Content
          SafeArea(child: child),
        ],
      ),
    );
  }
}
