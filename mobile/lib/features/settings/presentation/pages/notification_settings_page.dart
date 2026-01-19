import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/premium_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/data/auth_controller.dart';
import '../providers/notification_settings_provider.dart';

class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(notificationSettingsProvider);
    final user = ref.watch(authControllerProvider).value;
    final isAdmin = user?.role == 'ADMIN';
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.notificationSettings ?? 'Notification Settings'),
        centerTitle: false,
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
        data: (prefs) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Event Notifications Card
              PremiumCard(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      title:
                          l10n?.events ??
                          'Events', // Need to check if 'events' key exists, fallback provided
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _NotificationSwitchTile(
                      title: l10n?.notesNotification ?? 'Notes',
                      icon: Icons.note_alt_outlined,
                      description:
                          l10n?.notesNotificationDesc ??
                          'Get notified when a note is added', // Fallback
                      value: prefs.noteAdded,
                      onChanged: (val) => ref
                          .read(notificationSettingsProvider.notifier)
                          .updatePreference(prefs.copyWith(noteAdded: val)),
                      isDark: isDark,
                    ),
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: isDark ? Colors.white10 : Colors.grey.shade100,
                    ),
                    _NotificationSwitchTile(
                      title: l10n?.attendanceNotification ?? 'Attendance',
                      icon: Icons.fact_check_outlined,
                      description: 'Get notified when attendance is recorded',
                      value: prefs.attendanceRecorded,
                      onChanged: (val) => ref
                          .read(notificationSettingsProvider.notifier)
                          .updatePreference(
                            prefs.copyWith(attendanceRecorded: val),
                          ),
                      isDark: isDark,
                    ),
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: isDark ? Colors.white10 : Colors.grey.shade100,
                    ),
                    _NotificationSwitchTile(
                      title:
                          l10n?.birthdayNotification ?? 'Birthday Reminders',
                      icon: Icons.cake_outlined,
                      description: 'Get reminders for student birthdays',
                      value: prefs.birthdayReminder,
                      onChanged: (val) => ref
                          .read(notificationSettingsProvider.notifier)
                          .updatePreference(
                            prefs.copyWith(birthdayReminder: val),
                          ),
                      isDark: isDark,
                    ),
                  ],
                ),
              ).animate().fade().slideY(begin: 0.1, end: 0),

              // Alerts & Warnings Card
              PremiumCard(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      title: l10n?.alerts ?? 'Alerts',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _NotificationSwitchTile(
                      title:
                          l10n?.inactiveNotification ?? 'Inactive Students',
                      icon: Icons.person_off_outlined,
                      description: 'Alert when a student becomes inactive',
                      value: prefs.inactiveStudent,
                      onChanged: (val) => ref
                          .read(notificationSettingsProvider.notifier)
                          .updatePreference(
                            prefs.copyWith(inactiveStudent: val),
                          ),
                      isDark: isDark,
                    ),
                    if (isAdmin) ...[
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: isDark ? Colors.white10 : Colors.grey.shade100,
                      ),
                      _NotificationSwitchTile(
                        title:
                            l10n?.newUserNotification ?? 'New Registrations',
                        icon: Icons.person_add_outlined,
                        description: 'Notify when a new user registers',
                        value: prefs.newUserRegistered,
                        onChanged: (val) => ref
                            .read(notificationSettingsProvider.notifier)
                            .updatePreference(
                              prefs.copyWith(newUserRegistered: val),
                            ),
                        isDark: isDark,
                      ),
                    ],
                  ],
                ),
              ).animate().fade(delay: 100.ms).slideY(begin: 0.1, end: 0),

              // Configuration Card
              PremiumCard(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      title: l10n?.configuration ?? 'Configuration',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      title: Text(
                        l10n?.inactiveAfterDays ?? 'Inactive after (days)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      subtitle: Text(
                        'Threshold to consider a student inactive',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark
                                ? Colors.white24
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: prefs.inactiveThresholdDays,
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: isDark
                                  ? Colors.white70
                                  : Colors.grey.shade600,
                            ),
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            dropdownColor: isDark
                                ? AppColors.surfaceDark
                                : AppColors.surfaceLight,
                            items: [7, 14, 21, 30].map((e) {
                              return DropdownMenuItem(
                                value: e,
                                child: Text(l10n?.daysUnit(e) ?? '$e days'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                ref
                                    .read(notificationSettingsProvider.notifier)
                                    .updatePreference(
                                      prefs.copyWith(
                                        inactiveThresholdDays: val,
                                      ),
                                    );
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: isDark ? Colors.white10 : Colors.grey.shade100,
                    ),
                    ListTile(
                      title: Text(
                        l10n?.birthdayAlertTime ?? 'Birthday alert time',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      subtitle: Text(
                        prefs.birthdayNotifyMorning
                            ? (l10n?.morningTime ?? 'Morning (8:00 AM)')
                            : (l10n?.eveningTime ?? 'Evening before (8:00 PM)'),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      trailing: Switch(
                        value: prefs.birthdayNotifyMorning,
                        activeTrackColor: AppColors.goldPrimary,
                        activeColor: Colors.white,
                        onChanged: (val) {
                          ref
                              .read(notificationSettingsProvider.notifier)
                              .updatePreference(
                                prefs.copyWith(birthdayNotifyMorning: val),
                              );
                        },
                      ),
                    ),
                  ],
                ),
              ).animate().fade(delay: 200.ms).slideY(begin: 0.1, end: 0),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: isDark ? AppColors.goldPrimary : AppColors.goldDark,
        ),
      ),
    );
  }
}

class _NotificationSwitchTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  const _NotificationSwitchTile({
    required this.title,
    required this.icon,
    required this.description,
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.goldPrimary,
      title: Row(
        children: [
          Icon(icon, size: 20, color: isDark ? AppColors.goldPrimary : AppColors.goldDark),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(left: 32.0),
        child: Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ),
    );
  }
}
