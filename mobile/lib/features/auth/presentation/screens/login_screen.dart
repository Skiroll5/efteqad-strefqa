import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/premium_card.dart';
import '../../../../core/components/premium_button.dart';
import '../../../../core/components/premium_text_field.dart';
import '../../data/auth_controller.dart';
import '../../data/auth_repository.dart';
import 'package:mobile/l10n/app_localizations.dart';

import '../widgets/auth_background.dart';

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

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

      final l10n = AppLocalizations.of(context)!;
      String message;

      if (e is AuthError) {
        switch (e.code) {
          case 'PENDING_ACTIVATION':
            message = l10n.accountPendingActivation;
            break;
          case 'ACTIVATION_DENIED':
            message = l10n.accountDenied;
            break;
          case 'ACCOUNT_DISABLED':
            message = l10n.accountDisabled;
            break;
          case 'INVALID_CREDENTIALS':
            message = l10n.invalidCredentials;
            break;
          default:
            message = l10n.errorGeneric(e.message);
        }
      } else {
        message = l10n.errorGeneric(e.toString());
      }

      setState(() {
        _errorMessage = message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.5,
                      color: isDark ? Colors.white : AppColors.bluePrimary,
                    ),
                  ).animate().fade(delay: 400.ms).slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 4),
                  Text(
                    l10n.churchName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white54 : Colors.black45,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
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
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.redPrimary.withValues(alpha: 0.1),
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
                        controller: _emailController,
                        label: l10n.email,
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) =>
                            value!.isEmpty ? l10n.pleaseEnterName : null,
                        delay: 0.7,
                      ),
                      const SizedBox(height: 20),
                      PremiumTextField(
                        controller: _passwordController,
                        label: l10n.password,
                        prefixIcon: Icons.lock_outline,
                        isPassword: true,
                        validator: (value) =>
                            value!.isEmpty ? l10n.pleaseEnterName : null,
                        delay: 0.8,
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // Link to forgot password if available
                          },
                          child: Text(
                            l10n.forgotPassword,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ).animate().fade(delay: 900.ms),

                      const SizedBox(height: 12),
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
                                color: theme.primaryColor,
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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
