import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/auth/data/auth_controller.dart';

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

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [AppColors.backgroundDark, AppColors.surfaceDark]
                : [AppColors.backgroundLight, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Main Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: isDenied
                        ? AppColors.redPrimary.withValues(alpha: 0.1)
                        : (isDark
                            ? AppColors.goldPrimary.withValues(alpha: 0.15)
                            : AppColors.goldPrimary.withValues(alpha: 0.1)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDenied ? Icons.block_rounded : Icons.hourglass_top_rounded,
                    size: 48,
                    color: isDenied
                        ? AppColors.redPrimary
                        : (isDark ? AppColors.goldPrimary : AppColors.goldDark),
                  ),
                ).animate().scale(
                      duration: 500.ms,
                      curve: Curves.easeOutBack,
                    ),

                const SizedBox(height: 32),

                // Title
                Text(
                  isDenied ? l10n.accountDenied : l10n.accountPendingActivation,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fade(delay: 100.ms).slideY(begin: 0.2),

                const SizedBox(height: 12),

                // Description
                Text(
                  isDenied
                      ? l10n.accountDeniedDesc
                      : l10n.accountPendingActivationDesc,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white60 : Colors.black54,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fade(delay: 200.ms).slideY(begin: 0.2),

                const SizedBox(height: 32),

                // User info card
                if (user != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.goldPrimary.withValues(alpha: 0.2)
                                : AppColors.goldPrimary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              user.name.isNotEmpty
                                  ? user.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.goldPrimary
                                    : AppColors.goldDark,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user.email,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color:
                                      isDark ? Colors.white54 : Colors.black45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fade(delay: 300.ms).slideY(begin: 0.2),

                const SizedBox(height: 24),

                // Contact admin message
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.blue.withValues(alpha: 0.1)
                        : Colors.blue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Colors.blue.withValues(alpha: 0.3)
                          : Colors.blue.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 22,
                        color: isDark ? Colors.blue.shade300 : Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.contactAdminForActivation,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? Colors.blue.shade200
                                : Colors.blue.shade700,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fade(delay: 400.ms).slideY(begin: 0.2),

                const Spacer(flex: 3),

                // Logout Button only
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      ref.read(authControllerProvider.notifier).logout();
                    },
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: Text(l10n.logout),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.redPrimary,
                    ),
                  ),
                ).animate().fade(delay: 500.ms),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
