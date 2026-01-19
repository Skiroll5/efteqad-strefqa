import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
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

  String _getMonthAbbr(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Filter upcoming birthdays (next 30 days)
    final now = DateTime.now();
    final upcomingBirthdays = students.where((s) {
      if (s.birthdate == null) return false;
      final b = s.birthdate!;
      // Simple check: is month/day within next 30 days?
      // Normalize to current year
      var nextB = DateTime(now.year, b.month, b.day);
      if (nextB.isBefore(now.subtract(const Duration(days: 1)))) {
        nextB = DateTime(now.year + 1, b.month, b.day);
      }
      final diff = nextB.difference(now).inDays;
      return diff >= 0 && diff <= 30;
    }).toList();

    // Sort by soonest (closest first)
    upcomingBirthdays.sort((a, b) {
      var nextA = DateTime(now.year, a.birthdate!.month, a.birthdate!.day);
      if (nextA.isBefore(now.subtract(const Duration(days: 1)))) {
        nextA = DateTime(now.year + 1, a.birthdate!.month, a.birthdate!.day);
      }

      var nextB = DateTime(now.year, b.birthdate!.month, b.birthdate!.day);
      if (nextB.isBefore(now.subtract(const Duration(days: 1)))) {
        nextB = DateTime(now.year + 1, b.birthdate!.month, b.birthdate!.day);
      }

      return nextA.compareTo(nextB);
    });

    if (upcomingBirthdays.isEmpty) {
      // Show empty state
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Row(
              children: [
                Icon(Icons.cake, size: 18, color: AppColors.goldPrimary),
                const SizedBox(width: 8),
                Text(
                  l10n?.upcomingBirthdays ?? "Upcoming Birthdays",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event_busy,
                  size: 20,
                  color: isDark ? Colors.white38 : Colors.grey.shade400,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n?.noUpcomingBirthdays ?? "No upcoming birthdays in the next 30 days.",
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
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
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 0,
          ), // Parent handles padding
          child:
              Row(
                    children: [
                      Icon(Icons.cake, size: 18, color: AppColors.goldPrimary),
                      const SizedBox(width: 8),
                      Text(
                        l10n?.upcomingBirthdays ?? "Upcoming Birthdays",
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                      ),
                    ],
                  )
                  .animate()
                  .fade(delay: 100.ms)
                  .slideY(begin: 0.2, curve: Curves.easeOut),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 85,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 0),
            itemCount: upcomingBirthdays.length,
            itemBuilder: (context, index) {
              final student = upcomingBirthdays[index];
              final b = student.birthdate!;

              // Calculate days
              var nextB = DateTime(now.year, b.month, b.day);
              if (nextB.isBefore(now.subtract(const Duration(days: 1)))) {
                nextB = DateTime(now.year + 1, b.month, b.day);
              }
              final diff = nextB.difference(now).inDays;
              final isToday = diff == 0;

              return Container(
                    width: 155,
                    margin: const EdgeInsets.only(right: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          await Future.delayed(
                            const Duration(milliseconds: 150),
                          );
                          if (context.mounted) {
                            context.push('/students/${student.id}');
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        splashColor: AppColors.goldPrimary.withValues(
                          alpha: 0.2,
                        ),
                        highlightColor: AppColors.goldPrimary.withValues(
                          alpha: 0.1,
                        ),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: isToday
                                ? LinearGradient(
                                    colors: [
                                      AppColors.goldPrimary.withValues(
                                        alpha: 0.25,
                                      ),
                                      AppColors.goldDark.withValues(
                                        alpha: 0.15,
                                      ),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isToday
                                ? null
                                : (isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.grey.withValues(alpha: 0.08)),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isToday
                                  ? AppColors.goldPrimary.withValues(alpha: 0.6)
                                  : (isDark
                                        ? Colors.white10
                                        : Colors.grey.shade200),
                              width: isToday ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Date Box
                              Container(
                                width: 44,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: isToday
                                      ? AppColors.goldPrimary
                                      : (isDark
                                            ? AppColors.goldPrimary.withValues(
                                                alpha: 0.15,
                                              )
                                            : AppColors.goldPrimary.withValues(
                                                alpha: 0.12,
                                              )),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      b.day.toString(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: isToday
                                            ? Colors.white
                                            : AppColors.goldDark,
                                      ),
                                    ),
                                    Text(
                                      _getMonthAbbr(b.month),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isToday
                                            ? Colors.white70
                                            : AppColors.goldPrimary,
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
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: isDark
                                                ? Colors.grey.shade400
                                                : Colors.grey.shade600,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        if (isToday)
                                          const Text(
                                            "🎉 ",
                                            style: TextStyle(fontSize: 11),
                                          ),
                                        Flexible(
                                          child: Text(
                                            isToday
                                                ? (l10n?.today ?? "Today!")
                                                : (l10n?.daysLeft(diff) ??
                                                      "$diff days"),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: isToday
                                                  ? (isDark
                                                        ? Colors.white70
                                                        : AppColors.goldDark)
                                                  : AppColors.goldPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                  .animate()
                  .fade(delay: (index * 50).ms)
                  .slideX(begin: 0.1, end: 0);
            },
          ),
        ),
      ],
    );
  }
}
