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
  late TextEditingController _hiddenController;
  late FocusNode _hiddenFocusNode;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _hiddenController = widget.controller;
    _hiddenController.addListener(_onCodeChanged);

    _hiddenFocusNode = FocusNode();
    _hiddenFocusNode.addListener(() => setState(() {}));

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Remove aggressive clipboard check.
    // We now rely on AutofillHints.oneTimeCode and manual paste.
  }

  // Helper for animation logic
  Future<void> _pastingAnimation(String text) async {
    // Determine how many characters to type
    for (int i = 0; i < text.length; i++) {
      if (!mounted) return;
      _hiddenController.text = text.substring(0, i + 1);
      _hiddenFocusNode.requestFocus();
      _hiddenController.selection = TextSelection.fromPosition(
        TextPosition(offset: _hiddenController.text.length),
      );
      HapticFeedback.selectionClick();
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  @override
  void didUpdateWidget(PremiumOtpInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasError && !oldWidget.hasError) {
      _shake();
    }
    if (widget.controller != oldWidget.controller) {
      _hiddenController.removeListener(_onCodeChanged);
      _hiddenController = widget.controller;
      _hiddenController.addListener(_onCodeChanged);
    }
  }

  void _onCodeChanged() {
    setState(() {}); // Rebuild to show new characters
    if (_hiddenController.text.length == widget.length &&
        widget.onCompleted != null) {
      HapticFeedback.lightImpact();
      widget.onCompleted!(_hiddenController.text);
    }
  }

  void _shake() {
    _shakeController.forward().then((_) => _shakeController.reset());
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _hiddenController.removeListener(_onCodeChanged);
    _hiddenFocusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.goldPrimary : AppColors.bluePrimary;

    return Center(
      child: AnimatedBuilder(
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
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Hidden text field that captures input (Completely invisible/ignored but focusable)
            IgnorePointer(
              child: Opacity(
                opacity: 0.0,
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: TextField(
                    controller: _hiddenController,
                    focusNode: _hiddenFocusNode,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    maxLength: widget.length,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(color: Colors.transparent),
                    cursorColor: Colors.transparent,
                    showCursor: false,
                    enableInteractiveSelection: false,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                    ),
                  ),
                ),
              ),
            ),

            // 2. The visible cells (Visual representation only)
            Directionality(
              textDirection: TextDirection.ltr, // Always LTR for digits
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.min, // shrink to fit
                  children: List.generate(widget.length, (index) {
                    final text = _hiddenController.text;
                    final char = index < text.length ? text[index] : '';

                    final isActive =
                        _hiddenFocusNode.hasFocus &&
                        (index == text.length ||
                            (index == widget.length - 1 &&
                                text.length == widget.length));

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: ClipRRect(
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
                                colors: isActive
                                    ? [
                                        primaryColor.withValues(alpha: 0.2),
                                        primaryColor.withValues(alpha: 0.1),
                                      ]
                                    : [
                                        isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.08,
                                              )
                                            : Colors.white.withValues(
                                                alpha: 0.9,
                                              ),
                                        isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.04,
                                              )
                                            : Colors.white.withValues(
                                                alpha: 0.7,
                                              ),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: widget.hasError
                                    ? AppColors.redPrimary
                                    : (isActive
                                          ? primaryColor
                                          : (char.isNotEmpty
                                                ? (isDark
                                                      ? Colors.white38
                                                      : Colors
                                                            .grey
                                                            .shade400) // Filled but not active
                                                : (isDark
                                                      ? Colors.white12
                                                      : Colors.grey.shade300))),
                                width: isActive ? 2 : 1,
                              ),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: primaryColor.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              char,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: widget.hasError
                                    ? AppColors.redPrimary
                                    : (isDark ? Colors.white : Colors.black87),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            // 3. Touch Overlay (Top layer, handles all interactions)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onLongPress: () async {
                  HapticFeedback.mediumImpact();
                  // Show paste feedback
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  final text = data?.text?.trim();
                  if (text != null && text.isNotEmpty) {
                    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
                    if (digits.isNotEmpty) {
                      final toPaste = digits.substring(
                        0,
                        digits.length > widget.length
                            ? widget.length
                            : digits.length,
                      );
                      _pastingAnimation(toPaste);
                    }
                  }
                },
                onTap: () {
                  if (!_hiddenFocusNode.hasFocus) {
                    _hiddenFocusNode.requestFocus();
                  }
                  // Ensure cursor is at end
                  if (_hiddenController.text.isNotEmpty) {
                    _hiddenController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _hiddenController.text.length),
                    );
                  }
                  // Force show keyboard
                  SystemChannels.textInput.invokeMethod('TextInput.show');
                },
                child: Container(color: Colors.transparent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
