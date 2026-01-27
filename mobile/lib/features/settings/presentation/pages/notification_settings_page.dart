import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/premium_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/data/auth_controller.dart';
import '../providers/notification_settings_provider.dart';

/// Format time string from "HH:mm" to readable format
String _formatTimeString(String timeStr) {
  final parts = timeStr.split(':');
  final hour = int.tryParse(parts[0]) ?? 8;
  final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
  final period = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
  final minuteStr = minute.toString().padLeft(2, '0');
  return '$displayHour:$minuteStr $period';
}

class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(notificationSettingsProvider);
    final user = ref.watch(authControllerProvider).value;
    final isAdmin = user?.role == 'ADMIN';
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            stretch: true,
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            Colors.purple.withValues(alpha: 0.15),
                            AppColors.surfaceDark,
                          ]
                        : [Colors.purple.withValues(alpha: 0.08), Colors.white],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.notifications_active_rounded,
                            color: Colors.purple,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.notificationSettings,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: isDark ? Colors.white : Colors.black87,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: settingsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, st) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.errorGeneric(err.toString()),
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              data: (prefs) {
                return SliverList(
                  delegate: SliverChildListDelegate([
                    PremiumCard(
                      child: Column(
                        children: [
                          _ModernNotificationSwitch(
                            icon: Icons.note_alt_outlined,
                            iconColor: Colors.indigo,
                            title: l10n.notesNotification,
                            description: l10n.notesNotificationDesc,
                            value: prefs.noteAdded,
                            onChanged: (val) => ref
                                .read(notificationSettingsProvider.notifier)
                                .updatePreference(
                                  prefs.copyWith(noteAdded: val),
                                ),
                            isDark: isDark,
                          ),
                          _Divider(isDark: isDark),
                          _ModernNotificationSwitch(
                            icon: Icons.fact_check_outlined,
                            iconColor: Colors.green,
                            title: l10n.attendanceNotification,
                            description: l10n.attendanceNotificationDesc,
                            value: prefs.attendanceRecorded,
                            onChanged: (val) => ref
                                .read(notificationSettingsProvider.notifier)
                                .updatePreference(
                                  prefs.copyWith(attendanceRecorded: val),
                                ),
                            isDark: isDark,
                          ),
                          _Divider(isDark: isDark),
                          _ModernNotificationSwitch(
                            icon: Icons.person_off_outlined,
                            iconColor: Colors.red,
                            title: l10n.inactiveNotification,
                            description: l10n.inactiveNotificationDesc,
                            value: prefs.inactiveStudent,
                            onChanged: (val) => ref
                                .read(notificationSettingsProvider.notifier)
                                .updatePreference(
                                  prefs.copyWith(inactiveStudent: val),
                                ),
                            isDark: isDark,
                          ),
                          if (isAdmin) ...[
                            _Divider(isDark: isDark),
                            _ModernNotificationSwitch(
                              icon: Icons.person_add_outlined,
                              iconColor: Colors.teal,
                              title: l10n.newUserNotification,
                              description: l10n.newUserNotificationDesc,
                              value: prefs.newUserRegistered,
                              onChanged: (val) => ref
                                  .read(notificationSettingsProvider.notifier)
                                  .updatePreference(
                                    prefs.copyWith(newUserRegistered: val),
                                  ),
                              isDark: isDark,
                            ),
                          ],
                          _Divider(isDark: isDark),
                          _ModernNotificationSwitch(
                            icon: Icons.cake_outlined,
                            iconColor: Colors.pink,
                            title: l10n.birthdayNotification,
                            description: l10n.birthdayNotificationDesc,
                            value: prefs.birthdayReminder,
                            onChanged: (val) => ref
                                .read(notificationSettingsProvider.notifier)
                                .updatePreference(
                                  prefs.copyWith(birthdayReminder: val),
                                ),
                            isDark: isDark,
                          ),
                          // Conditional Birthday Settings
                          AnimatedSize(
                            duration: 300.ms,
                            curve: Curves.easeInOut,
                            alignment: Alignment.topCenter,
                            child: prefs.birthdayReminder
                                ? Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 52,
                                          right: 16,
                                          bottom: 8,
                                        ),
                                        child: Column(
                                          children: [
                                            _ConfigurationTile(
                                              icon:
                                                  Icons.calendar_today_outlined,
                                              iconColor: Colors.pink,
                                              title: l10n.birthdayReminderDays,
                                              description:
                                                  l10n.birthdayReminderDaysDesc,
                                              isDark: isDark,
                                              trailing: _ModernDropdown<int>(
                                                value:
                                                    prefs.birthdayReminderDays,
                                                items: [0, 1, 2, 3, 7],
                                                labelBuilder: (e) => e == 0
                                                    ? l10n.sameDay
                                                    : l10n.daysBefore(e),
                                                onChanged: (val) {
                                                  if (val != null) {
                                                    ref
                                                        .read(
                                                          notificationSettingsProvider
                                                              .notifier,
                                                        )
                                                        .updatePreference(
                                                          prefs.copyWith(
                                                            birthdayReminderDays:
                                                                val,
                                                          ),
                                                        );
                                                  }
                                                },
                                                isDark: isDark,
                                              ),
                                              isSubsection: true,
                                            ),
                                            _ConfigurationTile(
                                              icon: Icons.access_time_rounded,
                                              iconColor: Colors.blue,
                                              title: l10n.birthdayAlertTime,
                                              description: l10n.tapToChangeTime,
                                              isDark: isDark,
                                              trailing: _TimePickerButton(
                                                time: prefs.birthdayNotifyTime,
                                                isDark: isDark,
                                                onTap: () async {
                                                  final parts = prefs
                                                      .birthdayNotifyTime
                                                      .split(':');
                                                  final initialTime = TimeOfDay(
                                                    hour:
                                                        int.tryParse(
                                                          parts[0],
                                                        ) ??
                                                        8,
                                                    minute:
                                                        int.tryParse(
                                                          parts.length > 1
                                                              ? parts[1]
                                                              : '0',
                                                        ) ??
                                                        0,
                                                  );
                                                  final picked = await showTimePicker(
                                                    context: context,
                                                    initialTime: initialTime,
                                                    builder: (context, child) {
                                                      return Theme(
                                                        data: theme.copyWith(
                                                          colorScheme: theme
                                                              .colorScheme
                                                              .copyWith(
                                                                primary: AppColors
                                                                    .goldPrimary,
                                                              ),
                                                        ),
                                                        child: child!,
                                                      );
                                                    },
                                                  );
                                                  if (picked != null) {
                                                    final timeStr =
                                                        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                                    ref
                                                        .read(
                                                          notificationSettingsProvider
                                                              .notifier,
                                                        )
                                                        .updatePreference(
                                                          prefs.copyWith(
                                                            birthdayNotifyTime:
                                                                timeStr,
                                                          ),
                                                        );
                                                  }
                                                },
                                              ),
                                              isSubsection: true,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ).animate().fade().slideY(begin: 0.1),
                    const SizedBox(height: 24),
                  ]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 64, // Indent to align with text
      endIndent: 0,
      color: isDark ? Colors.white10 : Colors.grey.shade100,
    );
  }
}

// Modern Notification Switch
class _ModernNotificationSwitch extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  const _ModernNotificationSwitch({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: value ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: value
                    ? iconColor
                    : (isDark ? Colors.white38 : Colors.black26),
                size: 20,
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
                      fontWeight: FontWeight.w600,
                      color: value
                          ? (isDark ? Colors.white : Colors.black87)
                          : (isDark ? Colors.white54 : Colors.black45),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.goldPrimary,
              activeTrackColor: AppColors.goldPrimary.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}

// Configuration Tile
class _ConfigurationTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final bool isDark;
  final Widget trailing;
  final bool isSubsection;

  const _ConfigurationTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.isDark,
    required this.trailing,
    this.isSubsection = false,
  });

  @override
  Widget build(BuildContext context) {
    // For subsection, we make it look smaller/lighter
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6), // Smaller icon for subsection
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isDark ? Colors.white54 : Colors.black54,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                if (description.isNotEmpty && !isSubsection)
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

// Modern Dropdown
class _ModernDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T?> onChanged;
  final bool isDark;

  const _ModernDropdown({
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          icon: Icon(
            Icons.expand_more_rounded,
            color: isDark ? Colors.white70 : Colors.black54,
            size: 18,
          ),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
          items: items.map((e) {
            return DropdownMenuItem(value: e, child: Text(labelBuilder(e)));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// Time Picker Button
class _TimePickerButton extends StatelessWidget {
  final String time;
  final bool isDark;
  final VoidCallback onTap;

  const _TimePickerButton({
    required this.time,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatTimeString(time),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
