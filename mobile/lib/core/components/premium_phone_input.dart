import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/animations.dart';

/// Premium phone input with Egyptian number handling and always LTR
class PremiumPhoneInput extends StatefulWidget {
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
  State<PremiumPhoneInput> createState() => _PremiumPhoneInputState();
}

class _PremiumPhoneInputState extends State<PremiumPhoneInput> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  String _countryCode = '+20'; // Default to Egypt

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// Handle Egyptian number format - auto-strip leading 0
  void _onChanged(String value) {
    // If user types a leading 0 for Egyptian numbers, strip it
    if (_countryCode == '+20' && value.startsWith('0') && value.length > 1) {
      widget.controller.text = value.substring(1);
      widget.controller.selection = TextSelection.fromPosition(
        TextPosition(offset: widget.controller.text.length),
      );
    }
  }

  String get fullNumber {
    final number = widget.controller.text.trim();
    if (number.isEmpty) return '';
    return '$_countryCode$number';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.surfaceDark : Colors.grey.shade50;
    final borderColor = _isFocused
        ? (isDark ? AppColors.goldPrimary : AppColors.bluePrimary)
        : (isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.grey.shade300);

    return Directionality(
      // Always LTR for phone numbers
      textDirection: TextDirection.ltr,
      child:
          AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: borderColor,
                    width: _isFocused ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Country Code Selector
                    GestureDetector(
                      onTap: () => _showCountryPicker(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.grey.shade300,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getFlagEmoji(_countryCode),
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _countryCode,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white70
                                    : Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down,
                              size: 18,
                              color: isDark
                                  ? Colors.white54
                                  : Colors.grey.shade500,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Phone Number Input
                    Expanded(
                      child: TextFormField(
                        controller: widget.controller,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.phone,
                        textDirection: TextDirection.ltr,
                        onChanged: _onChanged,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(15),
                        ],
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: isDark
                              ? Colors.white
                              : AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          border: InputBorder.none,
                          hintText: _countryCode == '+20'
                              ? '10XXXXXXXX'
                              : widget.label,
                          hintStyle: TextStyle(
                            color: isDark
                                ? Colors.white38
                                : Colors.grey.shade400,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ],
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
                curve: AppAnimations.defaultCurve,
              ),
    );
  }

  String _getFlagEmoji(String countryCode) {
    switch (countryCode) {
      case '+20':
        return '🇪🇬';
      case '+1':
        return '🇺🇸';
      case '+44':
        return '🇬🇧';
      case '+966':
        return '🇸🇦';
      case '+971':
        return '🇦🇪';
      default:
        return '🌍';
    }
  }

  void _showCountryPicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final countries = [
      ('+20', '🇪🇬', 'Egypt'),
      ('+966', '🇸🇦', 'Saudi Arabia'),
      ('+971', '🇦🇪', 'UAE'),
      ('+1', '🇺🇸', 'United States'),
      ('+44', '🇬🇧', 'United Kingdom'),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ...countries.map(
              (country) => ListTile(
                leading: Text(country.$2, style: const TextStyle(fontSize: 24)),
                title: Text(
                  country.$3,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Text(
                  country.$1,
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  setState(() => _countryCode = country.$1);
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
