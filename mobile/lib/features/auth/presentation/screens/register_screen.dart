import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/premium_card.dart';
import '../../../../core/components/premium_button.dart';
import '../../../../core/components/premium_text_field.dart';
import '../../../../core/components/premium_back_button.dart';
import '../../data/auth_controller.dart';
import '../../data/auth_repository.dart';
import 'package:mobile/l10n/app_localizations.dart';
import '../widgets/auth_background.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'dart:ui' as ui;

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;
  String? _fullPhoneNumber;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final l10n = AppLocalizations.of(context)!;

    // Manual Validation for top-level error display
    String? validationError;
    if (_nameController.text.trim().isEmpty) {
      validationError = l10n.pleaseEnterName;
    } else if (_emailController.text.trim().isEmpty) {
      validationError = l10n.pleaseEnterEmail;
    } else {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(_emailController.text.trim())) {
        validationError = l10n.pleaseEnterValidEmail;
      } else if (_passwordController.text.isEmpty) {
        validationError = l10n.pleaseEnterPassword;
      }
    }

    if (validationError != null) {
      setState(() {
        _errorMessage = validationError;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await ref
          .read(authControllerProvider.notifier)
          .register(
            _emailController.text.trim(),
            _passwordController.text,
            _nameController.text.trim(),
            phone: _fullPhoneNumber,
          );

      if (!mounted) return;

      if (success) {
        context.push('/confirm-email-pending');
      }
    } catch (e) {
      if (!mounted) return;

      final l10n = AppLocalizations.of(context)!;
      String message;

      if (e is AuthError) {
        switch (e.code) {
          case 'EMAIL_EXISTS':
            message = l10n.emailAlreadyExists;
            break;
          case 'PHONE_EXISTS':
            message = l10n.phoneAlreadyExists;
            break;
          default:
            message = e.message;
        }
      } else {
        message = e.toString();
      }

      setState(() {
        _errorMessage = message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    return AuthBackground(
      child: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Header
                  Column(
                    children: [
                      Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(
                                alpha: isDark ? 0.05 : 0.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.person_add_alt_1_outlined,
                              size: 48,
                              color: isDark
                                  ? AppColors.goldPrimary
                                  : AppColors.bluePrimary,
                            ),
                          )
                          .animate()
                          .fade(duration: 600.ms)
                          .scale(delay: 200.ms, curve: Curves.easeOutBack),
                      const SizedBox(height: 24),
                      Text(
                            l10n.register,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -1,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.bluePrimary,
                                ),
                          )
                          .animate()
                          .fade(delay: 400.ms)
                          .slideY(begin: 0.3, end: 0),
                      const SizedBox(height: 8),
                      Text(
                            l10n.createAccountToStart,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                          )
                          .animate()
                          .fade(delay: 500.ms)
                          .slideY(begin: 0.3, end: 0),
                    ],
                  ),

                  const SizedBox(height: 40),

                  PremiumCard(
                    delay: 0.6,
                    isGlass: true,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Error message display
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.redPrimary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.redPrimary.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: AppColors.redPrimary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        color: AppColors.redPrimary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fade().slideY(begin: -0.2),
                            const SizedBox(height: 20),
                          ],
                          PremiumTextField(
                            controller: _nameController,
                            label: l10n.name,
                            prefixIcon: Icons.person_outline,
                            keyboardType: TextInputType.name,
                            delay: 0.7,
                          ),
                          const SizedBox(height: 16),
                          PremiumTextField(
                            controller: _emailController,
                            label: l10n.email,
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            delay: 0.8,
                          ),
                          const SizedBox(height: 16),
                          Directionality(
                                textDirection: ui.TextDirection.ltr,
                                child: IntlPhoneField(
                                  controller: _phoneController,
                                  initialCountryCode: 'EG',
                                  textAlign: TextAlign.left,
                                  decoration: InputDecoration(
                                    labelText: l10n.phoneNumber,
                                    labelStyle: TextStyle(
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: isDark
                                            ? Colors.white24
                                            : Colors.black12,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: isDark
                                            ? Colors.white24
                                            : Colors.black12,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: isDark
                                            ? AppColors.goldPrimary
                                            : AppColors.bluePrimary,
                                        width: 2,
                                      ),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.phone_outlined,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                    counterText: '',
                                  ),
                                  disableLengthCheck: true,
                                  languageCode: l10n.localeName,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  dropdownTextStyle: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  pickerDialogStyle: PickerDialogStyle(
                                    backgroundColor: isDark
                                        ? const Color(0xFF1E1E1E)
                                        : Colors.white,
                                    countryCodeStyle: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                    countryNameStyle: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                    searchFieldInputDecoration: InputDecoration(
                                      labelText: l10n.search,
                                      labelStyle: TextStyle(
                                        color: isDark
                                            ? Colors.grey
                                            : Colors.black54,
                                      ),
                                      prefixIcon: const Icon(Icons.search),
                                      filled: true,
                                      fillColor: isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.grey.withValues(alpha: 0.05),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                  onChanged: (phone) {
                                    if (phone.countryISOCode == 'EG' &&
                                        phone.number.startsWith('0')) {
                                      _fullPhoneNumber =
                                          '${phone.countryCode}${phone.number.substring(1)}';
                                    } else {
                                      _fullPhoneNumber = phone.completeNumber;
                                    }
                                  },
                                ),
                              )
                              .animate()
                              .fade(delay: 850.ms)
                              .slideY(begin: 0.2, end: 0),
                          const SizedBox(height: 16),
                          PremiumTextField(
                            controller: _passwordController,
                            label: l10n.password,
                            prefixIcon: Icons.lock_outline,
                            isPassword: true,
                            delay: 0.9,
                          ),
                          const SizedBox(height: 32),
                          PremiumButton(
                            label: l10n.register,
                            isFullWidth: true,
                            isLoading: _isLoading,
                            delay: 1.0,
                            onPressed: _handleRegister,
                          ),
                          const SizedBox(height: 24),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l10n.alreadyHaveAccount,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.black54,
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.pop(),
                                child: Text(
                                  l10n.login,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ).animate().fade(delay: 1200.ms),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            top: 20,
            left: 20,
            child: PremiumBackButton(isGlass: true),
          ),
        ],
      ),
    );
  }
}
