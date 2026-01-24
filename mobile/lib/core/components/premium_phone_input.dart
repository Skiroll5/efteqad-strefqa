import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart'; // Add this
import '../theme/app_colors.dart';
import '../theme/animations.dart';

/// Premium phone input with Egyptian number handling and always LTR
class PremiumPhoneInput extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final double delay;
  final FocusNode? focusNode; // Add this
  final TextInputAction? textInputAction; // Add this
  final ValueChanged<String>? onSubmitted; // Add this
  final String? Function(String?)? validator; // Add this

  const PremiumPhoneInput({
    super.key,
    required this.controller,
    required this.label,
    this.delay = 0,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.validator, // Add this
  });

  @override
  State<PremiumPhoneInput> createState() => _PremiumPhoneInputState();
}

class _PremiumPhoneInputState extends State<PremiumPhoneInput> {
  late FocusNode _focusNode; // Change to late
  bool _isFocused = false;
  String _countryCode = '+20'; // Default to Egypt

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode(); // Use provided or create new
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);

    // Fix RTL/LTR cursor position issue
    if (_isFocused && widget.controller.text.isNotEmpty) {
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

  // No longer stripping leading 0 as requested
  void _onChanged(String value) {
    // Keep raw value
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

    // "Vineyard" Inspired Input Style (Matching PremiumTextField)
    final bgColor = isDark
        ? AppColors.vineyardBrownLight.withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.8);

    final borderColor = _isFocused
        ? AppColors.goldPrimary
        : (isDark
              ? AppColors.goldPrimary.withValues(alpha: 0.2)
              : Colors.black12);

    return Directionality(
      textDirection: TextDirection.ltr,
      child:
          AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16), // Match Text Field
                  border: Border.all(
                    color: borderColor,
                    width: _isFocused ? 1.5 : 1,
                  ),
                  boxShadow: _isFocused
                      ? [
                          BoxShadow(
                            color: AppColors.goldPrimary.withValues(
                              alpha: 0.15,
                            ),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
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
                                  ? AppColors.goldPrimary.withValues(alpha: 0.2)
                                  : Colors.black12,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getFlagEmoji(_countryCode),
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _countryCode,
                              style: GoogleFonts.cairo(
                                color: isDark ? Colors.white70 : Colors.black87,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down,
                              size: 16,
                              color: isDark
                                  ? Colors.white54
                                  : Colors.grey.shade600,
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
                        textInputAction: widget.textInputAction,
                        onFieldSubmitted: widget.onSubmitted,
                        validator: widget.validator,
                        textDirection: TextDirection.ltr,
                        onChanged: _onChanged,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(15),
                        ],
                        style: GoogleFonts.cairo(
                          textStyle: theme.textTheme.bodyLarge,
                          color: isDark
                              ? Colors.white
                              : AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: InputBorder.none,
                          labelText: widget.label,
                          labelStyle: GoogleFonts.cairo(
                            color: _isFocused
                                ? AppColors.goldPrimary
                                : (isDark ? Colors.white70 : Colors.black54),
                            fontWeight: _isFocused
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 14,
                          ),
                          floatingLabelStyle: GoogleFonts.cairo(
                            color: AppColors.goldPrimary,
                            fontWeight: FontWeight.w700,
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
