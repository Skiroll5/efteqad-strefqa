import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/premium_card.dart';
import '../../../../core/components/premium_button.dart';
import '../../../../core/components/premium_text_field.dart';
import '../../../../core/components/app_snackbar.dart';
import '../../../../core/utils/message_handler.dart';
import '../../data/auth_controller.dart';
import '../../data/auth_repository.dart';
import 'package:mobile/l10n/app_localizations.dart';

import '../widgets/auth_background.dart';
import '../widgets/auth_message_banner.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;
  bool _isLoading = false;
  bool _showResendButton = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final l10n = AppLocalizations.of(context)!;

    // Reset state
    setState(() {
      _errorMessage = null;
      _showResendButton = false;
    });

    if (_emailController.text.trim().isEmpty) {
      setState(() => _errorMessage = l10n.pleaseEnterEmail);
      return;
    } else if (_passwordController.text.isEmpty) {
      setState(() => _errorMessage = l10n.pleaseEnterPassword);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await ref
          .read(authControllerProvider.notifier)
          .login(_emailController.text, _passwordController.text);

      if (!mounted) return;

      if (success) {
        context.go('/');
      }
    } catch (e) {
      if (!mounted) return;

      // Check specific conditions for UI logic (like showing resend button)
      bool canResend = false;
      if (e is AuthError && e.code == 'EMAIL_NOT_CONFIRMED') {
        canResend = true;
      }

      setState(() {
        _errorMessage = MessageHandler.getErrorMessage(context, e);
        _showResendButton = canResend;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResendConfirmation() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);

    try {
      await ref
          .read(authControllerProvider.notifier)
          .resendConfirmation(_emailController.text.trim());

      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: l10n.emailResent,
        type: AppSnackBarType.success,
      );
      // Navigate to confirmation screen where they can enter OTP
      context.push(
        '/confirm-email-pending',
        extra: {'email': _emailController.text.trim()},
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: MessageHandler.getErrorMessage(context, e),
        type: AppSnackBarType.error,
      );
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
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo & Branding
              Column(
                children: [
                  Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(
                            alpha: isDark ? 0.05 : 0.8,
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(
                              alpha: isDark ? 0.1 : 0.5,
                            ),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/logo.png',
                          height: 70,
                          fit: BoxFit.contain,
                        ),
                      )
                      .animate()
                      .fade(duration: 800.ms)
                      .scale(delay: 200.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 20),
                  Text(
                    l10n.login,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.0, // Tighter tracking for modern look
                      color: isDark ? Colors.white : AppColors.bluePrimary,
                    ),
                  ).animate().fade(delay: 400.ms).slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 4),
                  Text(
                    l10n.churchName,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white54 : Colors.black45,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ).animate().fade(delay: 500.ms).slideY(begin: 0.2, end: 0),
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
                      if (_errorMessage != null)
                        AuthMessageBanner(
                          message: _errorMessage!,
                          type: AuthMessageType.error,
                          onActionPressed: _showResendButton
                              ? _handleResendConfirmation
                              : null,
                          actionLabel: _showResendButton
                              ? l10n.resendEmail
                              : null,
                        ),

                      if (_errorMessage != null) const SizedBox(height: 20),

                      PremiumTextField(
                        controller: _emailController,
                        label: l10n.emailOrPhone,
                        prefixIcon: Icons.person_outline,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        delay: 0.7,
                      ),
                      const SizedBox(height: 16),
                      PremiumTextField(
                        controller: _passwordController,
                        label: l10n.password,
                        prefixIcon: Icons.lock_outline,
                        isPassword: true,
                        textInputAction: TextInputAction.done,
                        delay: 0.8,
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            context.push('/forgot-password');
                          },
                          child: Text(
                            l10n.forgotPassword,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? Colors.white70
                                  : theme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ).animate().fade(delay: 900.ms),

                      const SizedBox(height: 16),

                      PremiumButton(
                        label: l10n.login,
                        isFullWidth: true,
                        isLoading: _isLoading,
                        delay: 1.0,
                        onPressed: _handleLogin,
                      ),
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.dontHaveAccount,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push('/register'),
                            child: Text(
                              l10n.register,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AppColors.goldPrimary
                                    : theme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ).animate().fade(delay: 1100.ms),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 48),

              Text(
                l10n.loginVerse,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ).animate().fade(delay: 1200.ms).slideY(begin: 0.5),
            ],
          ),
        ),
      ),
    );
  }
}
