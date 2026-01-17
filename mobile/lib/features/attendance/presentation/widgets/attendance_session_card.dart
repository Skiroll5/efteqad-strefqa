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
                // Date Box
                Container(
                  width: 52,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.goldPrimary.withValues(alpha: 0.15)
                        : AppColors.goldPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        session.date.day.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.goldDark,
                        ),
                      ),
                      Text(
                        DateFormat.MMM().format(session.date).toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.goldPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${DateFormat('EEEE', Localizations.localeOf(context).languageCode).format(session.date)} - ${DateFormat('HH:mm', 'en').format(session.date)}',
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
                      if (session.note != null && session.note!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            session.note!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: isDark
                                      ? Colors.grey.shade500
                                      : Colors.grey.shade500,
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Percentage Badge + Chevron
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
                        final percentageColor = percentage >= 80
                            ? AppColors.goldPrimary
                            : percentage >= 50
                            ? Colors.orange
                            : AppColors.redPrimary;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: percentageColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$percentage%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: percentageColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.chevron_right,
                              size: 20,
                              color: isDark
                                  ? Colors.white30
                                  : Colors.grey.shade400,
                            ),
                          ],
                        );
                      },
                      loading: () => Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: isDark ? Colors.white30 : Colors.grey.shade400,
                      ),
                      error: (_, __) => Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: isDark ? Colors.white30 : Colors.grey.shade400,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
