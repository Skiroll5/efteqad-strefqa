import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/premium_button.dart';
import '../../../../core/components/keep_alive_wrapper.dart';
import '../../data/attendance_controller.dart';
import '../../../classes/data/classes_controller.dart';
import '../../../students/data/students_controller.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/attendance_session_card.dart';

class AttendanceSessionListScreen extends ConsumerStatefulWidget {
  const AttendanceSessionListScreen({super.key});

  @override
  ConsumerState<AttendanceSessionListScreen> createState() =>
      _AttendanceSessionListScreenState();
}

class _AttendanceSessionListScreenState
    extends ConsumerState<AttendanceSessionListScreen> {
  late final DateTime _loadTime;

  @override
  void initState() {
    super.initState();
    _loadTime = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(attendanceSessionsProvider);
    final studentsAsync = ref.watch(classStudentsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedClassId = ref.watch(selectedClassIdProvider);
    final classesAsync = ref.watch(classesStreamProvider);
    final l10n = AppLocalizations.of(context);

    // Check if class has students
    final hasStudents = studentsAsync.maybeWhen(
      data: (students) => students.isNotEmpty,
      orElse: () => false,
    );

    // Get class name for title
    String? className;
    classesAsync.whenData((classes) {
      final cls = classes.where((c) => c.id == selectedClassId).firstOrNull;
      className = cls?.name;
    });

    final title = className != null
        ? '$className - ${l10n?.attendance ?? 'Attendance'}'
        : (l10n?.attendance ?? 'Attendance');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(title),
      ),
      body: Column(
        children: [
          Expanded(
            child: sessionsAsync.when(
              data: (sessions) {
                if (sessions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_note_outlined,
                          size: 80,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ).animate().scale(
                          duration: 500.ms,
                          curve: Curves.easeOutBack,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No attendance sessions yet',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ).animate().fade(delay: 200.ms),
                        const SizedBox(height: 8),
                        Text(
                          hasStudents
                              ? 'Tap below to take attendance'
                              : 'Add students first to take attendance',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ).animate().fade(delay: 400.ms),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    // Sort by date descending
                    final sortedSessions = List.from(sessions)
                      ..sort((a, b) => b.date.compareTo(a.date));
                    final session = sortedSessions[index];

                    // Time-based restriction: Only animate items built in the first 600ms
                    final isInitialLoad =
                        DateTime.now().difference(_loadTime).inMilliseconds <
                        600;
                    final shouldAnimate = isInitialLoad && (index < 12);

                    Widget card = AttendanceSessionCard(
                      session: session,
                      isDark: isDark,
                    );

                    if (shouldAnimate) {
                      card = card
                          .animate()
                          .fade(duration: 400.ms, delay: (index * 50).ms)
                          .slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
                    }

                    return KeepAliveWrapper(child: card);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(child: Text('Error: $err')),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.shade200,
                ),
              ),
            ),
            child: PremiumButton(
              label: hasStudents
                  ? (l10n?.takeAttendance ?? 'Take Attendance')
                  : 'Add students first',
              icon: hasStudents ? Icons.add : Icons.warning_amber_rounded,
              isFullWidth: true,
              onPressed: hasStudents
                  ? () => context.push('/attendance/new')
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
