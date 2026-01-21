import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Base Background
          Container(
            color: isDark
                ? AppColors.backgroundDark
                : AppColors.backgroundLight,
          ),

          // Animated Orbs for Mesh Gradient Effect
          _PositionedOrb(
            top: -100,
            right: -50,
            size: 300,
            color: (isDark ? AppColors.goldPrimary : AppColors.goldLight)
                .withValues(alpha: 0.2),
          ),
          _PositionedOrb(
            bottom: -50,
            left: -50,
            size: 400,
            color: (isDark ? AppColors.bluePrimary : AppColors.blueLight)
                .withValues(alpha: 0.15),
          ),
          if (isDark)
            _PositionedOrb(
              top: 200,
              left: -100,
              size: 250,
              color: AppColors.redPrimary.withValues(alpha: 0.1),
            ),

          // Glass overlay for overall feel
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(color: Colors.transparent),
          ),

          // Content
          child,
        ],
      ),
    );
  }
}

class _PositionedOrb extends StatelessWidget {
  final double? top, bottom, left, right;
  final double size;
  final Color color;

  const _PositionedOrb({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child:
          Container(
                width: size,
                height: size,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .move(
                begin: const Offset(-20, -20),
                end: const Offset(20, 20),
                duration: 10.seconds,
                curve: Curves.easeInOut,
              )
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.1, 1.1),
                duration: 15.seconds,
                curve: Curves.easeInOut,
              ),
    );
  }
}
