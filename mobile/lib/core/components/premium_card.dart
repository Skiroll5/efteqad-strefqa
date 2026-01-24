import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/animations.dart';

class PremiumCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double delay;
  final bool isGlass;
  final bool enableAnimation;
  final Color? color;
  final BoxBorder? border;
  final double? slideOffset;
  final Duration? animationDuration;
  final double? borderRadius;

  const PremiumCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.delay = 0,
    this.isGlass = false,
    this.enableAnimation = true,
    this.color,
    this.border,
    this.slideOffset,
    this.animationDuration,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget cardContent;
    final effectiveBorderRadius = borderRadius ?? (isGlass ? 24.0 : 20.0);

    if (isGlass) {
      // Glassmorphism Implementation
      cardContent = ClipRRect(
        borderRadius: BorderRadius.circular(
          effectiveBorderRadius,
        ), // slightly more rounded for glass
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: padding ?? const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color:
                  color ??
                  (isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(effectiveBorderRadius),
              border:
                  border ??
                  Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.6),
                    width: 1,
                  ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        ),
      );
    } else {
      // Standard Solid Card
      cardContent = Container(
        padding: padding ?? const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color ?? (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(effectiveBorderRadius),
          border:
              border ??
              Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.shade200,
              ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        child: child,
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
                begin: slideOffset ?? 0.15,
                end: 0,
                duration: animationDuration ?? AppAnimations.defaultDuration,
                curve: AppAnimations.defaultCurve,
              )
        : cardContent;

    if (onTap != null) {
      return Padding(
        padding: margin ?? EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(effectiveBorderRadius),
            child: animatedCard,
          ),
        ),
      );
    }

    return Padding(padding: margin ?? EdgeInsets.zero, child: animatedCard);
  }
}
