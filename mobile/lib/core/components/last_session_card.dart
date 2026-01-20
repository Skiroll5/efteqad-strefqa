import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/home/data/home_insights_repository.dart';

class LastSessionCard extends ConsumerWidget {
  final ClassSessionStatus? sessionStatus;

  const LastSessionCard({super.key, this.sessionStatus});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (sessionStatus == null || !sessionStatus!.hasSession) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final status = sessionStatus!;

    final locale = Localizations.localeOf(context);
    final rateColor = _getRateColor(status.attendanceRate);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            if (status.session != null) {
              context.push('/attendance/${status.session!.id}');
            }
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: Class name + Label
                Row(
                  children: [
                    // Session icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.goldPrimary.withValues(alpha: 0.15)
                            : AppColors.goldPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.calendar_today_rounded,
                          color: AppColors.goldPrimary,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Class info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            status.className,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppColors.textPrimaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.lastSession,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Arrow
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: isDark ? Colors.white38 : Colors.black26,
                    ),
                  ],
                ),
                
                const SizedBox(height: 10),
                
                // Date/Time and Stats row
                Row(
                  children: [
                    // Date & Time combined
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: _formatDate(status.lastSessionDate!, locale),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                              ),
                            ),
                            TextSpan(
                              text: '  •  ',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white38 : Colors.black26,
                              ),
                            ),
                            TextSpan(
                              text: _formatTime(status.lastSessionDate!, locale),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Attendance stats
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: rateColor.withValues(alpha: isDark ? 0.15 : 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${status.presentCount}/${status.totalStudents}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 1,
                            height: 14,
                            color: isDark ? Colors.white24 : Colors.black12,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(status.attendanceRate * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: rateColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 10),
                
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: status.attendanceRate,
                    minHeight: 5,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      rateColor.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date, Locale locale) {
    // Arabic: "الأحد، 15 يناير" (day name, day month)
    // English: "Sunday, Jan 15" (day name, month day)
    final isArabic = locale.languageCode == 'ar';
    final pattern = isArabic ? 'EEEE، d MMM' : 'EEEE, MMM d';
    final fmt = DateFormat(pattern, locale.toString());
    return _toWesternDigits(fmt.format(date));
  }

  String _formatTime(DateTime date, Locale locale) {
    final fmt = DateFormat('h:mm a', locale.toString());
    return _toWesternDigits(fmt.format(date));
  }

  String _toWesternDigits(String input) {
    const eastern = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const western = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    for (int i = 0; i < eastern.length; i++) {
      input = input.replaceAll(eastern[i], western[i]);
    }
    return input;
  }

  Color _getRateColor(double rate) {
    if (rate >= 0.8) return Colors.green;
    if (rate >= 0.5) return Colors.orange;
    return Colors.red;
  }
}
