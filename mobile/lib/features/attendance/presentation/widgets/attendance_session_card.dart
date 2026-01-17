import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/database/app_database.dart';
import '../../data/attendance_controller.dart';

class AttendanceSessionCard extends ConsumerWidget {
  final AttendanceSession session;
  final bool isDark;

  const AttendanceSessionCard({
    super.key,
    required this.session,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeCode = Localizations.localeOf(context).languageCode;

    String fixLocalization(String input) {
      // 1. Force Latin numbers
      const eastern = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
      const western = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
      var result = input;
      for (int i = 0; i < eastern.length; i++) {
        result = result.replaceAll(eastern[i], western[i]);
      }

      // 2. Use Arabic comma if Arabic
      if (localeCode.startsWith('ar')) {
        result = result.replaceAll(',', '،');
      }
      return result;
    }

    final datePart = fixLocalization(
      DateFormat.yMMMEd(localeCode).format(session.date),
    );
    final timePart = fixLocalization(
      DateFormat.jm(localeCode).format(session.date),
    );

    final String title;
    final String? subtitle;

    if (session.note != null && session.note!.isNotEmpty) {
      title = session.note!;
      subtitle = '$datePart • $timePart';
    } else {
      title = '$datePart • $timePart';
      subtitle = null;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await Future.delayed(const Duration(milliseconds: 150));
            if (context.mounted) {
              context.push('/attendance/${session.id}');
            }
          },
          borderRadius: BorderRadius.circular(14),
          splashColor: AppColors.goldPrimary.withValues(alpha: 0.15),
          highlightColor: AppColors.goldPrimary.withValues(alpha: 0.08),
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                // Percentage Box (Previously Date Box)
                Consumer(
                  builder: (context, ref, child) {
                    final recordsAsync = ref.watch(
                      sessionRecordsWithStudentsProvider(session.id),
                    );

                    return recordsAsync.when(
                      data: (records) {
                        final presentCount = records
                            .where((r) => r.record?.status == 'PRESENT')
                            .length;
                        final total = records
                            .where((r) => r.record != null)
                            .length;
                        final percentage = total > 0
                            ? (presentCount / total * 100).toInt()
                            : 0;
                        final percentageColor = percentage >= 75
                            ? (isDark ? Colors.green.shade400 : Colors.green)
                            : percentage >= 50
                            ? Colors.orange
                            : (isDark
                                  ? AppColors.redLight
                                  : AppColors.redPrimary);

                        return Container(
                          width: 52,
                          height: 56,
                          decoration: BoxDecoration(
                            color: percentageColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: percentageColor.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: percentage.toString(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: percentageColor,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '%',
                                      style: TextStyle(
                                        fontSize: 12, // Smaller %
                                        fontWeight: FontWeight.bold,
                                        color: percentageColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      loading: () => Container(
                        width: 52,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      error: (_, __) => const SizedBox(width: 52, height: 56),
                    );
                  },
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                      ),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  // fontStyle: FontStyle.italic,
                                  color: isDark
                                      ? Colors.grey.shade500
                                      : Colors.grey.shade500,
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Chevron
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: isDark ? Colors.white30 : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
