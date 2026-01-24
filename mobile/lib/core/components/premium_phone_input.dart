import 'package:flutter/material.dart';
import 'package:mobile/core/components/premium_text_field.dart';

class PremiumPhoneInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final double delay;

  const PremiumPhoneInput({
    super.key,
    required this.controller,
    required this.label,
    this.delay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumTextField(
      controller: controller,
      label: label,
      prefixIcon: Icons.phone_outlined,
      keyboardType: TextInputType.phone,
      delay: delay,
    );
  }
}
