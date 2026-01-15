import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/premium_card.dart';
import '../../../auth/data/auth_controller.dart';
import '../../data/settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: false),
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
                            : [AppColors.bluePrimary, AppColors.blueLight],
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
                                        : AppColors.bluePrimary)
                                    .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user.role,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.goldPrimary
                                  : AppColors.bluePrimary,
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
                  title: 'Theme',
                  subtitle: _getThemeName(themeMode),
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

          // All Settings in one card
          PremiumCard(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.brightness_6_outlined,
                  title: 'Theme',
                  subtitle: _getThemeName(themeMode),
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
                Divider(
                  height: 1,
                  color: isDark ? Colors.white12 : Colors.grey.shade200,
                ),
                _SettingsTile(
                  icon: Icons.language_outlined,
                  title: 'Language',
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
                Divider(
                  height: 1,
                  color: isDark ? Colors.white12 : Colors.grey.shade200,
                ),
                _SettingsTile(
                  icon: Icons.info_outline,
                  title: 'Version',
                  subtitle: '1.0.0',
                  isDark: isDark,
                ),
              ],
            ),
          ).animate().fade(delay: 100.ms),

          // Logout Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton.icon(
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).logout(),
                icon: const Icon(Icons.logout),
                label: const Text(
                  'Logout',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.redPrimary.withOpacity(0.1),
                  foregroundColor: AppColors.redPrimary,
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

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
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
                color: (isDark ? AppColors.goldPrimary : AppColors.bluePrimary)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isDark ? AppColors.goldPrimary : AppColors.bluePrimary,
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
    final accentColor = isDark ? AppColors.goldPrimary : AppColors.bluePrimary;

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
