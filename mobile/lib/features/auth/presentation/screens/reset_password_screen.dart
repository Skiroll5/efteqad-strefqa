import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/premium_card.dart';
import '../../../../core/components/premium_button.dart';
import '../../../../core/components/premium_text_field.dart';
import '../../../../core/components/premium_back_button.dart';
import '../../../../core/components/app_snackbar.dart';
import '../../../../core/utils/message_handler.dart';
import '../../data/auth_controller.dart';
import 'package:mobile/l10n/app_localizations.dart';
import '../widgets/auth_background.dart';
import '../widgets/auth_message_banner.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String token; // OTP code or token from deep link

  const ResetPasswordScreen({super.key, required this.token});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _scrollController = ScrollController();
  final _formKey = GlobalKey<FormState>();

  String? _errorMessage;
  String? _passwordError;
  String? _confirmError;
  bool _isLoading = false;
  String _password = '';

  final _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Token is now passed via widget.token, no need to prefill a controller.

    _passwordController.addListener(() {
      setState(() {
        _password = _passwordController.text;
        // Instant validation
        final l10n = AppLocalizations.of(context)!;
        if (_password.isEmpty) {
          _passwordError = null;
        } else if (_password.length < 8) {
          _passwordError = l10n.atLeast8Chars;
        } else {
          _passwordError = null;
        }

        if (_confirmPasswordController.text.isNotEmpty) {
          _checkPasswordMatch();
        }
      });
    });

    _confirmPasswordController.addListener(() {
      setState(() {
        _checkPasswordMatch();
      });
    });

    // Auto-scroll when password field is focused
    _passwordFocusNode.addListener(() {
      if (_passwordFocusNode.hasFocus) {
        Future.delayed(300.ms, () {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.offset + 80,
              duration: 300.ms,
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  // Check mismatch helper
  void _checkPasswordMatch() {
    final l10n = AppLocalizations.of(context)!;
    if (_confirmPasswordController.text.isEmpty) {
      _confirmError = null;
    } else if (_passwordController.text != _confirmPasswordController.text) {
      _confirmError = l10n.passwordsDoNotMatch;
    } else {
      _confirmError = null;
    }
  }

  // Helper widget
  Widget _buildInlineError(String? error) {
    if (error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 16), // Align with input text
      child: Text(
        error,
        textAlign: TextAlign.start,
        style: GoogleFonts.cairo(
          color: AppColors.redPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ).animate().fade().slideX(begin: -0.05),
    );
  }

  Future<void> _handleReset() async {
    final l10n = AppLocalizations.of(context)!;

    // Reset state
    setState(() {
      _errorMessage = null;
      _passwordError = null;
      _confirmError = null;
    });

    bool isValid = true;

    // OTP check removed as we trust widget.token
    if (widget.token.isEmpty) {
      setState(() => _errorMessage = l10n.invalidToken);
      return;
    }

    if (_passwordController.text.isEmpty) {
      setState(() => _passwordError = l10n.pleaseEnterPassword);
      isValid = false;
    } else if (_passwordController.text.length < 8) {
      setState(() => _passwordError = l10n.atLeast8Chars);
      isValid = false;
    }

    if (_confirmPasswordController.text.isNotEmpty &&
        _passwordController.text != _confirmPasswordController.text) {
      setState(() => _confirmError = l10n.passwordsDoNotMatch);
      isValid = false;
    }

    if (!isValid) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authControllerProvider.notifier)
          .resetPassword(widget.token, _passwordController.text);

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
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: AuthBackground(
        child: Stack(
          children: [
            SingleChildScrollView(
              // Removed Center
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(
                24,
                100,
                24,
                24,
              ), // Increased top padding
              child: Column(
                children: [
                  // Header
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
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
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.password_rounded,
                          size: 44,
                          color: isDark
                              ? AppColors.goldPrimary
                              : AppColors.bluePrimary,
                        ),
                      ).animate().fade().scale(curve: Curves.easeOutBack),

                      const SizedBox(height: 24),

                      Text(
                            l10n.resetPassword,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.bluePrimary,
                            ),
                          )
                          .animate()
                          .fade(delay: 150.ms)
                          .slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 10),

                      Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              l10n.pleaseEnterPassword,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDark ? Colors.white60 : Colors.black54,
                                height: 1.5,
                              ),
                            ),
                          )
                          .animate()
                          .fade(delay: 200.ms)
                          .slideY(begin: 0.2, end: 0),
                    ],
                  ),

                  const SizedBox(height: 36),

                  PremiumCard(
                    isGlass: true,
                    delay: 0.3,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_errorMessage != null)
                            AuthMessageBanner(
                              message: _errorMessage!,
                              type: AuthMessageType.error,
                            ),

                          if (_errorMessage != null) const SizedBox(height: 16),

                          Focus(
                            focusNode: _passwordFocusNode,
                            child: PremiumTextField(
                              controller: _passwordController,
                              label: l10n.newPassword,
                              prefixIcon: Icons.lock_outline,
                              isPassword: true,
                              textInputAction: TextInputAction.next,
                              delay: 0.4,
                            ),
                          ),
                          _buildInlineError(_passwordError),

                          const SizedBox(height: 14),

                          PremiumTextField(
                            controller: _confirmPasswordController,
                            label: l10n.confirmNewPassword,
                            prefixIcon: Icons.lock_reset,
                            isPassword: true,
                            textInputAction: TextInputAction.done,
                            delay: 0.5,
                          ),
                          _buildInlineError(_confirmError),

                          const SizedBox(height: 28),

                          PremiumButton(
                            label: l10n.resetPassword,
                            isFullWidth: true,
                            isLoading: _isLoading,
                            onPressed: _handleReset,
                            delay: 0.6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Positioned(
              top: 20,
              left: 20,
              child: PremiumBackButton(isGlass: true),
            ),
          ],
        ),
      ),
    );
  }
}
