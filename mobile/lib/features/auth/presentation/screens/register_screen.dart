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
  final _scrollController = ScrollController();

  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;
  bool _isLoading = false;

  // Track password for strength check
  String _password = '';

  // Track focus for auto-scroll
  final _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      setState(() => _password = _passwordController.text);
    });

    // Auto-scroll when password field is focused to ensure strength indicator is visible
    _passwordFocusNode.addListener(() {
      if (_passwordFocusNode.hasFocus) {
        // Delay to allow keyboard to appear
        Future.delayed(300.ms, () {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.offset + 100,
              duration: 300.ms,
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _scrollController.dispose();
    _passwordFocusNode.dispose();
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
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(
                            alpha: isDark ? 0.08 : 0.9,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (isDark
                                          ? AppColors.goldPrimary
                                          : AppColors.bluePrimary)
                                      .withValues(alpha: 0.2),
                              blurRadius: 30,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.person_add_outlined,
                          size: 40,
                          color: isDark
                              ? AppColors.goldPrimary
                              : AppColors.bluePrimary,
                        ),
                      ).animate().fade().scale(curve: Curves.easeOutBack),

                      const SizedBox(height: 20),

                      Text(
                            l10n.createAccountToStart,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.bluePrimary,
                              height: 1.2,
                            ),
                          )
                          .animate()
                          .fade(delay: 100.ms)
                          .slideY(begin: 0.2, end: 0),
                    ],
                  ),

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
                          const SizedBox(height: 14),
                          PremiumTextField(
                            controller: _emailController,
                            label: l10n.email,
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            delay: 0.4,
                          ),
                          const SizedBox(height: 14),
                          PremiumPhoneInput(
                            controller: _phoneController,
                            label: l10n.phoneNumberOptional,
                            delay: 0.5,
                          ),
                          const SizedBox(height: 14),

                          // Password field with focus handling
                          Focus(
                            focusNode: _passwordFocusNode,
                            child: PremiumTextField(
                              controller: _passwordController,
                              label: l10n.password,
                              prefixIcon: Icons.lock_outline,
                              isPassword: true,
                              textInputAction: TextInputAction.next,
                              delay: 0.6,
                            ),
                          ),

                          // Strength Indicator - compact design for keyboard visibility
                          AnimatedSize(
                            duration: 200.ms,
                            curve: Curves.easeOut,
                            child: _password.isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: PasswordStrengthIndicator(
                                      password: _password,
                                      compact:
                                          true, // Use compact mode for keyboard visibility
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),

                          const SizedBox(height: 14),

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
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
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
