import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/premium_card.dart';
import '../../../../core/components/premium_button.dart';
import '../../../../core/components/premium_text_field.dart';
import '../../../../core/components/premium_back_button.dart';
import '../../../../core/utils/message_handler.dart';
import '../../data/auth_controller.dart';
import 'package:mobile/l10n/app_localizations.dart';
import '../widgets/auth_background.dart';
import '../widgets/auth_message_banner.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _identifierController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _handleRecover() async {
    final l10n = AppLocalizations.of(context)!;

    // Reset state
    setState(() => _errorMessage = null);

    if (_identifierController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = l10n.pleaseEnterEmail;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authControllerProvider.notifier)
          .forgotPassword(_identifierController.text.trim());

      if (!mounted) return;

      // Navigate to unified OTP screen
      context.push(
        '/verify-reset-otp', // This route now maps to OtpVerificationScreen in router
        extra: {'identifier': _identifierController.text.trim()},
      );
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
                          Icons.lock_reset_rounded,
                          size: 48,
                          color: isDark
                              ? AppColors.goldPrimary
                              : AppColors.bluePrimary,
                        ),
                      ).animate().fade().scale(curve: Curves.easeOutBack),

                      const SizedBox(height: 24),

                      Text(
                            l10n.forgotPasswordTitle,
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
                            l10n.forgotPasswordSubtitle,
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
                    delay: 0.3,
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
                            controller: _identifierController,
                            label: l10n.emailOrPhone,
                            prefixIcon: Icons.person_outline,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            delay: 0.4,
                          ),

                          const SizedBox(height: 32),

                          PremiumButton(
                            label: l10n.sendResetLink,
                            isFullWidth: true,
                            isLoading: _isLoading,
                            onPressed: _handleRecover,
                            delay: 0.5,
                          ),

                          const SizedBox(height: 16),

                          TextButton(
                            onPressed: () => context.pop(),
                            child: Text(
                              l10n.goBackToLogin,
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ).animate().fade(delay: 600.ms),
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
