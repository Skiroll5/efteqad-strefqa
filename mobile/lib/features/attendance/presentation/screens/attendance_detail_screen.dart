import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _showDeleteDialog(context, ref),
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
              // Progress Bar Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Attendance Rate',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${(percentage * 100).toStringAsFixed(0)}%',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _getProgressColor(percentage),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        children: [
                          // Background
                          Container(
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          // Filled portion
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                            height: 16,
                            width:
                                MediaQuery.of(context).size.width *
                                percentage *
                                0.85, // Account for padding
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _getProgressColor(percentage),
                                  _getProgressColor(
                                    percentage,
                                  ).withOpacity(0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Summary text
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildMiniStat(
                          Icons.check_circle,
                          presentCount,
                          'Present',
                          AppColors.goldPrimary,
                        ),
                        const SizedBox(width: 24),
                        _buildMiniStat(
                          Icons.cancel,
                          total - presentCount,
                          'Absent',
                          Colors.grey,
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fade().slideY(begin: -0.1, end: 0),

              const Divider(height: 1),

              // Records List
              Expanded(
                child: records.isEmpty
                    ? const Center(child: Text('No attendance records'))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: records.length,
                        itemBuilder: (context, index) {
                          final item = records[index];
                          final isPresent = item.record.status == 'PRESENT';

                          return PremiumCard(
                            delay: index * 0.03,
                            margin: const EdgeInsets.only(bottom: 8),
                            color: isPresent
                                ? AppColors.goldPrimary.withOpacity(0.05)
                                : null,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: isPresent
                                      ? AppColors.goldPrimary
                                      : Colors.grey.shade300,
                                  child: Text(
                                    item.studentName[0].toUpperCase(),
                                    style: TextStyle(
                                      color: isPresent
                                          ? Colors.white
                                          : Colors.grey.shade600,
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
                                          ? FontWeight.bold
                                          : FontWeight.normal,
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

  Widget _buildMiniStat(IconData icon, int count, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          '$count $label',
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 0.8) return AppColors.goldPrimary;
    if (percentage >= 0.5) return Colors.orange;
    return AppColors.redPrimary;
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Session'),
        content: const Text(
          'Are you sure you want to delete this attendance session?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.redPrimary),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(attendanceControllerProvider.notifier)
                  .deleteSession(sessionId);
              if (context.mounted) context.pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
