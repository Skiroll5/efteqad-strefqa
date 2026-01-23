import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/premium_card.dart';
import '../../../../core/components/premium_button.dart';
import '../../../../core/components/premium_text_field.dart';
import '../../../../core/components/app_snackbar.dart';
import '../../data/auth_controller.dart';
import '../../data/auth_repository.dart';
import 'package:mobile/l10n/app_localizations.dart';
import '../widgets/auth_background.dart';

class EmailConfirmationPendingScreen extends ConsumerStatefulWidget {
  const EmailConfirmationPendingScreen({super.key});

  @override
  ConsumerState<EmailConfirmationPendingScreen> createState() =>
      _EmailConfirmationPendingScreenState();
}

class _EmailConfirmationPendingScreenState
    extends ConsumerState<EmailConfirmationPendingScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    final l10n = AppLocalizations.of(context)!;

    if (_otpController.text.trim().isEmpty) {
      setState(() => _errorMessage = l10n.pleaseEnterOtp);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authControllerProvider.notifier)
          .confirmEmail(_otpController.text.trim());

      if (!mounted) return;

      AppSnackBar.show(
        context,
        message: l10n.emailConfirmedSuccess,
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

  // Note: Resend logic is handled in LoginScreen and here we assume
  // user just arrived. But if they are stuck here, they might want to resend?
  // Since we don't have the user's email stored in state here easily without
  // passing it around, we'll keep the "Go Back to Login" as the primary flow
  // if they need to resend (Login -> Error -> Resend).

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    return AuthBackground(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Header Image/Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.mark_email_read_rounded,
                  size: 80,
                  color: isDark ? AppColors.goldPrimary : AppColors.bluePrimary,
                ),
              ).animate().fade().scale(
                duration: 800.ms,
                curve: Curves.easeOutBack,
              ),

              const SizedBox(height: 40),

              PremiumCard(
                isGlass: true,
                child: Column(
                  children: [
                    Text(
                      l10n.checkYourEmail,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.bluePrimary,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fade(delay: 300.ms).slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 16),

                    Text(
                      l10n.confirmEmailDescription,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: isDark ? Colors.white70 : Colors.black54,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fade(delay: 400.ms).slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 32),

                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.redPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.redPrimary.withValues(alpha: 0.2),
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
                    ),
                    const SizedBox(height: 20),

                    PremiumButton(
                      label: l10n.confirm,
                      isFullWidth: true,
                      isLoading: _isLoading,
                      onPressed: _handleConfirm,
                    ),

                    const SizedBox(height: 24),

                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text(
                        l10n.goBackToLogin,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.goldPrimary
                              : AppColors.bluePrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ).animate().fade(delay: 600.ms),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
