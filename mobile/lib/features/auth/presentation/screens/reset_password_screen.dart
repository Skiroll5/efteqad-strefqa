import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/premium_card.dart';
import '../../../../core/components/premium_button.dart';
import '../../../../core/components/premium_text_field.dart';
import '../../../../core/components/premium_back_button.dart';
import '../../../../core/components/password_strength_indicator.dart';
import '../../../../core/components/app_snackbar.dart';
import '../../../../core/utils/message_handler.dart';
import '../../data/auth_controller.dart';
import 'package:mobile/l10n/app_localizations.dart';
import '../widgets/auth_background.dart';
import '../widgets/auth_message_banner.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String
  token; // Depending on flow, this might be OTP code or token from deep link

  const ResetPasswordScreen({super.key, required this.token});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _errorMessage;
  bool _isLoading = false;
  String _password = '';

  @override
  void initState() {
    super.initState();
    if (widget.token.isNotEmpty) {
      _otpController.text = widget.token;
    }

    _passwordController.addListener(() {
      setState(() => _password = _passwordController.text);
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    final l10n = AppLocalizations.of(context)!;

    // Reset state
    setState(() => _errorMessage = null);

    if (_otpController.text.trim().isEmpty) {
      setState(() => _errorMessage = l10n.pleaseEnterOtp);
      return;
    }
    if (_passwordController.text.isEmpty) {
      setState(() => _errorMessage = l10n.pleaseEnterPassword);
      return;
    }
    if (_passwordController.text.length < 8) {
      setState(() => _errorMessage = l10n.atLeast8Chars);
      return;
    }

    if (_confirmPasswordController.text.isNotEmpty &&
        _passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = l10n.passwordsDoNotMatch);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authControllerProvider.notifier)
          .resetPassword(_otpController.text.trim(), _passwordController.text);

      if (!mounted) return;

      AppSnackBar.show(
        context,
        message: l10n.passwordResetSuccess,
        type: AppSnackBarType.success,
      );

      context.go('/login');
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
              padding: const EdgeInsets.symmetric(horizontal: 24),
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
                          Icons.password_rounded,
                          size: 48,
                          color: isDark
                              ? AppColors.goldPrimary
                              : AppColors.bluePrimary,
                        ),
                      ).animate().fade().scale(curve: Curves.easeOutBack),
                      const SizedBox(height: 24),
                      Text(
                            l10n.resetPassword,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.bluePrimary,
                            ),
                          )
                          .animate()
                          .fade(delay: 200.ms)
                          .slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 8),
                      Text(
                            l10n.enterOtpAndNewPassword,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          )
                          .animate()
                          .fade(delay: 300.ms)
                          .slideY(begin: 0.2, end: 0),
                    ],
                  ),
                  const SizedBox(height: 40),

                  PremiumCard(
                    isGlass: true,
                    delay: 0.4,
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
                            controller: _otpController,
                            label: l10n.otpCode,
                            prefixIcon: Icons.confirmation_number_outlined,
                            keyboardType: TextInputType.number,
                            delay: 0.5,
                          ),
                          const SizedBox(height: 16),
                          PremiumTextField(
                            controller: _passwordController,
                            label: l10n.newPassword,
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

                          const SizedBox(height: 32),

                          PremiumButton(
                            label: l10n.resetPassword,
                            isFullWidth: true,
                            isLoading: _isLoading,
                            onPressed: _handleReset,
                            delay: 0.8,
                          ),
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
