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
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppColors.backgroundDark, AppColors.surfaceDark]
                : [AppColors.backgroundLight, Colors.white],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo or Title
                Icon(
                      Icons.church,
                      size: 64,
                      color: Theme.of(context).primaryColor,
                    )
                    .animate()
                    .fade(duration: 500.ms)
                    .scale(delay: 200.ms, curve: Curves.easeOutBack),

                const SizedBox(height: 16),

                Text(
                  l10n.appTitle,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ).animate().fade(delay: 300.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 48),

                PremiumCard(
                  delay: 0.2,
                  isGlass: true,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Text(
                          l10n.login,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),

                        // Error message display
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
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: AppColors.redPrimary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      color: AppColors.redPrimary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fade().slideY(begin: -0.2),
                          const SizedBox(height: 16),
                        ],

                        PremiumTextField(
                          controller: _emailController,
                          label: l10n.email,
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) =>
                              value!.isEmpty ? l10n.pleaseEnterName : null,
                          delay: 0.3,
                        ),
                        const SizedBox(height: 16),
                        PremiumTextField(
                          controller: _passwordController,
                          label: l10n.password,
                          prefixIcon: Icons.lock_outline,
                          isPassword: true,
                          validator: (value) =>
                              value!.isEmpty ? l10n.pleaseEnterName : null,
                          delay: 0.4,
                        ),
                        const SizedBox(height: 32),
                        PremiumButton(
                          label: l10n.login,
                          isFullWidth: true,
                          isLoading: _isLoading,
                          delay: 0.5,
                          onPressed: _handleLogin,
                        ),
                        const SizedBox(height: 16),
                        PremiumButton(
                          label: l10n.register,
                          variant: ButtonVariant.outline,
                          isFullWidth: true,
                          delay: 0.6,
                          onPressed: () => context.push('/register'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
