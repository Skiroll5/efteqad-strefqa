import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/premium_card.dart';
import '../../../auth/data/auth_controller.dart';
import '../../data/settings_controller.dart';
import '../../../sync/data/sync_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.settings ?? 'Settings'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Profile Card
          if (user != null)
            PremiumCard(
              margin: const EdgeInsets.only(top: 8, bottom: 24),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isDark
                            ? [AppColors.goldPrimary, AppColors.goldDark]
                            : [AppColors.goldPrimary, AppColors.goldLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.transparent,
                      child: Text(
                        user.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (isDark
                                        ? AppColors.goldPrimary
                                        : AppColors.goldPrimary)
                                    .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user.role == 'ADMIN'
                                ? (l10n?.admin ?? 'Admin')
                                : (l10n?.servant ?? 'Servant'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.goldPrimary
                                  : AppColors.goldDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fade().slideY(begin: -0.1, end: 0),

          // Settings Card
          PremiumCard(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.brightness_6_outlined,
                  title: l10n?.theme ?? 'Theme',
                  subtitle: _getThemeName(context, themeMode),
                  isDark: isDark,
                  onTap: () =>
                      _showThemePicker(context, ref, themeMode, isDark),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ).animate().fade(delay: 100.ms),

          // Language Card
          PremiumCard(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.language_outlined,
                  title: l10n?.language ?? 'Language',
                  subtitle: _getLanguageName(locale.languageCode),
                  isDark: isDark,
                  onTap: () =>
                      _showLanguagePicker(context, ref, locale, isDark),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ).animate().fade(delay: 200.ms),

          // Version Card
          PremiumCard(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.info_outline,
                        size: 22,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.version ?? 'Version',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          Text(
                            '1.0.0',
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
                  ],
                ),
              ),
            ),
          ).animate().fade(delay: 300.ms),

          // Statistics Settings (Threshold)
          if (user?.role == 'ADMIN')
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
                            color: isDark
                                ? AppColors.goldPrimary.withOpacity(0.1)
                                : AppColors.goldPrimary.withOpacity(0.1),
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
                ).animate().fade(delay: 400.ms);
              },
            ),

          // Emergency Data Reset (Developer/Admin section)
          if (user?.role == 'ADMIN')
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
                          l10n?.dataManagement ?? 'Data Management',
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
                  Text(
                    l10n?.resetDataCaption ??
                        'If you manually reset the backend database, use this to clear local data.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ).animate().fade(delay: 500.ms),
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
                                .withOpacity(0.3),
                      ),
                      minimumSize: const Size.fromHeight(45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fade(delay: 500.ms),

          // Logout Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton.icon(
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).logout(),
                icon: const Icon(Icons.logout),
                label: Text(
                  l10n?.logout ?? 'Logout',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      (isDark ? AppColors.redLight : AppColors.redPrimary)
                          .withOpacity(0.1),
                  foregroundColor: isDark
                      ? AppColors.redLight
                      : AppColors.redPrimary,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ).animate().fade(delay: 400.ms),
            ),
          ),
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
                    backgroundColor: AppColors.redPrimary,
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

  String _getThemeName(BuildContext context, ThemeMode mode) {
    final l10n = AppLocalizations.of(context);
    switch (mode) {
      case ThemeMode.light:
        return l10n?.light ?? 'Light';
      case ThemeMode.dark:
        return l10n?.dark ?? 'Dark';
      case ThemeMode.system:
        return l10n?.system ?? 'System';
    }
  }

  String _getLanguageName(String code) {
    if (code == 'en') return 'English';
    if (code == 'ar') return 'العربية';
    return code;
  }

  void _showThemePicker(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _PickerSheet(
        title: 'Select Theme',
        isDark: isDark,
        options: [
          _PickerOption(
            icon: Icons.brightness_auto,
            title: 'System',
            selected: current == ThemeMode.system,
            onTap: () {
              ref.read(themeModeProvider.notifier).setTheme(ThemeMode.system);
              Navigator.pop(context);
            },
          ),
          _PickerOption(
            icon: Icons.light_mode,
            title: 'Light',
            selected: current == ThemeMode.light,
            onTap: () {
              ref.read(themeModeProvider.notifier).setTheme(ThemeMode.light);
              Navigator.pop(context);
            },
          ),
          _PickerOption(
            icon: Icons.dark_mode,
            title: 'Dark',
            selected: current == ThemeMode.dark,
            onTap: () {
              ref.read(themeModeProvider.notifier).setTheme(ThemeMode.dark);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(
    BuildContext context,
    WidgetRef ref,
    Locale current,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _PickerSheet(
        title: 'Select Language',
        isDark: isDark,
        options: [
          _PickerOption(
            icon: Icons.language,
            title: 'English',
            selected: current.languageCode == 'en',
            onTap: () {
              ref.read(localeProvider.notifier).setLocale(const Locale('en'));
              Navigator.pop(context);
            },
          ),
          _PickerOption(
            icon: Icons.language,
            title: 'العربية',
            selected: current.languageCode == 'ar',
            onTap: () {
              ref.read(localeProvider.notifier).setLocale(const Locale('ar'));
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    this.onTap,
    this.trailing,
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
                    .withOpacity(0.1),
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
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _PickerSheet extends StatelessWidget {
  final String title;
  final bool isDark;
  final List<_PickerOption> options;

  const _PickerSheet({
    required this.title,
    required this.isDark,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Options
          ...options,
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _PickerOption({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = isDark ? AppColors.goldPrimary : AppColors.goldDark;

    return ListTile(
      leading: Icon(icon, color: selected ? accentColor : null),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected ? accentColor : null,
        ),
      ),
      trailing: selected ? Icon(Icons.check_circle, color: accentColor) : null,
      onTap: onTap,
    );
  }
}
