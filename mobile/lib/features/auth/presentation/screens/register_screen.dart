import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
// import '../../../../core/components/premium_card.dart'; // Removed
import '../../../../core/components/premium_button.dart';
import '../../../../core/components/premium_text_field.dart';
import '../../../../core/components/premium_phone_input.dart';
import '../../../../core/components/premium_back_button.dart';
import '../../../../core/components/app_snackbar.dart'; // Add this
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

  // Keys for individual field validation
  final _nameKey = GlobalKey<FormFieldState>();
  final _emailKey = GlobalKey<FormFieldState>();
  final _phoneKey = GlobalKey<FormFieldState>();

  // Error states for custom validation
  String? _nameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  String? _confirmError;

  // Track focus for auto-scroll
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    // Validation on Blur (Unfocus)
    void addBlurValidation(FocusNode node, VoidCallback validator) {
      node.addListener(() {
        if (!node.hasFocus) {
          validator();
        }
      });
    }

    addBlurValidation(_nameFocusNode, _validateName);
    addBlurValidation(_emailFocusNode, _validateEmail);
    addBlurValidation(_phoneFocusNode, _validatePhone);

    // Instant Password Validation
    _passwordController.addListener(() {
      setState(() {
        _password = _passwordController.text;

        // Instant validation logic
        final l10n = AppLocalizations.of(context)!;
        if (_password.isEmpty) {
          _passwordError = null; // Don't show error for empty, cleaner start
        } else if (_password.length < 8) {
          _passwordError = l10n.atLeast8Chars;
        } else {
          _passwordError = null;
        }

        // Also check match if confirm is not empty
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

    // Auto-scroll logic matching ResetPasswordScreen
    void addScrollListener(FocusNode node) {
      node.addListener(() {
        if (node.hasFocus) {
          Future.delayed(300.ms, () {
            if (mounted && node.context != null) {
              Scrollable.ensureVisible(
                node.context!,
                duration: 300.ms,
                curve: Curves.easeOut,
                alignment: 0.3,
              );
            }
          });
        }
      });
    }

    addScrollListener(_nameFocusNode);
    addScrollListener(_emailFocusNode);
    addScrollListener(_phoneFocusNode);

    // Special logic for password field
    _passwordFocusNode.addListener(() {
      if (_passwordFocusNode.hasFocus) {
        Future.delayed(300.ms, () {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.offset +
                  80, // Reduced slightly as requested implicitly
              duration: 300.ms,
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

    addScrollListener(_confirmPasswordFocusNode);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _scrollController.dispose();

    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();

    super.dispose();
  }

  // Validators
  bool _validateName() {
    final l10n = AppLocalizations.of(context)!;
    final value = _nameController.text.trim();
    String? error;

    if (value.isEmpty) {
      error = l10n.pleaseEnterName;
    } else if (value.length < 2) {
      error = l10n.invalidName;
    }

    if (error != _nameError) {
      setState(() => _nameError = error);
    }
    return error == null;
  }

  bool _validateEmail() {
    final l10n = AppLocalizations.of(context)!;
    final value = _emailController.text.trim();
    String? error;

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (value.isEmpty) {
      error = l10n.pleaseEnterEmail;
    } else if (!emailRegex.hasMatch(value)) {
      error = l10n.invalidEmail;
    }

    if (error != _emailError) {
      setState(() => _emailError = error);
    }
    return error == null;
  }

  bool _validatePhone() {
    final l10n = AppLocalizations.of(context)!;
    final value = _phoneController.text.trim();
    String? error;

    if (value.isNotEmpty && value.length < 10) {
      error = l10n.phoneNumberTooShort;
    }

    if (error != _phoneError) {
      setState(() => _phoneError = error);
    }
    return error == null;
  }

  void _checkPasswordMatch() {
    final l10n = AppLocalizations.of(context)!;
    if (_confirmPasswordController.text.isEmpty) {
      _confirmError = null; // Don't show error if empty
    } else if (_passwordController.text != _confirmPasswordController.text) {
      _confirmError = l10n.passwordsDoNotMatch;
    } else {
      _confirmError = null;
    }
  }

  Future<void> _handleRegister() async {
    final l10n = AppLocalizations.of(context)!;

    // Reset banner state
    setState(() => _errorMessage = null);

    // Validation Logic using Inline Errors
    bool isValid = true;
    isValid &= _validateName();
    isValid &= _validateEmail();
    isValid &= _validatePhone();

    // Password Validation (Explicit check on submit)
    if (_passwordController.text.isEmpty) {
      setState(() => _passwordError = l10n.pleaseEnterPassword);
      isValid = false;
    } else if (_passwordController.text.length < 8) {
      setState(() => _passwordError = l10n.atLeast8Chars);
      isValid = false;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _confirmError = l10n.passwordsDoNotMatch);
      isValid = false;
    }

    if (!isValid) return;

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

  Future<void> _handleGoogleLogin() async {
    debugPrint('DEBUG: Google Sign In Button Pressed (Register)!');
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      behavior: HitTestBehavior.translucent, // Ensure touches pass through
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: AuthBackground(
        child: Stack(
          children: [
            // Removed Center widget to align to top
            SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(
                24,
                100, // Increased top padding since we removed Center
                24,
                24 + MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10), // Reduced spacing
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child:
                            Text(
                                  l10n.createAccountToStart,
                                  textAlign: TextAlign.start,
                                  style: GoogleFonts.cairo(
                                    textStyle: theme.textTheme.headlineSmall,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.bluePrimary,
                                    height: 1.2,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                                .animate()
                                .fade(duration: 600.ms)
                                .slideX(
                                  begin: -0.1,
                                  end: 0,
                                  curve: Curves.easeOutQuad,
                                ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment
                          .start, // Ensure children start aligned
                      children: [
                        if (_errorMessage != null)
                          AuthMessageBanner(
                            message: _errorMessage!,
                            type: AuthMessageType.error,
                          ),

                        if (_errorMessage != null) const SizedBox(height: 20),

                        PremiumTextField(
                          key: _nameKey,
                          controller: _nameController,
                          focusNode: _nameFocusNode,
                          label: l10n.name,
                          prefixIcon: Icons.badge_outlined,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) {
                            _validateName();
                            FocusScope.of(
                              context,
                            ).requestFocus(_emailFocusNode);
                          },
                          delay: 0.3,
                        ),
                        _buildInlineError(_nameError),

                        const SizedBox(height: 16),

                        PremiumTextField(
                          key: _emailKey,
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          label: l10n.email,
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          textDirection: TextDirection.ltr,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) {
                            _validateEmail();
                            FocusScope.of(
                              context,
                            ).requestFocus(_phoneFocusNode);
                          },
                          delay: 0.4,
                        ),
                        _buildInlineError(_emailError),

                        const SizedBox(height: 16),

                        PremiumPhoneInput(
                          key: _phoneKey,
                          controller: _phoneController,
                          focusNode: _phoneFocusNode,
                          textInputAction: TextInputAction.next,
                          label: l10n.phoneNumberOptional,
                          onSubmitted: (_) {
                            _validatePhone();
                            FocusScope.of(
                              context,
                            ).requestFocus(_passwordFocusNode);
                          },
                          delay: 0.5,
                        ),
                        _buildInlineError(_phoneError),

                        const SizedBox(height: 16),

                        // Password field
                        PremiumTextField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          label: l10n.password,
                          prefixIcon: Icons.lock_outline,
                          isPassword: true,
                          textInputAction: TextInputAction.next,
                          delay: 0.6,
                        ),
                        _buildInlineError(_passwordError),

                        // REMOVED PasswordStrengthIndicator (The Bad One)
                        const SizedBox(height: 16),

                        PremiumTextField(
                          controller: _confirmPasswordController,
                          focusNode: _confirmPasswordFocusNode,
                          label: l10n.confirmNewPassword,
                          prefixIcon: Icons.lock_reset,
                          isPassword: true,
                          textInputAction: TextInputAction.done,
                          delay: 0.7,
                        ),
                        _buildInlineError(_confirmError),

                        const SizedBox(height: 32),

                        PremiumButton(
                          label: l10n.register,
                          onPressed: _handleRegister,
                          isLoading: _isLoading,
                          isFullWidth: true,
                          delay: 0.8,
                          textStyle: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Social Login Divider
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
                            color: isDark
                                ? Colors.white54
                                : Colors.grey.shade500,
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
                  ).animate().fade(delay: 900.ms),

                  const SizedBox(height: 24),

                  // Google Sign In Button
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
                  ).animate().fade(delay: 1000.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.alreadyHaveAccount,
                        style: GoogleFonts.cairo(
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          l10n.login,
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
                  ).animate().fade(delay: 1100.ms),

                  const SizedBox(height: 20),
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
