import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/premium_card.dart';
import '../../../../core/components/premium_button.dart';
import '../../../../core/components/premium_otp_input.dart';
import '../../../../core/components/premium_back_button.dart';
import '../../../../core/components/app_snackbar.dart';
import '../../../../core/utils/message_handler.dart';
import '../../data/auth_controller.dart';
import 'package:mobile/l10n/app_localizations.dart';
import '../widgets/auth_background.dart';
import '../widgets/auth_message_banner.dart';

enum OtpPurpose { emailConfirmation, passwordReset }

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String identifier; // Email or Phone
  final OtpPurpose purpose;

  const OtpVerificationScreen({
    super.key,
    required this.identifier,
    required this.purpose,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  // Timer for resend
  Timer? _timer;
  int _secondsRemaining = 0;
  static const int _resendCooldown = 60;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _secondsRemaining = _resendCooldown);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleSubmit() async {
    final l10n = AppLocalizations.of(context)!;
    final otp = _otpController.text.trim();

    if (otp.isEmpty || otp.length < 6) {
      setState(() => _errorMessage = l10n.pleaseEnterOtp);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.purpose == OtpPurpose.emailConfirmation) {
        await ref.read(authControllerProvider.notifier).confirmEmail(otp);

        if (!mounted) return;
        AppSnackBar.show(
          context,
          message: l10n.emailConfirmedSuccess,
          type: AppSnackBarType.success,
        );
        context.go('/login');
      } else {
        // Password Reset
        await ref.read(authControllerProvider.notifier).verifyResetOtp(otp);

        if (!mounted) return;
        // Verify success - navigate to reset password with the token (OTP code is the token here)
        context.push('/reset-password', extra: {'token': otp});
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

  Future<void> _handleResend() async {
    if (_secondsRemaining > 0) return;

    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.purpose == OtpPurpose.emailConfirmation) {
        await ref
            .read(authControllerProvider.notifier)
            .resendConfirmation(widget.identifier);
      } else {
        await ref
            .read(authControllerProvider.notifier)
            .forgotPassword(widget.identifier);
      }

      if (!mounted) return;

      _startTimer(); // Restart cooldown

      AppSnackBar.show(
        context,
        message: widget.purpose == OtpPurpose.emailConfirmation
            ? l10n.emailResent
            : l10n.resetLinkSent, // Or "Code resent"
        type: AppSnackBarType.success,
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

    // UI Data based on purpose
    final icon = widget.purpose == OtpPurpose.emailConfirmation
        ? Icons.mark_email_read_rounded
        : Icons.lock_clock_rounded;

    final title = widget.purpose == OtpPurpose.emailConfirmation
        ? l10n.checkYourEmail
        : l10n.verifyCode;

    final subtitle = widget.purpose == OtpPurpose.emailConfirmation
        ? l10n.confirmEmailDescription
        : l10n.enterCodeDesc;

    return AuthBackground(
      child: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Header Icon
                  Container(
                    padding: const EdgeInsets.all(24),
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
                    child: Icon(
                      icon,
                      size: 64,
                      color: isDark
                          ? AppColors.goldPrimary
                          : AppColors.bluePrimary,
                    ),
                  ).animate().scale(
                    duration: 600.ms,
                    curve: Curves.easeOutBack,
                  ),

                  const SizedBox(height: 32),

                  PremiumCard(
                    delay: 0.3,
                    isGlass: true,
                    child: Column(
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : AppColors.bluePrimary,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fade().slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 12),

                        // Identifier display
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.identifier,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ).animate().fade(delay: 200.ms),

                        const SizedBox(height: 16),

                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark ? Colors.white60 : Colors.black54,
                            height: 1.5,
                          ),
                        ).animate().fade(delay: 300.ms),

                        const SizedBox(height: 32),

                        if (_errorMessage != null)
                          AuthMessageBanner(
                            message: _errorMessage!,
                            type: AuthMessageType.error,
                          ),

                        PremiumOtpInput(
                          controller: _otpController,
                          onCompleted: (_) => _handleSubmit(),
                        ),

                        const SizedBox(height: 32),

                        PremiumButton(
                          label: l10n.verify, // Or "Confirm"
                          isFullWidth: true,
                          isLoading: _isLoading,
                          onPressed: _handleSubmit,
                        ),

                        const SizedBox(height: 24),

                        // Resend Timer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_secondsRemaining > 0)
                              Text(
                                '${l10n.resendConfirmation} (${_secondsRemaining}s)',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            else
                              TextButton.icon(
                                onPressed: _isLoading ? null : _handleResend,
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: 16,
                                ),
                                label: Text(l10n.resendConfirmation),
                                style: TextButton.styleFrom(
                                  foregroundColor: isDark
                                      ? AppColors.goldPrimary
                                      : AppColors.bluePrimary,
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: Text(
                            l10n.goBackToLogin,
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
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
