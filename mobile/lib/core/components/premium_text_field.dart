import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/animations.dart';

class PremiumTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData? prefixIcon;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final double delay;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
  final TextDirection? textDirection; // Add this

  const PremiumTextField({
    super.key,
    required this.controller,
    required this.label,
    this.prefixIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.delay = 0,
    this.textInputAction,
    this.focusNode,
    this.onSubmitted,
    this.textDirection, // Add this
  });

  @override
  State<PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<PremiumTextField> {
  bool _obscureText = true;
  late FocusNode _focusNode; // Change to late
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode(); // Use provided or create new
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });

    // Fix RTL/LTR cursor position issue
    // When focusing, if text exists, ensure cursor goes to the end
    if (_isFocused && widget.controller.text.isNotEmpty) {
      // Small delay to ensure frame is ready if needed, though direct set usually works
      // using addPostFrameCallback is safer for focus transitions
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _focusNode.hasFocus) {
          widget.controller.selection = TextSelection.fromPosition(
            TextPosition(offset: widget.controller.text.length),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose(); // Only dispose if we created it
    } else {
      _focusNode.removeListener(_handleFocusChange);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // "Vineyard" Inspired Input Style
    // Background: Darker semi-transparent fill for contrast against gradient
    final bgColor = isDark
        ? AppColors.vineyardBrownLight.withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.8);

    // Border: Gold accent on focus, subtle gold/grey otherwise
    // Label text color
    final labelColor = _isFocused
        ? AppColors.goldPrimary
        : (isDark
              ? Colors.white70
              : Colors.black54); // Darker text for light mode

    final borderColor = _isFocused
        ? AppColors.goldPrimary
        : (isDark
              ? AppColors.goldPrimary.withValues(alpha: 0.2)
              : Colors.black12); // Visible border for light mode

    final activeIconColor = AppColors.goldPrimary;
    final inactiveIconColor = isDark ? Colors.white54 : Colors.grey.shade600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: borderColor,
                  width: _isFocused ? 1.5 : 1.0,
                ),
                boxShadow: _isFocused
                    ? [
                        BoxShadow(
                          color: AppColors.goldPrimary.withValues(alpha: 0.15),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
              child: TextFormField(
                controller: widget.controller,
                focusNode: _focusNode,
                obscureText: widget.isPassword && _obscureText,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                validator: widget.validator,
                onFieldSubmitted: widget.onSubmitted,
                textDirection: widget.textDirection, // Add this
                onChanged: widget.onChanged,
                style: GoogleFonts.cairo(
                  textStyle: theme.textTheme.bodyLarge,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w600,
                ),
                cursorColor: AppColors.goldPrimary,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  border: InputBorder.none,
                  labelText: widget.label,
                  labelStyle: GoogleFonts.cairo(
                    color: labelColor,
                    fontWeight: _isFocused ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                  ),
                  floatingLabelStyle: GoogleFonts.cairo(
                    color: AppColors.goldPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  prefixIcon: widget.prefixIcon != null
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(
                            widget.prefixIcon,
                            size: 22,
                            color: _isFocused
                                ? activeIconColor
                                : inactiveIconColor,
                          ),
                        )
                      : null,
                  prefixIconConstraints: const BoxConstraints(minWidth: 48),
                  suffixIcon: widget.isPassword
                      ? IconButton(
                          icon: Icon(
                            _obscureText
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                            color: inactiveIconColor,
                          ),
                          onPressed: () =>
                              setState(() => _obscureText = !_obscureText),
                          splashRadius: 20,
                        )
                      : null,
                ),
              ),
            )
            .animate(
              delay: Duration(milliseconds: (widget.delay * 1000).toInt()),
            )
            .fade(duration: AppAnimations.defaultDuration)
            .slideY(
              begin: 0.1,
              end: 0,
              duration: AppAnimations.defaultDuration,
              curve: Curves.easeOutBack,
            ),
      ],
    );
  }
}
