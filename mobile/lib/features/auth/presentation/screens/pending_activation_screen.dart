import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/auth/data/auth_controller.dart';
import 'package:mobile/features/settings/presentation/screens/settings_screen.dart';

class PendingActivationScreen extends ConsumerWidget {
  const PendingActivationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Watch user to personalize message
    final user = ref.watch(authControllerProvider).asData?.value;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Icon(
                Icons.hourglass_top,
                size: 80,
                color: isDark ? AppColors.goldPrimary : AppColors.goldDark,
              ),
              const SizedBox(height: 32),
              Text(
                l10n.accountPendingActivation ?? 'Account Pending Activation',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.accountPendingActivationDesc ??
                    'Your account has been created successfully but is waiting for administrator approval. You will be notified once your account is active.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.white70 : Colors.black54,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              if (user != null) ...[
                 const SizedBox(height: 24),
                 Container(
                   padding: const EdgeInsets.all(12),
                   decoration: BoxDecoration(
                     color: isDark ? Colors.white10 : Colors.grey.shade100,
                     borderRadius: BorderRadius.circular(12),
                   ),
                   child: Column(
                     children: [
                       Text(
                         user.name,
                         style: const TextStyle(fontWeight: FontWeight.bold),
                       ),
                       Text(
                         user.email,
                         style: TextStyle(
                           fontSize: 12,
                           color: isDark ? Colors.white54 : Colors.black54,
                         ),
                       ),
                     ],
                   ),
                 ),
              ],
              const Spacer(),

              // Settings / Logout Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      // Navigate to settings (where logout is usually located)
                      // Or maybe just show logout directly?
                      // The user asked for "settings button should be visible in order to make him able to sign out".
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                    icon: const Icon(Icons.settings),
                    label: Text(l10n.settings ?? 'Settings'),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: () {
                      ref.read(authControllerProvider.notifier).logout();
                    },
                    icon: const Icon(Icons.logout),
                    label: Text(l10n.logout ?? 'Logout'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.redPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
