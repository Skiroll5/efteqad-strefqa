import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/components/app_snackbar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/premium_card.dart';
import '../../../auth/data/auth_controller.dart';
import '../../data/settings_controller.dart';
import '../../../../features/sync/data/sync_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with Profile
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            stretch: true,
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate collapse ratio (0 = expanded, 1 = collapsed)
                final expandedHeight = 220.0;
                final collapsedHeight =
                    kToolbarHeight + MediaQuery.of(context).padding.top;
                final currentHeight = constraints.maxHeight;
                final collapseRatio =
                    ((expandedHeight - currentHeight) /
                            (expandedHeight - collapsedHeight))
                        .clamp(0.0, 1.0);

                // Interpolate padding from 20 (expanded) to 56 (collapsed)
                final startPadding = 20.0 + (36.0 * collapseRatio);
                // Interpolate font size from 24 (expanded) to 20 (collapsed)
                final fontSize = 24.0 - (4.0 * collapseRatio);

                return FlexibleSpaceBar(
                  title: Text(
                    l10n.settings,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  centerTitle: false,
                  titlePadding: EdgeInsetsDirectional.only(
                    start: startPadding,
                    bottom: 14,
                  ),
                  collapseMode: CollapseMode.pin,
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                AppColors.goldPrimary.withValues(alpha: 0.15),
                                AppColors.surfaceDark,
                              ]
                            : [
                                AppColors.goldPrimary.withValues(alpha: 0.1),
                                Colors.white,
                              ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 48),
                            if (user != null) ...[
                              Row(
                                children: [
                                  // Avatar with gradient border
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.goldPrimary,
                                          AppColors.goldDark,
                                        ],
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 32,
                                      backgroundColor: isDark
                                          ? AppColors.surfaceDark
                                          : Colors.white,
                                      child: Text(
                                        user.name[0].toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 26,
                                          color: AppColors.goldPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.name,
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black87,
                                              ),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.goldPrimary
                                                .withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                user.role == 'ADMIN'
                                                    ? Icons
                                                          .admin_panel_settings_rounded
                                                    : Icons.person_rounded,
                                                size: 14,
                                                color: AppColors.goldPrimary,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                user.role == 'ADMIN'
                                                    ? l10n.admin
                                                    : l10n.servant,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.goldPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Settings Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Appearance Section
                _SettingsSection(
                  title: l10n.appearance,
                  icon: Icons.palette_outlined,
                  isDark: isDark,
                  children: [
                    _ModernSettingsTile(
                      icon: Icons.brightness_6_rounded,
                      iconColor: Colors.orange,
                      title: l10n.theme,
                      subtitle: _getThemeName(context, themeMode),
                      isDark: isDark,
                      onTap: () =>
                          _showThemePicker(context, ref, themeMode, isDark),
                    ),
                    _ModernSettingsTile(
                      icon: Icons.translate_rounded,
                      iconColor: Colors.blue,
                      title: l10n.language,
                      subtitle: _getLanguageName(locale.languageCode),
                      isDark: isDark,
                      onTap: () =>
                          _showLanguagePicker(context, ref, locale, isDark),
                    ),
                  ],
                ).animate().fade().slideY(begin: 0.1),

                const SizedBox(height: 16),

                // Preferences Section
                _SettingsSection(
                  title: l10n.preferences,
                  icon: Icons.tune_rounded,
                  isDark: isDark,
                  children: [
                    _ModernSettingsTile(
                      icon: Icons.chat_bubble_outline_rounded,
                      iconColor: Colors.green,
                      title: l10n.whatsappTemplate,
                      subtitle: l10n.whatsappTemplateDesc,
                      isDark: isDark,
                      onTap: () => context.push('/settings/whatsapp-template'),
                    ),
                    _ModernSettingsTile(
                      icon: Icons.notifications_none_rounded,
                      iconColor: Colors.purple,
                      title: l10n.notificationSettings,
                      subtitle: l10n.notificationSettingsDesc,
                      isDark: isDark,
                      onTap: () => context.push('/settings/notifications'),
                    ),
                    Consumer(
                      builder: (context, ref, child) {
                        final defaultNote = ref.watch(defaultNoteProvider);
                        return _ModernSettingsTile(
                          icon: Icons.edit_note_rounded,
                          iconColor: Colors.teal,
                          title: l10n.defaultAttendanceNote,
                          subtitle: defaultNote.isNotEmpty
                              ? defaultNote
                              : l10n.defaultAttendanceNoteDesc,
                          isDark: isDark,
                          onTap: () =>
                              _showDefaultNoteEditor(context, ref, defaultNote),
                        );
                      },
                    ),
                  ],
                ).animate().fade(delay: 100.ms).slideY(begin: 0.1),

                const SizedBox(height: 16),

                // Statistics Section
                Consumer(
                  builder: (context, ref, child) {
                    final threshold = ref.watch(statisticsSettingsProvider);
                    return _SettingsSection(
                      title: l10n.statistics,
                      icon: Icons.analytics_outlined,
                      isDark: isDark,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.red.shade400,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.atRiskThreshold,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          l10n.thresholdCaption(threshold),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark
                                                ? Colors.white54
                                                : Colors.black45,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.goldPrimary.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '$threshold',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.goldPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: AppColors.goldPrimary,
                                  inactiveTrackColor: isDark
                                      ? Colors.white12
                                      : Colors.grey.shade200,
                                  thumbColor: AppColors.goldPrimary,
                                  overlayColor: AppColors.goldPrimary
                                      .withValues(alpha: 0.2),
                                  trackHeight: 6,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 10,
                                  ),
                                ),
                                child: Slider(
                                  value: threshold.toDouble(),
                                  min: 1,
                                  max: 10,
                                  divisions: 9,
                                  onChanged: (val) {
                                    ref
                                        .read(
                                          statisticsSettingsProvider.notifier,
                                        )
                                        .setThreshold(val.toInt());
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ).animate().fade(delay: 150.ms).slideY(begin: 0.1);
                  },
                ),

                // Admin Section
                if (user?.role == 'ADMIN') ...[
                  const SizedBox(height: 16),
                  _SettingsSection(
                    title: l10n.adminPanel,
                    icon: Icons.admin_panel_settings_outlined,
                    isDark: isDark,
                    accentColor: AppColors.goldPrimary,
                    children: [
                      _ModernSettingsTile(
                        icon: Icons.person_off_rounded,
                        iconColor: Colors.orange,
                        title: l10n.abortedActivations,
                        subtitle: l10n.viewDeniedUsersDesc,
                        isDark: isDark,
                        onTap: () =>
                            context.push('/settings/denied-activations'),
                      ),
                    ],
                  ).animate().fade(delay: 200.ms).slideY(begin: 0.1),

                  const SizedBox(height: 16),

                  // Danger Zone
                  _SettingsSection(
                    title: l10n.dangerZone,
                    icon: Icons.warning_amber_rounded,
                    isDark: isDark,
                    accentColor: AppColors.redPrimary,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.delete_forever_rounded,
                                color: Colors.red.shade400,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.resetAllData,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    l10n.resetAllDataDesc,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red.withValues(
                                  alpha: 0.15,
                                ),
                                foregroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                              onPressed: () => _showResetConfirmation(
                                context,
                                ref,
                                l10n,
                                isDark,
                              ),
                              child: Text(l10n.reset),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ).animate().fade(delay: 250.ms).slideY(begin: 0.1),
                ],

                const SizedBox(height: 16),

                // App Info
                _SettingsSection(
                  title: l10n.about,
                  icon: Icons.info_outline_rounded,
                  isDark: isDark,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.goldPrimary.withValues(alpha: 0.2),
                                  AppColors.goldPrimary.withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.school_rounded,
                              color: AppColors.goldPrimary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Efteqad',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                Text(
                                  '${l10n.version} 1.0.0',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ).animate().fade(delay: 300.ms).slideY(begin: 0.1),

                const SizedBox(height: 24),

                // Logout Button
                SafeArea(
                  child: FilledButton.icon(
                    onPressed: () =>
                        ref.read(authControllerProvider.notifier).logout(),
                    icon: const Icon(Icons.logout_rounded),
                    label: Text(
                      l10n.logout,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.1),
                      foregroundColor: Colors.red,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ).animate().fade(delay: 350.ms),
                ),

                const SizedBox(height: 16),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _getThemeName(BuildContext context, ThemeMode mode) {
    final l10n = AppLocalizations.of(context)!;
    switch (mode) {
      case ThemeMode.light:
        return l10n.light;
      case ThemeMode.dark:
        return l10n.dark;
      case ThemeMode.system:
        return l10n.system;
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
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ModernPickerSheet(
        title: l10n.theme,
        isDark: isDark,
        options: [
          _PickerOption(
            icon: Icons.brightness_auto_rounded,
            title: l10n.system,
            subtitle: l10n.systemThemeDesc,
            selected: current == ThemeMode.system,
            onTap: () {
              ref.read(themeModeProvider.notifier).setTheme(ThemeMode.system);
              Navigator.pop(context);
            },
          ),
          _PickerOption(
            icon: Icons.light_mode_rounded,
            title: l10n.light,
            subtitle: l10n.lightThemeDesc,
            selected: current == ThemeMode.light,
            onTap: () {
              ref.read(themeModeProvider.notifier).setTheme(ThemeMode.light);
              Navigator.pop(context);
            },
          ),
          _PickerOption(
            icon: Icons.dark_mode_rounded,
            title: l10n.dark,
            subtitle: l10n.darkThemeDesc,
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
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ModernPickerSheet(
        title: l10n.language,
        isDark: isDark,
        options: [
          _PickerOption(
            icon: Icons.language_rounded,
            title: 'English',
            subtitle: l10n.englishLanguageDesc,
            selected: current.languageCode == 'en',
            onTap: () {
              ref.read(localeProvider.notifier).setLocale(const Locale('en'));
              Navigator.pop(context);
            },
          ),
          _PickerOption(
            icon: Icons.language_rounded,
            title: 'العربية',
            subtitle: l10n.arabicLanguageDesc,
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
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.edit_note_rounded,
                color: Colors.teal,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.defaultAttendanceNote,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: l10n.defaultNoteHint,
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
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              ref.read(defaultNoteProvider.notifier).setNote(controller.text);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.goldPrimary,
            ),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    bool isDark,
  ) async {
    final localizations = l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.warning_rounded, color: Colors.red, size: 32),
        ),
        title: Text(l10n.resetDataTitle, textAlign: TextAlign.center),
        content: Text(l10n.resetDataConfirm, textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(syncServiceProvider).clearLocalData();
        if (context.mounted) {
          AppSnackBar.show(
            context,
            message: localizations.successResetData,
            type: AppSnackBarType.success,
          );
        }
      } catch (e) {
        if (context.mounted) {
          AppSnackBar.show(
            context,
            message: localizations.errorResetData(e.toString()),
            type: AppSnackBarType.error,
          );
        }
      }
    }
  }
}

// Modern Settings Section with header
class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;
  final List<Widget> children;
  final Color? accentColor;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.isDark,
    required this.children,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? (isDark ? Colors.white54 : Colors.black45);

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

// Modern Settings Tile
class _ModernSettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback? onTap;

  const _ModernSettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }
}

// Modern Picker Sheet
class _ModernPickerSheet extends StatelessWidget {
  final String title;
  final bool isDark;
  final List<_PickerOption> options;

  const _ModernPickerSheet({
    required this.title,
    required this.isDark,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
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
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Options
          ...options.map(
            (option) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: option,
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
        ],
      ),
    );
  }
}

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _PickerOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: selected
          ? AppColors.goldPrimary.withValues(alpha: 0.1)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.goldPrimary.withValues(alpha: 0.15)
                      : (isDark ? Colors.white10 : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: selected
                      ? AppColors.goldPrimary
                      : (isDark ? Colors.white54 : Colors.black45),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: selected
                            ? AppColors.goldPrimary
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.goldPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
