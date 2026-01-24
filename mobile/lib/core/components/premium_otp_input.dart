import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile/core/theme/app_colors.dart';

/// Premium OTP input with glassmorphism styling, paste support, and animations
class PremiumOtpInput extends StatefulWidget {
  final TextEditingController controller;
  final int length;
  final ValueChanged<String>? onCompleted;
  final bool hasError;

  const PremiumOtpInput({
    super.key,
    required this.controller,
    this.length = 6,
    this.onCompleted,
    this.hasError = false,
  });

  @override
  State<PremiumOtpInput> createState() => _PremiumOtpInputState();
}

class _PremiumOtpInputState extends State<PremiumOtpInput>
    with SingleTickerProviderStateMixin {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  late AnimationController _shakeController;
  int _focusedIndex = -1;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.length,
      (index) => TextEditingController(),
    );
    _focusNodes = List.generate(widget.length, (index) {
      final node = FocusNode();
      node.addListener(() {
        setState(() {
          _focusedIndex = node.hasFocus ? index : _focusedIndex;
        });
      });
      return node;
    });

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(PremiumOtpInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasError && !oldWidget.hasError) {
      _shake();
    }
  }

  void _shake() {
    _shakeController.forward().then((_) => _shakeController.reset());
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _shakeController.dispose();
    super.dispose();
  }

  void _onChanged(String value, int index) {
    // Handle paste of full OTP code
    if (value.length > 1) {
      _handlePaste(value);
      return;
    }

    if (value.length == 1 && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    _updateMainController();
  }

  void _handlePaste(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return;

    for (int i = 0; i < widget.length && i < digits.length; i++) {
      _controllers[i].text = digits[i];
    }

    // Focus last filled or next empty
    final focusIndex = digits.length >= widget.length
        ? widget.length - 1
        : digits.length;
    if (focusIndex < widget.length) {
      _focusNodes[focusIndex].requestFocus();
    }

    _updateMainController();
  }

  void _onKeyDown(KeyEvent event, int index) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
        _controllers[index - 1].clear();
        _updateMainController();
      }
    }
  }

  void _updateMainController() {
    final otp = _controllers.map((c) => c.text).join();
    widget.controller.text = otp;
    if (otp.length == widget.length && widget.onCompleted != null) {
      HapticFeedback.lightImpact();
      widget.onCompleted!(otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.goldPrimary : AppColors.bluePrimary;

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final shakeOffset = _shakeController.value < 0.5
            ? _shakeController.value * 20 - 5
            : (1 - _shakeController.value) * 20 - 5;
        return Transform.translate(
          offset: Offset(shakeOffset * (widget.hasError ? 1 : 0), 0),
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(widget.length, (index) {
          final isFocused = _focusedIndex == index;
          final hasValue = _controllers[index].text.isNotEmpty;

          return ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: AnimatedContainer(
                    duration: 200.ms,
                    width: 48,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isFocused
                            ? [
                                primaryColor.withValues(alpha: 0.2),
                                primaryColor.withValues(alpha: 0.1),
                              ]
                            : [
                                isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.white.withValues(alpha: 0.9),
                                isDark
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : Colors.white.withValues(alpha: 0.7),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: widget.hasError
                            ? AppColors.redPrimary
                            : (isFocused
                                  ? primaryColor
                                  : (isDark
                                        ? Colors.white12
                                        : Colors.grey.shade300)),
                        width: isFocused ? 2 : 1,
                      ),
                      boxShadow: isFocused
                          ? [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (event) => _onKeyDown(event, index),
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: widget.hasError
                              ? AppColors.redPrimary
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                        maxLength: 1,
                        decoration: InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          hintText: isFocused ? '' : '•',
                          hintStyle: TextStyle(
                            fontSize: 20,
                            color: isDark
                                ? Colors.white24
                                : Colors.grey.shade300,
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(null), // Allow paste
                        ],
                        onChanged: (value) => _onChanged(value, index),
                      ),
                    ),
                  ),
                ),
              )
              .animate()
              .fade(delay: (index * 40).ms, duration: 200.ms)
              .scale(
                delay: (index * 40).ms,
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                duration: 200.ms,
                curve: Curves.easeOutBack,
              )
              .animate(target: hasValue ? 1 : 0)
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.05, 1.05),
                duration: 100.ms,
              );
        }),
      ),
    );
  }
}
