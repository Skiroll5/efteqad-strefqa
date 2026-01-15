import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/animations.dart';

enum ButtonVariant { primary, secondary, outline, danger }

class PremiumButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonVariant variant;
  final bool isFullWidth;
  final double delay;

  const PremiumButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.variant = ButtonVariant.primary,
    this.isFullWidth = false,
    this.delay = 0,
  });

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine colors based on variant
    Color backgroundColor;
    Color foregroundColor;
    Border? border;

    switch (widget.variant) {
      case ButtonVariant.primary:
        backgroundColor = theme.primaryColor;
        foregroundColor =
            Colors.white; // Or black depending on primary color contrast
        break;
      case ButtonVariant.secondary:
        backgroundColor = AppColors.blueLight;
        foregroundColor = Colors.white;
        break;
      case ButtonVariant.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = theme.colorScheme.onSurface;
        border = Border.all(color: theme.colorScheme.outline);
        break;
      case ButtonVariant.danger:
        backgroundColor = AppColors.redPrimary;
        foregroundColor = Colors.white;
        break;
    }

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: foregroundColor,
            ),
          )
        else ...[
          if (widget.icon != null) ...[
            Icon(widget.icon, size: 20, color: foregroundColor),
            const SizedBox(width: 8),
          ],
          Text(
            widget.label,
            style: theme.textTheme.titleMedium?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );

    return GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.isLoading ? null : widget.onPressed,
          child: AnimatedScale(
            scale: _isPressed ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeInOut,
            child: Container(
              width: widget.isFullWidth ? double.infinity : null,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: widget.onPressed == null ? Colors.grey : backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: border,
                boxShadow:
                    widget.variant == ButtonVariant.outline ||
                        widget.onPressed == null
                    ? []
                    : [
                        BoxShadow(
                          color: backgroundColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: content,
            ),
          ),
        )
        .animate(delay: Duration(milliseconds: (widget.delay * 1000).toInt()))
        .fade(duration: AppAnimations.defaultDuration)
        .slideY(
          begin: 0.2,
          end: 0,
          duration: AppAnimations.defaultDuration,
          curve: AppAnimations.defaultCurve,
        );
  }
}
