import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/auth/data/auth_controller.dart';

import '../widgets/auth_background.dart';

class PendingActivationScreen extends ConsumerWidget {
  const PendingActivationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Watch user to personalize message and check if denied
    final user = ref.watch(authControllerProvider).asData?.value;
    final isDenied = user?.activationDenied ?? false;

    return AuthBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Main Icon with premium styling
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDenied
                      ? AppColors.redPrimary.withValues(alpha: 0.12)
                      : (isDark
                            ? AppColors.goldPrimary.withValues(alpha: 0.12)
                            : AppColors.goldPrimary.withValues(alpha: 0.1)),
                  border: Border.all(
                    color: isDenied
                        ? AppColors.redPrimary.withValues(alpha: 0.3)
                        : (isDark
                              ? AppColors.goldPrimary.withValues(alpha: 0.3)
                              : AppColors.goldPrimary.withValues(alpha: 0.2)),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isDenied
                                  ? AppColors.redPrimary
                                  : AppColors.goldPrimary)
                              .withValues(alpha: 0.2),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: Icon(
                  isDenied ? Icons.block_rounded : Icons.hourglass_top_rounded,
                  size: 48,
                  color: isDenied
                      ? AppColors.redPrimary
                      : (isDark ? AppColors.goldPrimary : AppColors.goldDark),
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 36),

              // Title
              Text(
                isDenied ? l10n.accountDenied : l10n.accountPendingActivation,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ).animate().fade(delay: 100.ms).slideY(begin: 0.2),

              const SizedBox(height: 14),

              // Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  isDenied
                      ? l10n.accountDeniedDesc
                      : l10n.accountPendingActivationDesc,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white60 : Colors.black54,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ).animate().fade(delay: 150.ms).slideY(begin: 0.2),

              const SizedBox(height: 36),

              // User info card with glassmorphism
              if (user != null)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey.shade200,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.2 : 0.05,
                        ),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.goldPrimary.withValues(alpha: 0.3),
                              AppColors.goldPrimary.withValues(alpha: 0.15),
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.goldPrimary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.goldPrimary
                                  : AppColors.goldDark,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fade(delay: 200.ms).slideY(begin: 0.2),

              const SizedBox(height: 24),

              // Contact admin message with premium styling
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.blue.withValues(alpha: 0.1)
                      : Colors.blue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.blue.withValues(alpha: 0.25)
                        : Colors.blue.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: isDark ? Colors.blue.shade300 : Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        l10n.contactAdminForActivation,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? Colors.blue.shade200
                              : Colors.blue.shade700,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fade(delay: 250.ms).slideY(begin: 0.2),

              const Spacer(flex: 3),

              // Logout Button with premium styling
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.redPrimary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: FilledButton.icon(
                    onPressed: () {
                      ref.read(authControllerProvider.notifier).logout();
                    },
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: Text(l10n.logout),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.redPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ).animate().fade(delay: 300.ms),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}
