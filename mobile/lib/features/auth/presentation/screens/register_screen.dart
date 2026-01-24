import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/premium_card.dart';
import '../../../../core/components/premium_button.dart';
import '../../../../core/components/premium_text_field.dart';
import '../../../../core/components/premium_phone_input.dart';
import '../../../../core/components/premium_back_button.dart';
import '../../../../core/components/password_strength_indicator.dart';
import '../../../../core/utils/message_handler.dart';
import '../../data/auth_controller.dart';
import 'package:mobile/l10n/app_localizations.dart';

import '../widgets/auth_background.dart';
import '../widgets/auth_message_banner.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;
  bool _isLoading = false;

  // Track password for strength check
  String _password = '';

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      setState(() => _password = _passwordController.text);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final l10n = AppLocalizations.of(context)!;

    // Reset state
    setState(() => _errorMessage = null);

    // Basic Validations
    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = l10n.pleaseEnterName);
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      setState(() => _errorMessage = l10n.pleaseEnterEmail);
      return;
    }

    if (_passwordController.text.isEmpty) {
      setState(() => _errorMessage = l10n.pleaseEnterPassword);
      return;
    }

    // Password match
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = l10n.passwordsDoNotMatch);
      return;
    }

    // Password strength check
    if (_passwordController.text.length < 8) {
      setState(() => _errorMessage = l10n.atLeast8Chars);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await ref
          .read(authControllerProvider.notifier)
          .register(
            _emailController.text.trim(),
            _passwordController.text,
            _nameController.text.trim(),
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
          );

      if (!mounted) return;

      if (success) {
        // Navigate to unified verification screen
        context.push(
          '/confirm-email-pending',
          extra: {'email': _emailController.text.trim()},
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = MessageHandler.getErrorMessage(context, e);
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
              padding: EdgeInsets.fromLTRB(
                24,
                80,
                24,
                24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.createAccountToStart,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.bluePrimary,
                      height: 1.2,
                    ),
                  ).animate().fade().slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 32),

                  PremiumCard(
                    delay: 0.2,
                    isGlass: true,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          if (_errorMessage != null)
                            AuthMessageBanner(
                              message: _errorMessage!,
                              type: AuthMessageType.error,
                            ),

                          if (_errorMessage != null) const SizedBox(height: 16),

                          PremiumTextField(
                            controller: _nameController,
                            label: l10n.name,
                            prefixIcon: Icons.badge_outlined,
                            textInputAction: TextInputAction.next,
                            delay: 0.3,
                          ),
                          const SizedBox(height: 16),
                          PremiumTextField(
                            controller: _emailController,
                            label: l10n.email,
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            delay: 0.4,
                          ),
                          const SizedBox(height: 16),
                          PremiumPhoneInput(
                            controller: _phoneController,
                            label: l10n.phoneNumberOptional,
                            delay: 0.5,
                          ),
                          const SizedBox(height: 16),
                          PremiumTextField(
                            controller: _passwordController,
                            label: l10n.password,
                            prefixIcon: Icons.lock_outline,
                            isPassword: true,
                            textInputAction: TextInputAction.next,
                            delay: 0.6,
                          ),

                          // Strength Indicator
                          AnimatedSize(
                            duration: 300.ms,
                            child: _password.isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.only(
                                      top: 8,
                                      bottom: 8,
                                    ),
                                    child: PasswordStrengthIndicator(
                                      password: _password,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),

                          const SizedBox(height: 16),

                          PremiumTextField(
                            controller: _confirmPasswordController,
                            label: l10n.confirmNewPassword,
                            prefixIcon: Icons.lock_reset,
                            isPassword: true,
                            textInputAction: TextInputAction.done,
                            delay: 0.7,
                          ),

                          const SizedBox(height: 24),

                          PremiumButton(
                            label: l10n.register,
                            onPressed: _handleRegister,
                            isLoading: _isLoading,
                            isFullWidth: true,
                            delay: 0.8,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.alreadyHaveAccount,
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: Text(
                          l10n.login,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.goldPrimary
                                : AppColors.bluePrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fade(delay: 900.ms),

                  const SizedBox(height: 20),
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
