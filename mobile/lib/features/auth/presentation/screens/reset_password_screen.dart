import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/premium_card.dart';
import '../../../../core/components/premium_button.dart';
import '../../../../core/components/premium_text_field.dart';
import '../../../../core/components/premium_back_button.dart';
import '../../../../core/components/app_snackbar.dart';
import '../../data/auth_controller.dart';
import '../../data/auth_repository.dart';
import 'package:mobile/l10n/app_localizations.dart';
import '../widgets/auth_background.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    final l10n = AppLocalizations.of(context)!;

    if (_otpController.text.trim().isEmpty) {
      setState(() => _errorMessage = l10n.pleaseEnterOtp);
      return;
    }
    if (_passwordController.text.isEmpty) {
      setState(() => _errorMessage = l10n.pleaseEnterPassword);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

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
        _errorMessage = e is AuthError ? e.message : e.toString();
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
                            style: theme.textTheme.headlineMedium?.copyWith(
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
                            style: theme.textTheme.bodyLarge?.copyWith(
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
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
                            controller: _otpController,
                            label: l10n.otpCode,
                            prefixIcon: Icons.confirmation_number_outlined,
                            keyboardType: TextInputType.number,
                            delay: 0.6,
                          ),
                          const SizedBox(height: 16),
                          PremiumTextField(
                            controller: _passwordController,
                            label: l10n.newPassword,
                            prefixIcon: Icons.lock_outline,
                            isPassword: true,
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
