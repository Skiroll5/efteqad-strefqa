import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../l10n/app_localizations.dart';
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
                                    .withValues(alpha: 0.15),
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
                Divider(
                  height: 1,
                  color: isDark ? Colors.white10 : Colors.grey.shade100,
                  indent: 50,
                ),
                _SettingsTile(
                  icon: Icons.chat_bubble_outline,
                  title: l10n?.whatsappTemplate ?? 'WhatsApp Template',
                  subtitle:
                      l10n?.whatsappTemplateDesc ??
                      'Customize the default message sent to students',
                  isDark: isDark,
                  onTap: () => context.push('/settings/whatsapp-template'),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                Divider(
                  height: 1,
                  color: isDark ? Colors.white10 : Colors.grey.shade100,
                  indent: 50,
                ),
                _SettingsTile(
                  icon: Icons.notifications_none_outlined,
                  title: 'Notifications',
                  subtitle: 'Manage push notifications',
                  isDark: isDark,
                  onTap: () => context.push('/settings/notifications'),
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

          // Default Attendance Note Card (New)
          PremiumCard(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                Consumer(
                  builder: (context, ref, child) {
                    final defaultNote = ref.watch(defaultNoteProvider);
                    return _SettingsTile(
                      icon: Icons.edit_note,
                      title:
                          l10n?.defaultAttendanceNote ??
                          'Default Attendance Note',
                      subtitle: defaultNote.isNotEmpty
                          ? defaultNote
                          : (l10n?.defaultAttendanceNoteDesc ??
                                'Set default note'),
                      isDark: isDark,
                      onTap: () =>
                          _showDefaultNoteEditor(context, ref, defaultNote),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    );
                  },
                ),
              ],
            ),
          ).animate().fade(delay: 150.ms),

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
                          .withValues(alpha: 0.1),
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

  void _showDefaultNoteEditor(
    BuildContext context,
    WidgetRef ref,
    String currentNote,
  ) {
    final controller = TextEditingController(text: currentNote);
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n?.defaultAttendanceNote ?? 'Default Attendance Note',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: TextField(
          controller: controller,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: l10n?.defaultNoteHint ?? 'Enter default note...',
            filled: true,
            fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(defaultNoteProvider.notifier).setNote(controller.text);
              Navigator.pop(context);
            },
            child: Text(l10n?.save ?? 'Save'),
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
