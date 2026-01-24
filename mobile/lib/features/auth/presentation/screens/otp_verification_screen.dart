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
  bool _hasError = false;

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
      setState(() {
        _errorMessage = l10n.pleaseEnterOtp;
        _hasError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasError = false;
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
        // Verify success - navigate to reset password with the token
        context.push('/reset-password', extra: {'token': otp});
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = MessageHandler.getErrorMessage(context, e);
        _hasError = true;
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
      _hasError = false;
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
            : l10n.resetLinkSent,
        type: AppSnackBarType.success,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = MessageHandler.getErrorMessage(context, e);
        _hasError = true;
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

                  // Header Icon with premium glow
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(
                        alpha: isDark ? 0.08 : 0.9,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(
                          alpha: isDark ? 0.15 : 0.5,
                        ),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isDark
                                      ? AppColors.goldPrimary
                                      : AppColors.bluePrimary)
                                  .withValues(alpha: 0.25),
                          blurRadius: 40,
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      size: 56,
                      color: isDark
                          ? AppColors.goldPrimary
                          : AppColors.bluePrimary,
                    ),
                  ).animate().scale(
                    duration: 500.ms,
                    curve: Curves.easeOutBack,
                  ),

                  const SizedBox(height: 36),

                  PremiumCard(
                    delay: 0.2,
                    isGlass: true,
                    child: Column(
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.white
                                : AppColors.bluePrimary,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fade().slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 14),

                        // Identifier display with premium styling
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.email_outlined,
                                size: 16,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  widget.identifier,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.8)
                                        : Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fade(delay: 150.ms),

                        const SizedBox(height: 16),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark ? Colors.white60 : Colors.black54,
                              height: 1.5,
                            ),
                          ),
                        ).animate().fade(delay: 200.ms),

                        const SizedBox(height: 28),

                        if (_errorMessage != null) ...[
                          AuthMessageBanner(
                            message: _errorMessage!,
                            type: AuthMessageType.error,
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Premium OTP Input
                        PremiumOtpInput(
                          controller: _otpController,
                          onCompleted: (_) => _handleSubmit(),
                          hasError: _hasError,
                        ),

                        const SizedBox(height: 28),

                        PremiumButton(
                          label: l10n.verify,
                          isFullWidth: true,
                          isLoading: _isLoading,
                          onPressed: _handleSubmit,
                        ),

                        const SizedBox(height: 24),

                        // Resend Timer with premium styling
                        AnimatedSwitcher(
                          duration: 200.ms,
                          child: _secondsRemaining > 0
                              ? Container(
                                  key: const ValueKey('timer'),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          value:
                                              _secondsRemaining /
                                              _resendCooldown,
                                          strokeWidth: 2,
                                          color: isDark
                                              ? AppColors.goldPrimary
                                                    .withValues(alpha: 0.5)
                                              : AppColors.bluePrimary
                                                    .withValues(alpha: 0.5),
                                          backgroundColor: isDark
                                              ? Colors.white10
                                              : Colors.grey.shade200,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        '${l10n.resendConfirmation} (${_secondsRemaining}s)',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white38
                                              : Colors.black38,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : TextButton.icon(
                                  key: const ValueKey('resend'),
                                  onPressed: _isLoading ? null : _handleResend,
                                  icon: const Icon(
                                    Icons.refresh_rounded,
                                    size: 18,
                                  ),
                                  label: Text(l10n.resendConfirmation),
                                  style: TextButton.styleFrom(
                                    foregroundColor: isDark
                                        ? AppColors.goldPrimary
                                        : AppColors.bluePrimary,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                  ),
                                ),
                        ),

                        const SizedBox(height: 12),

                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: Text(
                            l10n.goBackToLogin,
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.grey[600],
                              fontWeight: FontWeight.w500,
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
