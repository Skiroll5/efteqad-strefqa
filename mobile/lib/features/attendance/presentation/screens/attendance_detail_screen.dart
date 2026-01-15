import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/premium_card.dart';
import '../../data/attendance_controller.dart';

class AttendanceDetailScreen extends ConsumerWidget {
  final String sessionId;

  const AttendanceDetailScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(
      sessionRecordsWithStudentsProvider(sessionId),
    );
    final sessionsAsync = ref.watch(attendanceSessionsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get session info for date display
    String dateText = 'Attendance';
    sessionsAsync.whenData((sessions) {
      final session = sessions.where((s) => s.id == sessionId).firstOrNull;
      if (session != null) {
        dateText = DateFormat.yMMMd().format(session.date);
      }
    });

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateText,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Attendance Details',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: AppColors.redPrimary.withOpacity(0.8),
            ),
            onPressed: () => _showDeleteSheet(context, ref),
            tooltip: 'Delete',
          ),
        ],
      ),
      body: recordsAsync.when(
        data: (records) {
          final presentCount = records
              .where((r) => r.record.status == 'PRESENT')
              .length;
          final total = records.length;
          final percentage = total > 0 ? (presentCount / total) : 0.0;

          return Column(
            children: [
              // Stats Header
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            AppColors.goldPrimary.withOpacity(0.2),
                            AppColors.goldDark.withOpacity(0.1),
                          ]
                        : [
                            AppColors.bluePrimary.withOpacity(0.1),
                            AppColors.blueLight.withOpacity(0.05),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        (isDark ? AppColors.goldPrimary : AppColors.bluePrimary)
                            .withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    // Big Percentage
                    Text(
                      '${(percentage * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: _getProgressColor(percentage),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Attendance Rate',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        children: [
                          Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white12
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOutCubic,
                            height: 12,
                            width:
                                MediaQuery.of(context).size.width *
                                percentage *
                                0.75,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _getProgressColor(percentage),
                                  _getProgressColor(
                                    percentage,
                                  ).withOpacity(0.6),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Present / Absent Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatChip(
                          icon: Icons.check_circle,
                          label: 'Present',
                          count: presentCount,
                          color: AppColors.goldPrimary,
                          isDark: isDark,
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: isDark ? Colors.white12 : Colors.grey.shade300,
                        ),
                        _StatChip(
                          icon: Icons.cancel,
                          label: 'Absent',
                          count: total - presentCount,
                          color: Colors.grey,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fade().scale(
                begin: const Offset(0.95, 0.95),
                end: const Offset(1, 1),
              ),

              // Students List Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'STUDENTS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '($total)',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Records List
              Expanded(
                child: records.isEmpty
                    ? Center(
                        child: Text(
                          'No attendance records',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: records.length,
                        itemBuilder: (context, index) {
                          final item = records[index];
                          final isPresent = item.record.status == 'PRESENT';

                          return PremiumCard(
                            delay: index * 0.02,
                            margin: const EdgeInsets.only(bottom: 8),
                            color: isPresent
                                ? AppColors.goldPrimary.withOpacity(
                                    isDark ? 0.1 : 0.05,
                                  )
                                : null,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: isPresent
                                      ? AppColors.goldPrimary
                                      : (isDark
                                            ? Colors.grey.shade700
                                            : Colors.grey.shade200),
                                  child: Text(
                                    item.studentName[0].toUpperCase(),
                                    style: TextStyle(
                                      color: isPresent
                                          ? Colors.white
                                          : (isDark
                                                ? Colors.white70
                                                : Colors.grey),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item.studentName,
                                    style: TextStyle(
                                      fontWeight: isPresent
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isPresent
                                          ? (isDark
                                                ? AppColors.textPrimaryDark
                                                : AppColors.textPrimaryLight)
                                          : (isDark
                                                ? AppColors.textSecondaryDark
                                                : AppColors.textSecondaryLight),
                                    ),
                                  ),
                                ),
                                Icon(
                                  isPresent
                                      ? Icons.check_circle
                                      : Icons.cancel_outlined,
                                  color: isPresent
                                      ? AppColors.goldPrimary
                                      : Colors.grey.shade400,
                                  size: 22,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 0.8) return AppColors.goldPrimary;
    if (percentage >= 0.5) return Colors.orange;
    return AppColors.redPrimary;
  }

  void _showDeleteSheet(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.redPrimary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_forever,
                  color: AppColors.redPrimary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Delete this session?',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'This attendance session and all its records will be permanently deleted.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await ref
                            .read(attendanceControllerProvider.notifier)
                            .deleteSession(sessionId);
                        if (context.mounted) context.pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.redPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final bool isDark;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}
