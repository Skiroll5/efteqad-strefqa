import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
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
      if (e is AuthError) {
        if (e.code == 'EMAIL_NOT_CONFIRMED') {
          canResend = true;
        }
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

  Future<void> _handleGoogleLogin() async {
    debugPrint('DEBUG: Google Sign In Button Pressed!');
    // Prevent multiple clicks
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final success = await ref
          .read(authControllerProvider.notifier)
          .signInWithGoogle();

      if (!mounted) return;

      if (success) {
        context.go('/');
      }
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

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: AuthBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // 1. Logo and Header
                Column(
                  children: [
                    Hero(
                          tag: 'app_logo',
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.goldPrimary.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 60,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/logo.png',
                              height: 100,
                              fit: BoxFit.contain,
                            ),
                          ),
                        )
                        .animate()
                        .fade(duration: 800.ms, curve: Curves.easeOut)
                        .slideY(
                          begin: -0.2,
                          end: 0,
                          duration: 800.ms,
                          curve: Curves.easeOutQuart,
                        ),

                    const SizedBox(height: 24),

                    Text(
                          l10n.churchName,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            textStyle: theme.textTheme.titleMedium,
                            color: isDark
                                ? Colors.white70
                                : Colors.grey.shade700,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                        .animate()
                        .fade(delay: 300.ms, duration: 600.ms)
                        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),
                  ],
                ),

                const SizedBox(height: 48),

                // 2. Transparent Form Area (No Card)
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                        textDirection: TextDirection.ltr, // Force LTR for email
                        textInputAction: TextInputAction.next,
                        delay: 0.4,
                      ),
                      const SizedBox(height: 16),
                      PremiumTextField(
                        controller: _passwordController,
                        label: l10n.password,
                        prefixIcon: Icons.lock_outline,
                        isPassword: true,
                        textInputAction: TextInputAction.done,
                        delay: 0.5,
                      ),

                      const SizedBox(height: 12),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            context.push('/forgot-password');
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            l10n.forgotPassword,
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.goldPrimary
                                  : AppColors.bluePrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ).animate().fade(delay: 600.ms),

                      const SizedBox(height: 32),

                      PremiumButton(
                        label: l10n.login,
                        isFullWidth: true,
                        isLoading: _isLoading,
                        delay: 0.6,
                        onPressed: _handleLogin,
                        textStyle: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 3. Social Login Divider
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: isDark ? Colors.white24 : Colors.black12,
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        l10n.orContinueWith,
                        style: GoogleFonts.cairo(
                          color: isDark ? Colors.white54 : Colors.grey.shade500,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: isDark ? Colors.white24 : Colors.black12,
                        thickness: 1,
                      ),
                    ),
                  ],
                ).animate().fade(delay: 700.ms),

                const SizedBox(height: 24),

                // 4. Google Sign In Button
                OutlinedButton(
                  onPressed: _isLoading ? null : _handleGoogleLogin,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white.withValues(alpha: 0.8),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Google Icon
                            Container(
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: Text(
                                'G',
                                style: GoogleFonts.inter(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              l10n.googleSignIn,
                              style: GoogleFonts.cairo(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ).animate().fade(delay: 800.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 32),

                // 5. Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.dontHaveAccount,
                      style: GoogleFonts.cairo(
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/register'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        l10n.register,
                        style: GoogleFonts.cairo(
                          color: isDark
                              ? AppColors.goldPrimary
                              : AppColors.bluePrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ).animate().fade(delay: 900.ms),

                const SizedBox(height: 48),

                // Elegant Quote Design
                Column(
                  children: [
                    Icon(
                      Icons.format_quote_rounded,
                      size: 24,
                      color: isDark ? Colors.white24 : Colors.black12,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.loginVerse,
                      style: GoogleFonts.cairo(
                        textStyle: theme.textTheme.bodySmall,
                        color: isDark ? Colors.white38 : Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ).animate().fade(delay: 1000.ms).slideY(begin: 0.2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
