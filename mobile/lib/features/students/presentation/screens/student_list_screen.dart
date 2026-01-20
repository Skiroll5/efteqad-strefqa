import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile/features/attendance/data/attendance_controller.dart';
import 'package:mobile/features/attendance/data/attendance_repository.dart';

import '../../../../core/components/app_snackbar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/upcoming_birthdays_section.dart';
import '../../../../core/components/global_at_risk_widget.dart';
import '../../../../core/components/premium_card.dart';
import '../../../../core/database/app_database.dart';
import '../../data/students_controller.dart';
import 'package:mobile/features/classes/data/classes_controller.dart';
import 'package:mobile/features/statistics/data/statistics_repository.dart';
import 'package:mobile/l10n/app_localizations.dart';
import '../../../../features/auth/data/auth_controller.dart';
import '../../../../features/settings/data/settings_controller.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:mobile/features/attendance/presentation/widgets/attendance_session_card.dart';

enum StudentSortField { name, percentage }

enum SortDirection { asc, desc }

class StudentSortState {
  final StudentSortField field;
  final SortDirection direction;

  const StudentSortState({
    this.field = StudentSortField.name,
    this.direction = SortDirection.asc,
  });

  StudentSortState copyWith({
    StudentSortField? field,
    SortDirection? direction,
  }) {
    return StudentSortState(
      field: field ?? this.field,
      direction: direction ?? this.direction,
    );
  }
}

final studentSortProvider = StateProvider<StudentSortState>((ref) {
  return const StudentSortState();
});

enum StudentFilterMode { all, atRiskOnly }

final studentFilterProvider = StateProvider<StudentFilterMode>((ref) {
  return StudentFilterMode.all;
});

class StudentListScreen extends ConsumerStatefulWidget {
  const StudentListScreen({super.key});

  @override
  ConsumerState<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends ConsumerState<StudentListScreen> {
  bool _allowAnimation = true;

  @override
  void initState() {
    super.initState();
    // Disable animation after initial load
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _allowAnimation = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(classStudentsProvider);
    final selectedClassId = ref.watch(selectedClassIdProvider);
    final classesAsync = ref.watch(classesStreamProvider);
    final userClassesAsync = ref.watch(userClassesStreamProvider);
    final user = ref.watch(authControllerProvider).asData?.value;
    final attendanceStatsAsync = selectedClassId != null
        ? ref.watch(classAttendanceStatsProvider(selectedClassId))
        : const AsyncValue.data(<String, StudentAttendanceStats>{});
    final sessionsAsync = ref.watch(attendanceSessionsProvider);
    final atRiskThreshold = ref.watch(statisticsSettingsProvider);

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get class name and determine if single-class manager
    String? className;
    int userClassCount = 0;
    classesAsync.whenData((classes) {
      final cls = classes.where((c) => c.id == selectedClassId).firstOrNull;
      className = cls?.name;
    });
    userClassesAsync.whenData((classes) {
      userClassCount = classes.length;
    });

    // Single-class manager: no back button, show settings
    final isSingleClassManager = user?.role != 'ADMIN' && userClassCount == 1;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        // Only show back button if user has multiple classes or is admin
        leading: isSingleClassManager
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  ref.read(selectedClassIdProvider.notifier).state = null;
                  context.go('/');
                },
              ),
        automaticallyImplyLeading: !isSingleClassManager,
        title: Text(className ?? l10n.students),
        actions: [
          // Show settings for single-class managers
          if (isSingleClassManager)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: l10n.settings,
              onPressed: () => context.push('/settings'),
            ),
        ],
      ),
      body: studentsAsync.when(
        data: (students) {
          final sortState = ref.watch(studentSortProvider);
          final statsMap = attendanceStatsAsync.value ?? {};
          final sessions = sessionsAsync.value ?? [];

          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // 1. Birthday Section
              if (students.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: UpcomingBirthdaysSection(
                      students: students,
                      isDark: isDark,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // 2. Attendance Sessions Section (Inline)
              SliverToBoxAdapter(
                child: _buildSessionsSection(
                  context,
                  sessions,
                  ref,
                  isDark,
                  l10n,
                  selectedClassId,
                ),
              ),

              // 3. At Risk Students Section
              if (selectedClassId != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                    child: Consumer(
                      builder: (context, ref, _) {
                        final atRiskAsync = ref.watch(
                          classAtRiskStudentsProvider(selectedClassId),
                        );
                        return atRiskAsync.when(
                          data: (atRiskStudents) => GlobalAtRiskWidget(
                            atRiskStudents: atRiskStudents,
                            isDark: isDark,
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        );
                      },
                    ),
                  ),
                ),

              // 4. Student List Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: Title + Add Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                                "${l10n.students} (${students.length})",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              )
                              .animate()
                              .fade(delay: 200.ms)
                              .slideY(begin: 0.2, curve: Curves.easeOut),
                          Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () =>
                                      _showAddStudentDialog(context, ref),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.goldPrimary.withValues(
                                              alpha: 0.1,
                                            )
                                          : AppColors.goldPrimary.withValues(
                                              alpha: 0.1,
                                            ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDark
                                            ? AppColors.goldPrimary.withValues(
                                                alpha: 0.2,
                                              )
                                            : AppColors.goldPrimary.withValues(
                                                alpha: 0.3,
                                              ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.add,
                                          size: 18,
                                          color: isDark
                                              ? AppColors.goldPrimary
                                              : AppColors.goldDark,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          l10n.addNewStudent,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isDark
                                                ? AppColors.goldPrimary
                                                : AppColors.goldDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                              .animate()
                              .fade(delay: 200.ms)
                              .slideY(begin: 0.2, curve: Curves.easeOut),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Row 2: Sorting + Filter
                      Row(
                            children: [
                              // Sorting Chips
                              Container(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1E1E1E)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: Row(
                                  children: [
                                    _buildSortChip(
                                      context: context,
                                      label: l10n.name,
                                      isActive:
                                          sortState.field ==
                                          StudentSortField.name,
                                      direction: sortState.direction,
                                      isDark: isDark,
                                      onTap: () {
                                        final current = ref.read(
                                          studentSortProvider,
                                        );
                                        ref
                                            .read(studentSortProvider.notifier)
                                            .state = current.copyWith(
                                          field: StudentSortField.name,
                                          direction:
                                              current.field ==
                                                  StudentSortField.name
                                              ? (current.direction ==
                                                        SortDirection.asc
                                                    ? SortDirection.desc
                                                    : SortDirection.asc)
                                              : SortDirection.asc,
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 4),
                                    _buildSortChip(
                                      context: context,
                                      label: l10n.attendancePercentage,
                                      isActive:
                                          sortState.field ==
                                          StudentSortField.percentage,
                                      direction: sortState.direction,
                                      isDark: isDark,
                                      onTap: () {
                                        final current = ref.read(
                                          studentSortProvider,
                                        );
                                        ref
                                            .read(studentSortProvider.notifier)
                                            .state = current.copyWith(
                                          field: StudentSortField.percentage,
                                          direction:
                                              current.field ==
                                                  StudentSortField.percentage
                                              ? (current.direction ==
                                                        SortDirection.asc
                                                    ? SortDirection.desc
                                                    : SortDirection.asc)
                                              : SortDirection.desc,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Filter Toggle
                              Consumer(
                                builder: (context, ref, child) {
                                  final filterMode = ref.watch(
                                    studentFilterProvider,
                                  );
                                  final isFiltered =
                                      filterMode ==
                                      StudentFilterMode.atRiskOnly;
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: isFiltered
                                          ? AppColors.redPrimary.withValues(
                                              alpha: 0.1,
                                            )
                                          : (isDark
                                                ? const Color(0xFF1E1E1E)
                                                : Colors.grey.shade100),
                                      borderRadius: BorderRadius.circular(12),
                                      border: isFiltered
                                          ? Border.all(
                                              color: AppColors.redPrimary,
                                              width: 1,
                                            )
                                          : null,
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.warning_amber_rounded,
                                        color: isFiltered
                                            ? AppColors.redPrimary
                                            : (isDark
                                                  ? Colors.grey.shade600
                                                  : Colors.grey.shade400),
                                        size: 20,
                                      ),
                                      tooltip: isFiltered
                                          ? 'Show All'
                                          : 'At Risk Only',
                                      onPressed: () {
                                        ref
                                            .read(
                                              studentFilterProvider.notifier,
                                            )
                                            .state = isFiltered
                                            ? StudentFilterMode.all
                                            : StudentFilterMode.atRiskOnly;
                                      },
                                    ),
                                  );
                                },
                              ),
                            ],
                          )
                          .animate()
                          .fade(delay: 250.ms)
                          .slideY(begin: 0.2, curve: Curves.easeOut),
                    ],
                  ),
                ),
              ),

              // 4. Student List with Stats
              Builder(
                builder: (context) {
                  final filterMode = ref.watch(studentFilterProvider);

                  // First, sort students
                  final sortedStudents = List.of(students)
                    ..sort((a, b) {
                      int result;
                      if (sortState.field == StudentSortField.name) {
                        result = a.name.toLowerCase().compareTo(
                          b.name.toLowerCase(),
                        );
                      } else {
                        final pctA = statsMap[a.id]?.presencePercentage ?? 0.0;
                        final pctB = statsMap[b.id]?.presencePercentage ?? 0.0;
                        result = pctA.compareTo(pctB);
                        // If same percentage, sort by name
                        if (result == 0) {
                          result = a.name.toLowerCase().compareTo(
                            b.name.toLowerCase(),
                          );
                        }
                      }
                      return sortState.direction == SortDirection.asc
                          ? result
                          : -result;
                    });

                  // Then filter if needed
                  final displayedStudents =
                      filterMode == StudentFilterMode.atRiskOnly
                      ? sortedStudents.where((s) {
                          final stats = statsMap[s.id];
                          if (stats == null) return false;
                          return stats.consecutiveAbsences >= atRiskThreshold;
                        }).toList()
                      : sortedStudents;

                  if (displayedStudents.isEmpty &&
                      filterMode == StudentFilterMode.atRiskOnly) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 48,
                                color: Colors.green,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.noAtRiskStudents,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  // Show empty state when no students at all
                  if (students.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: isDark
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.noStudentsYet,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.tapAddStudentsAbove,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isDark
                                      ? Colors.grey.shade500
                                      : Colors.grey.shade500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final student = displayedStudents[index];
                      final stats = statsMap[student.id];

                      return _buildStudentCard(
                        context,
                        student,
                        stats,
                        isDark,
                        index,
                        atRiskThreshold,
                      );
                    }, childCount: displayedStudents.length),
                  );
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Text(
            AppLocalizations.of(context)!.errorGeneric(err.toString()),
          ),
        ),
      ),
      // No bottom nav bar needed if actions are inline
    );
  }

  Widget _buildSessionsSection(
    BuildContext context,
    List<AttendanceSession> sessions,
    WidgetRef ref,
    bool isDark,
    AppLocalizations l10n,
    String? classId,
  ) {
    // Sort sessions by date descending
    final sortedSessions = List.of(sessions)
      ..sort((a, b) => b.date.compareTo(a.date));

    // Take top 3
    final recentSessions = sortedSessions.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    l10n.attendance,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  // Header Button: Now "View All" (Swapped)
                  Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            // Navigate to Attendance List
                            context.push('/attendance');
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.goldPrimary.withValues(alpha: 0.1)
                                  : AppColors.goldPrimary.withValues(
                                      alpha: 0.1,
                                    ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.goldPrimary.withValues(
                                        alpha: 0.2,
                                      )
                                    : AppColors.goldPrimary.withValues(
                                        alpha: 0.3,
                                      ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  l10n.viewAll,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isDark
                                        ? AppColors.goldPrimary
                                        : AppColors.goldDark,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 16,
                                  color: isDark
                                      ? AppColors.goldPrimary
                                      : AppColors.goldDark,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .animate()
                      .fade(delay: 200.ms)
                      .slideY(begin: 0.2, curve: Curves.easeOut),
                ],
              )
              .animate()
              .fade(delay: 150.ms)
              .slideY(begin: 0.2, curve: Curves.easeOut),

          const SizedBox(height: 12),

          // Recent Sessions List
          if (sessions.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "No sessions yet.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                ),
              ),
            )
          else
            Column(
              children: recentSessions.asMap().entries.map((entry) {
                final index = entry.key;
                final session = entry.value;
                return AttendanceSessionCard(session: session, isDark: isDark)
                    .animate()
                    .fade(duration: 400.ms, delay: (100 + index * 50).ms)
                    .slideX(begin: 0.1, end: 0, curve: Curves.easeOut);
              }).toList(),
            ),

          // Footer Button: Now "New Attendance" (Swapped)
          Container(
            margin: const EdgeInsets.only(top: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (classId != null) {
                    context.push('/attendance/new');
                  }
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDark
                          ? AppColors.goldPrimary.withValues(alpha: 0.3)
                          : AppColors.goldPrimary.withValues(alpha: 0.5),
                    ),
                    borderRadius: BorderRadius.circular(14),
                    color: isDark
                        ? AppColors.goldPrimary.withValues(alpha: 0.1)
                        : AppColors.goldPrimary.withValues(alpha: 0.05),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add,
                        size: 18,
                        color: isDark
                            ? AppColors.goldPrimary
                            : AppColors.goldDark,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.newAttendance,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.goldPrimary
                              : AppColors.goldDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ).animate().fade(delay: 300.ms).slideY(begin: 0.1, end: 0),
        ],
      ),
    );
  }

  String _formatPhone(String phone) {
    // Remove any non-digit characters
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');

    // Check if it's an 11-digit number (typical Egypt mobile) or 12 digit (20...)
    String rest = cleaned;
    if (cleaned.startsWith('20')) {
      rest = cleaned.substring(2);
    } else if (cleaned.length == 11 && cleaned.startsWith('0')) {
      rest = cleaned.substring(1);
    }

    // Now 'rest' should be 10 digits for EG (e.g. 100 710 9211)
    if (rest.length == 10) {
      return '+20 ${rest.substring(0, 3)} ${rest.substring(3, 6)} ${rest.substring(6)}';
    }

    return phone;
  }

  Widget _buildStudentCard(
    BuildContext context,
    Student student,
    StudentAttendanceStats? stats,
    bool isDark,
    int index,
    int threshold,
  ) {
    final presentPct = stats?.presencePercentage ?? 0.0;
    // Critical if consecutive absences exceed threshold
    final absentCount = stats?.absentCount ?? 0;
    final consecutiveAbsences = stats?.consecutiveAbsences ?? 0;
    final isCritical = consecutiveAbsences >= threshold;
    final l10n = AppLocalizations.of(context)!;

    // At Risk if consecutive absences exceed threshold
    final isAtRisk = stats != null && stats.totalRecords > 0 && isCritical;

    return PremiumCard(
      enableAnimation: _allowAnimation,
      // Optimize: Only stagger the first 12 items.
      // Items scrolling into view later should appear almost instantly (0.1s).
      delay: index < 12 ? (0.2 + (index * 0.05)) : 0.1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      onTap: () => context.push('/students/${student.id}'),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.goldPrimary,
                child: Text(
                  student.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isAtRisk)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.redLight : AppColors.redPrimary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? AppColors.surfaceDark
                            : AppColors.surfaceLight,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.priority_high,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                if (student.phone != null && student.phone!.isNotEmpty)
                  Text(
                    _formatPhone(student.phone!),
                    textDirection: ui.TextDirection.ltr,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  )
                else
                  Text(
                    l10n.noPhone,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),

          // Stats Column
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Percentage Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      (presentPct < 50
                              ? (isDark
                                    ? AppColors.redLight
                                    : AppColors.redPrimary)
                              : (presentPct < 75
                                    ? Colors.orange
                                    : Colors.green))
                          .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: presentPct < 50
                        ? (isDark ? AppColors.redLight : AppColors.redPrimary)
                        : (presentPct < 75 ? Colors.orange : Colors.green),
                    width: 0.5,
                  ),
                ),
                child: (stats == null)
                    ? Text(
                        l10n.notSet,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? Colors.grey.shade500
                              : Colors.grey.shade400,
                        ),
                      )
                    : Text(
                        "${presentPct.toStringAsFixed(0)}%",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: presentPct < 50
                              ? (isDark
                                    ? AppColors.redLight
                                    : AppColors.redPrimary)
                              : (presentPct < 75
                                    ? Colors.orange
                                    : Colors.green),
                        ),
                      ),
              ),
              const SizedBox(height: 2),
              const SizedBox(height: 4),
              RichText(
                textAlign: TextAlign.end,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'Outfit',
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  children: [
                    TextSpan(text: l10n.absencesTotal(absentCount)),
                    if (consecutiveAbsences > 0) ...[
                      const TextSpan(text: " • "),
                      TextSpan(
                        text: l10n.consecutive(consecutiveAbsences),
                        style: TextStyle(
                          color: isCritical
                              ? AppColors.redLight
                              : (isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600),
                          fontWeight: isCritical
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
          ),
        ],
      ),
    );
  }

  void _showAddStudentDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    String? fullPhoneNumber;
    final addressController = TextEditingController();
    DateTime? selectedBirthdate;
    String? nameError;
    String? serverError;
    bool markAbsentPast = true;

    // Logic to determine class ID based on user role
    final user = ref.read(authControllerProvider).asData?.value;
    String? selectedClassId = ref.read(selectedClassIdProvider);

    if (user?.role != 'ADMIN' && user?.classId != null) {
      // For servants, force use of their assigned class
      selectedClassId = user!.classId;
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.grey.withValues(alpha: 0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDark ? AppColors.goldPrimary : AppColors.goldPrimary,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.redPrimary),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.redPrimary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    l10n.addNewStudent,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.addStudentCaption,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  if (serverError != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.redLight.withValues(alpha: 0.1)
                            : AppColors.redPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: isDark
                                ? AppColors.redLight
                                : AppColors.redPrimary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              serverError!,
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.redLight
                                    : AppColors.redPrimary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Name Field
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    decoration: inputDecoration.copyWith(
                      labelText: l10n.studentName,
                      errorText: nameError,
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: isDark
                            ? AppColors.goldPrimary.withValues(alpha: 0.7)
                            : AppColors.goldPrimary.withValues(alpha: 0.7),
                      ),
                    ),
                    onChanged: (value) {
                      if (nameError != null) {
                        setSheetState(() => nameError = null);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Phone Field
                  Directionality(
                    textDirection: ui.TextDirection.ltr,
                    child: IntlPhoneField(
                      controller: phoneController,
                      initialCountryCode: 'EG',
                      textAlign: TextAlign.left,
                      decoration: inputDecoration.copyWith(
                        labelText: l10n.phoneNumberOptional,
                        counterText: '', // Hide length counter
                        alignLabelWithHint: true,
                      ),
                      disableLengthCheck: true,
                      languageCode: l10n.localeName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      dropdownTextStyle: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      pickerDialogStyle: PickerDialogStyle(
                        backgroundColor: isDark
                            ? const Color(0xFF1E1E1E)
                            : Colors.white,
                        countryCodeStyle: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        countryNameStyle: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        searchFieldInputDecoration: InputDecoration(
                          labelText: l10n.search,
                          labelStyle: TextStyle(
                            color: isDark ? Colors.grey : Colors.black54,
                          ),
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      onChanged: (phone) {
                        if (phone.countryISOCode == 'EG' &&
                            phone.number.startsWith('0')) {
                          fullPhoneNumber =
                              '${phone.countryCode}${phone.number.substring(1)}';
                        } else {
                          fullPhoneNumber = phone.completeNumber;
                        }
                      },
                      onCountryChanged: (country) {
                        // Optional: log or handle
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Address Field
                  TextField(
                    controller: addressController,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    decoration: inputDecoration.copyWith(
                      labelText: l10n.addressOptional,
                      prefixIcon: Icon(
                        Icons.location_on_outlined,
                        color: isDark
                            ? AppColors.goldPrimary.withValues(alpha: 0.7)
                            : AppColors.goldPrimary.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Birthday Picker
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedBirthdate ?? DateTime(2010),
                          firstDate: DateTime(1950),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: theme.copyWith(
                                colorScheme: isDark
                                    ? const ColorScheme.dark(
                                        primary: AppColors.goldPrimary,
                                        onPrimary: Colors.black,
                                        surface: Color(0xFF1E1E1E),
                                        onSurface: Colors.white,
                                      )
                                    : const ColorScheme.light(
                                        primary: AppColors.goldPrimary,
                                        onPrimary: Colors.white,
                                      ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setSheetState(() => selectedBirthdate = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.transparent),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.cake_outlined,
                              color: isDark
                                  ? AppColors.goldPrimary.withValues(alpha: 0.7)
                                  : AppColors.goldPrimary.withValues(
                                      alpha: 0.7,
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.dateOfBirth,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    selectedBirthdate != null
                                        ? '${selectedBirthdate!.day}/${selectedBirthdate!.month}/${selectedBirthdate!.year}'
                                        : l10n.notSet,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                      color: selectedBirthdate != null
                                          ? (isDark
                                                ? Colors.white
                                                : Colors.black87)
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Retroactive Absence Checkbox
                  CheckboxListTile(
                    value: markAbsentPast,
                    onChanged: (val) {
                      setSheetState(() => markAbsentPast = val ?? false);
                    },
                    title: Text(
                      l10n.markAbsentPast,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      l10n.markAbsentPastCaption,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                    activeColor: AppColors.goldPrimary,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            side: BorderSide(
                              color: isDark
                                  ? Colors.white24
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            l10n.cancel,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final name = nameController.text.trim();
                            if (name.isEmpty) {
                              setSheetState(
                                () => nameError = l10n.pleaseEnterName,
                              );
                              return;
                            }

                            if (selectedClassId == null) {
                              setSheetState(
                                () => serverError = "No class selected",
                              );
                              return;
                            }

                            try {
                              Navigator.pop(
                                context,
                              ); // Close dialog first? Or wait? User didn't specify. Standard is wait or close. Close for optimistic.

                              await ref
                                  .read(studentsControllerProvider)
                                  .addStudent(
                                    name: name,
                                    phone:
                                        fullPhoneNumber ??
                                        phoneController.text.trim(),
                                    classId: selectedClassId,
                                    address: addressController.text.trim(),
                                    birthdate: selectedBirthdate,
                                    markAbsentPast:
                                        markAbsentPast, // Pass the flag
                                  );

                              if (context.mounted) {
                                AppSnackBar.show(
                                  context,
                                  message: AppLocalizations.of(
                                    context,
                                  )!.successAddStudent,
                                  type: AppSnackBarType.success,
                                );
                              }
                            } catch (e) {
                              // If we popped, we can't show error in dialog.
                              // So maybe don't pop? But optimistically popping is better UX usually.
                              // Let's show snackbar error if pop happened.
                              if (context.mounted) {
                                AppSnackBar.show(
                                  context,
                                  message: AppLocalizations.of(
                                    context,
                                  )!.errorAddStudent(e.toString()),
                                  type: AppSnackBarType.error,
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.goldPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            l10n.addStudentAction,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
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
        ),
      ),
    );
  }

  Widget _buildSortChip({
    required BuildContext context,
    required String label,
    required bool isActive,
    required SortDirection direction,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? AppColors.goldPrimary : AppColors.goldPrimary)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? Colors.white
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 4),
              Icon(
                direction == SortDirection.asc
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 14,
                color: Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
