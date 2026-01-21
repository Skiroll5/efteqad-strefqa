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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await ref
          .read(authControllerProvider.notifier)
          .register(
            _emailController.text,
            _passwordController.text,
            _nameController.text,
          );

      if (!mounted) return;

      if (success) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (!mounted) return;

      final l10n = AppLocalizations.of(context)!;
      String message;

      if (e is AuthError) {
        switch (e.code) {
          case 'EMAIL_EXISTS':
            message = l10n.emailAlreadyExists;
            break;
          default:
            message = e.message;
        }
      } else {
        message = e.toString();
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

  void _showSuccessDialog() {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.registrationSuccessful,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.registrationSuccessfulDesc,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/login');
            },
            child: Text(
              l10n.login,
              style: TextStyle(
                color: isDark ? AppColors.goldPrimary : AppColors.goldDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Back Button
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(
                      Icons.arrow_back,
                      color: isDark
                          ? AppColors.goldPrimary
                          : AppColors.goldDark,
                    ),
                  ),
                ).animate().fade(duration: 300.ms),

                const SizedBox(height: 24),

                // Logo/Icon
                Icon(
                      Icons.person_add_alt_1,
                      size: 64,
                      color: Theme.of(context).primaryColor,
                    )
                        .animate()
                        .fade(duration: 500.ms)
                        .scale(delay: 200.ms, curve: Curves.easeOutBack),

                const SizedBox(height: 16),

                Text(
                  l10n.register,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ).animate().fade(delay: 300.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 8),

                Text(
                  l10n.createAccountToStart,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fade(delay: 350.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 32),

                PremiumCard(
                  delay: 0.2,
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
                                  controller: _nameController,
                                  label: l10n.name,
                                  prefixIcon: Icons.person_outline,
                                  keyboardType: TextInputType.name,
                                  validator: (value) =>
                                      value!.isEmpty ? l10n.pleaseEnterName : null,
                                  delay: 0.3,
                                ),
                                const SizedBox(height: 16),
                                PremiumTextField(
                                  controller: _emailController,
                                  label: l10n.email,
                                  prefixIcon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) =>
                                      value!.isEmpty ? l10n.pleaseEnterName : null,
                                  delay: 0.4,
                                ),
                                const SizedBox(height: 16),
                                PremiumTextField(
                                  controller: _passwordController,
                                  label: l10n.password,
                                  prefixIcon: Icons.lock_outline,
                                  isPassword: true,
                                  validator: (value) =>
                                      value!.isEmpty ? l10n.pleaseEnterName : null,
                                  delay: 0.5,
                                ),
                                const SizedBox(height: 32),
                                PremiumButton(
                                  label: l10n.register,
                                  isFullWidth: true,
                                  isLoading: _isLoading,
                                  delay: 0.6,
                                  onPressed: _handleRegister,
                                ),
                                const SizedBox(height: 16),
                                PremiumButton(
                                  label: l10n.cancel,
                                  variant: ButtonVariant.outline,
                                  isFullWidth: true,
                                  delay: 0.7,
                                  onPressed: () => context.pop(),
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
