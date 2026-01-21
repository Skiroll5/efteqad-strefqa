import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/animations.dart';

class PremiumTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData? prefixIcon;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final double delay;

  const PremiumTextField({
    super.key,
    required this.controller,
    required this.label,
    this.prefixIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.delay = 0,
  });

  @override
  State<PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<PremiumTextField> {
  bool _obscureText = true;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: _isFocused ? 0.08 : 0.03)
                : Colors.black.withValues(alpha: _isFocused ? 0.04 : 0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isFocused
                  ? theme.primaryColor
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1)),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.isPassword && _obscureText,
            keyboardType: widget.keyboardType,
            validator: widget.validator,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: InputBorder.none,
              labelText: widget.label,
              labelStyle: TextStyle(
                color: _isFocused
                    ? theme.primaryColor
                    : (isDark ? Colors.white38 : Colors.black45),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      size: 20,
                      color: _isFocused
                          ? theme.primaryColor
                          : (isDark ? Colors.white38 : Colors.black38),
                    )
                  : null,
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscureText
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      onPressed: () =>
                          setState(() => _obscureText = !_obscureText),
                    )
                  : null,
            ),
          ),
        )
        .animate(delay: Duration(milliseconds: (widget.delay * 1000).toInt()))
        .fade(duration: AppAnimations.defaultDuration)
        .slideX(
          begin: -0.1,
          end: 0,
          duration: AppAnimations.defaultDuration,
          curve: AppAnimations.defaultCurve,
        );
  }
}
