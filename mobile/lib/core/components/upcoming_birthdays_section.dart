import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/l10n/app_localizations.dart';

class UpcomingBirthdaysSection extends StatelessWidget {
  final List<Student> students;
  final bool isDark;

  const UpcomingBirthdaysSection({
    super.key,
    required this.students,
    required this.isDark,
  });

  String _getMonthAbbr(int month, Locale locale) {
    // Create a date in that month and format it
    final date = DateTime(2024, month, 15);
    return DateFormat.MMM(locale.toString()).format(date);
  }

  int _getDaysUntilBirthday(DateTime birthdate) {
    final now = DateTime.now();
    // Normalize to start of day for accurate day counting
    final today = DateTime(now.year, now.month, now.day);
    
    var nextBirthday = DateTime(today.year, birthdate.month, birthdate.day);
    if (nextBirthday.isBefore(today)) {
      nextBirthday = DateTime(today.year + 1, birthdate.month, birthdate.day);
    }
    
    return nextBirthday.difference(today).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);

    // Filter upcoming birthdays (next 30 days)
    final upcomingBirthdays = students.where((s) {
      if (s.birthdate == null) return false;
      final diff = _getDaysUntilBirthday(s.birthdate!);
      return diff >= 0 && diff <= 30;
    }).toList();

    // Sort by soonest (closest first)
    upcomingBirthdays.sort((a, b) {
      final daysA = _getDaysUntilBirthday(a.birthdate!);
      final daysB = _getDaysUntilBirthday(b.birthdate!);
      return daysA.compareTo(daysB);
    });

    if (upcomingBirthdays.isEmpty) {
      // Show empty state
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.upcomingBirthdays,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.cake_outlined,
                  size: 20,
                  color: isDark ? Colors.white38 : Colors.black26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.noUpcomingBirthdays,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.upcomingBirthdays,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimaryLight,
          ),
        ).animate().fade(delay: 100.ms).slideY(begin: 0.2, curve: Curves.easeOut),
        const SizedBox(height: 12),
        SizedBox(
          height: 74,
          child: ClipRect(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: upcomingBirthdays.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final student = upcomingBirthdays[index];
                final b = student.birthdate!;

                // Calculate days using normalized method
                final diff = _getDaysUntilBirthday(b);
                final isToday = diff == 0;
                final isTomorrow = diff == 1;

                return _BirthdayCard(
                  student: student,
                  birthdate: b,
                  daysLeft: diff,
                  isToday: isToday,
                  isTomorrow: isTomorrow,
                  isDark: isDark,
                  locale: locale,
                  l10n: l10n,
                  getMonthAbbr: _getMonthAbbr,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _BirthdayCard extends StatelessWidget {
  final Student student;
  final DateTime birthdate;
  final int daysLeft;
  final bool isToday;
  final bool isTomorrow;
  final bool isDark;
  final Locale locale;
  final AppLocalizations? l10n;
  final String Function(int, Locale) getMonthAbbr;

  const _BirthdayCard({
    required this.student,
    required this.birthdate,
    required this.daysLeft,
    required this.isToday,
    required this.isTomorrow,
    required this.isDark,
    required this.locale,
    required this.l10n,
    required this.getMonthAbbr,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: 180,
      child: Material(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/students/${student.id}'),
          child: Stack(
            children: [
              // Confetti decorations in background (on the right/end side)
              Positioned(
                top: 6,
                left: 8,
                child: Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: AppColors.goldPrimary.withValues(alpha: isToday ? 0.4 : 0.15),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 24,
                child: Icon(
                  Icons.celebration,
                  size: 12,
                  color: AppColors.goldPrimary.withValues(alpha: isToday ? 0.3 : 0.1),
                ),
              ),
              Positioned(
                top: 14,
                left: 30,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.goldPrimary.withValues(alpha: isToday ? 0.5 : 0.2),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: 18,
                left: 10,
                child: Container(
                  width: 3,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.goldPrimary.withValues(alpha: isToday ? 0.4 : 0.15),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Main content
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isToday
                        ? AppColors.goldPrimary.withValues(alpha: 0.5)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06)),
                    width: isToday ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Date Box
                    Container(
                      width: 42,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isToday
                            ? AppColors.goldPrimary
                            : (isDark
                                ? AppColors.goldPrimary.withValues(alpha: 0.15)
                                : AppColors.goldPrimary.withValues(alpha: 0.1)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            birthdate.day.toString(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isToday ? Colors.white : AppColors.goldDark,
                            ),
                          ),
                          Text(
                            getMonthAbbr(birthdate.month, locale),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isToday ? Colors.white70 : AppColors.goldPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Name & countdown
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isToday
                                ? "🎉 ${l10n.today}"
                                : isTomorrow
                                    ? l10n.tomorrow
                                    : l10n.daysLeft(daysLeft),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isToday || isTomorrow
                                  ? AppColors.goldPrimary
                                  : (isDark ? Colors.white54 : Colors.black45),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Arrow indicator
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: isDark ? Colors.white30 : Colors.black26,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fade(delay: (50).ms).slideX(begin: 0.1, end: 0);
  }
}
