import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/premium_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/data/auth_controller.dart';
import '../../../statistics/data/statistics_repository.dart';
import '../../../sync/data/sync_service.dart';

class AdminPanelScreen extends ConsumerWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.asData?.value;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    // Check if user is admin
    if (user?.role != 'ADMIN') {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(child: Text('You do not have admin privileges.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Logic (Greetings or Summary could go here, but keeping it clean for now)

          // 1. User & Class Management Section
          Text(
            'Management',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ).animate().fade(),
          const SizedBox(height: 8),

          PremiumCard(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                _AdminTile(
                  icon: Icons.people_outline,
                  title: 'User Management',
                  subtitle: 'Activate, enable/disable users',
                  isDark: isDark,
                  onTap: () => context.push('/admin/users'),
                ),
                Divider(
                  height: 1,
                  color: isDark ? Colors.white10 : Colors.grey.shade100,
                  indent: 50,
                ),
                _AdminTile(
                  icon: Icons.class_outlined,
                  title: 'Class Management',
                  subtitle: 'Manage classes and managers',
                  isDark: isDark,
                  onTap: () => context.push('/admin/classes'),
                ),
              ],
            ),
          ).animate().fade(delay: 100.ms),

          const SizedBox(height: 16),

          // 2. Statistics Settings (Threshold)
          Text(
            l10n?.statistics ?? 'Statistics',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ).animate().fade(delay: 150.ms),
          const SizedBox(height: 8),

          Consumer(
            builder: (context, ref, child) {
              final threshold = ref.watch(statisticsSettingsProvider);
              return PremiumCard(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                              (isDark
                                      ? AppColors.goldPrimary
                                      : AppColors.goldPrimary)
                                  .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.analytics_outlined,
                          color: isDark
                              ? AppColors.goldPrimary
                              : AppColors.goldDark,
                        ),
                      ),
                      title: Text(
                        l10n?.atRiskThreshold ?? 'At Risk Threshold',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      subtitle: Text(
                        l10n?.thresholdCaption(threshold) ??
                            'Flag student after $threshold consecutive absences',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                    Slider(
                      value: threshold.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: threshold.toString(),
                      activeColor: isDark
                          ? AppColors.goldPrimary
                          : AppColors.goldPrimary,
                      onChanged: (val) {
                        ref
                            .read(statisticsSettingsProvider.notifier)
                            .setThreshold(val.toInt());
                      },
                    ),
                  ],
                ),
              ).animate().fade(delay: 200.ms);
            },
          ),

          const SizedBox(height: 16),

          // 3. Data Management
          Text(
            l10n?.dataManagement ?? 'Data Management',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ).animate().fade(delay: 250.ms),
          const SizedBox(height: 8),

          PremiumCard(
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: isDark
                            ? AppColors.redLight
                            : AppColors.redPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n?.dangerZone ?? 'Danger Zone',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    l10n?.resetDataCaption ??
                        'If you manually reset the backend database, use this to clear local data.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _confirmDataReset(context, ref, l10n),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(l10n?.resetSyncData ?? 'Reset Sync & Data'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark
                        ? AppColors.redLight
                        : AppColors.redPrimary,
                    side: BorderSide(
                      color:
                          (isDark ? AppColors.redLight : AppColors.redPrimary)
                              .withValues(alpha: 0.3),
                    ),
                    minimumSize: const Size.fromHeight(45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fade(delay: 300.ms),
        ],
      ),
    );
  }

  void _confirmDataReset(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations? l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.confirmReset ?? 'Confirm Reset'),
        content: Text(
          l10n?.resetWarning ??
              'This will delete all local attendance data and force a full re-sync from the server. Use only if backend was cleared.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final messenger = ScaffoldMessenger.of(context);
              final theme = Theme.of(context);
              final isDark = theme.brightness == Brightness.dark;
              try {
                final syncService = ref.read(syncServiceProvider);
                await syncService.clearLocalData();
                await syncService.pullChanges();

                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Success: Local data reset and re-synced.'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Error resetting data: $e'),
                    backgroundColor: isDark
                        ? AppColors.redLight
                        : AppColors.redPrimary,
                  ),
                );
              }
            },
            child: Text(
              l10n?.delete ?? 'Delete',
              style: const TextStyle(
                color: AppColors.redPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  const _AdminTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.goldPrimary : AppColors.goldPrimary)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isDark ? AppColors.goldPrimary : AppColors.goldDark,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ],
        ),
      ),
    );
  }
}
