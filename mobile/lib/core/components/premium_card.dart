import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/animations.dart';

class PremiumCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool isGlass;
  final double delay;
  final BoxBorder? border;
  final bool enableAnimation;
  final double slideOffset;
  final Duration? animationDuration;

  const PremiumCard({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.padding,
    this.margin,
    this.isGlass = false,
    this.delay = 0,
    this.border,
    this.enableAnimation = true,
    this.slideOffset = 0.2, // Increased default for better visibility
    this.animationDuration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget cardContent = Container(
      padding: padding ?? const EdgeInsets.all(24), // Increased default padding
      decoration: BoxDecoration(
        color:
            color ?? (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
        borderRadius: BorderRadius.circular(24), // More rounded corners
        border:
            border ??
            (isGlass
                ? null
                : Border.all(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05),
                  )),
        boxShadow: isGlass
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                  spreadRadius: -5,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: -2,
                ),
              ],
      ),
      child: child,
    );

    if (isGlass) {
      cardContent = ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.5),
                width: 0.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: isDark ? 0.1 : 0.8),
                  Colors.white.withValues(alpha: isDark ? 0.05 : 0.5),
                ],
              ),
            ),
            child: cardContent,
          ),
        ),
      );
    }

    Widget animatedCard = enableAnimation
        ? cardContent
              .animate(delay: Duration(milliseconds: (delay * 1000).toInt()))
              .fade(
                duration: animationDuration ?? AppAnimations.defaultDuration,
                curve: AppAnimations.defaultCurve,
              )
              .slideY(
                begin: slideOffset,
                end: 0,
                duration: animationDuration ?? AppAnimations.defaultDuration,
                curve: AppAnimations.defaultCurve,
              )
        : cardContent;

    if (onTap != null) {
      return Padding(
        padding: margin ?? const EdgeInsets.symmetric(vertical: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: animatedCard,
          ),
        ),
      );
    }

    return Padding(
      padding: margin ?? const EdgeInsets.symmetric(vertical: 8),
      child: animatedCard,
    );
  }
}
