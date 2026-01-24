import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PremiumOtpInput extends StatefulWidget {
  final TextEditingController controller;
  final int length;
  final ValueChanged<String>? onCompleted;

  const PremiumOtpInput({
    super.key,
    required this.controller,
    this.length = 6,
    this.onCompleted,
  });

  @override
  State<PremiumOtpInput> createState() => _PremiumOtpInputState();
}

class _PremiumOtpInputState extends State<PremiumOtpInput> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.length,
      (index) => TextEditingController(),
    );
    _focusNodes = List.generate(widget.length, (index) => FocusNode());

    // Listen to the main controller to sync if needed (optional)
    // For now, allow individual inputs to drive the main controller
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.length == 1 && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    _updateMainController();
  }

  void _updateMainController() {
    final otp = _controllers.map((c) => c.text).join();
    widget.controller.text = otp;
    if (otp.length == widget.length && widget.onCompleted != null) {
      widget.onCompleted!(otp);
    }
  }

  // Handle paste logic if needed, but keeping it simple for now

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (index) {
        return Container(
          width: 45,
          height: 55,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
            maxLength: 1,
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) => _onChanged(value, index),
          ),
        ).animate().fade(delay: (index * 50).ms).scale(delay: (index * 50).ms);
      }),
    );
  }
}
