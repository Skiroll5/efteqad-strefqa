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
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget cardContent = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            color ?? (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
        borderRadius: BorderRadius.circular(16),
        border:
            border ??
            (isGlass
                ? Border.all(color: Colors.white.withOpacity(0.2))
                : Border.all(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withOpacity(0.05),
                  )),
        boxShadow: isGlass
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: child,
    );

    if (isGlass) {
      cardContent = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: (color ?? theme.colorScheme.surface).withOpacity(0.7),
            child: cardContent,
          ),
        ),
      );
    }

    Widget animatedCard = enableAnimation
        ? cardContent
              .animate(delay: Duration(milliseconds: (delay * 1000).toInt()))
              .fade(
                duration: AppAnimations.defaultDuration,
                curve: AppAnimations.defaultCurve,
              )
              .slideY(
                begin: 0.1,
                end: 0,
                duration: AppAnimations.defaultDuration,
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
            borderRadius: BorderRadius.circular(16),
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
