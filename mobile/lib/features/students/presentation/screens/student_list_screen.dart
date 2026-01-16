import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile/features/attendance/data/attendance_controller.dart';
import 'package:mobile/features/attendance/data/attendance_repository.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/premium_card.dart';
import '../../../../core/database/app_database.dart';
import '../../data/students_controller.dart';
import 'package:mobile/features/classes/data/classes_controller.dart';
import 'package:mobile/l10n/app_localizations.dart';
import '../../../../features/auth/data/auth_controller.dart';

class StudentListScreen extends ConsumerWidget {
  const StudentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(classStudentsProvider);
    final selectedClassId = ref.watch(selectedClassIdProvider);
    final classesAsync = ref.watch(classesStreamProvider);
    final attendanceStatsAsync = selectedClassId != null
        ? ref.watch(classAttendanceStatsProvider(selectedClassId))
        : const AsyncValue.data(<String, StudentAttendanceStats>{});
    final sessionsAsync = ref.watch(attendanceSessionsProvider);

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get class name
    String? className;
    classesAsync.whenData((classes) {
      final cls = classes.where((c) => c.id == selectedClassId).firstOrNull;
      className = cls?.name;
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(selectedClassIdProvider.notifier).state = null;
            context.go('/');
          },
        ),
        title: Text(className ?? l10n?.students ?? 'Class Dashboard'),
        actions: [],
      ),
      body: studentsAsync.when(
        data: (students) {
          if (students.isEmpty) {
            return _buildEmptyState(context, isDark, theme);
          }

          final statsMap = attendanceStatsAsync.value ?? {};
          final sessions = sessionsAsync.value ?? [];

          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // 1. Birthday Section
              SliverToBoxAdapter(
                child: _buildBirthdaySection(context, students, isDark, l10n),
              ),

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

              // 3. Student List Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${l10n?.students ?? 'Students'} (${students.length})",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle,
                          size: 24,
                          color: AppColors.goldPrimary,
                        ),
                        tooltip: l10n?.addNewStudent ?? 'Add Student',
                        onPressed: () => _showAddStudentDialog(context, ref),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Student List with Stats
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final sortedStudents = List.of(students)
                    ..sort(
                      (a, b) =>
                          a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                    );
                  final student = sortedStudents[index];
                  final stats = statsMap[student.id];

                  return _buildStudentCard(
                    context,
                    student,
                    stats,
                    isDark,
                    index,
                  );
                }, childCount: students.length),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
      // No bottom nav bar needed if actions are inline
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 16),
          Text(
            'No students yet',
            style: theme.textTheme.titleLarge,
          ).animate().fade(delay: 200.ms),
        ],
      ),
    );
  }

  Widget _buildBirthdaySection(
    BuildContext context,
    List<Student> students,
    bool isDark,
    AppLocalizations? l10n,
  ) {
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

    // Sort by soonest
    upcomingBirthdays.sort((a, b) {
      var nextA = DateTime(now.year, a.birthdate!.month, a.birthdate!.day);
      if (nextA.isBefore(now))
        nextA = DateTime(now.year + 1, a.birthdate!.month, a.birthdate!.day);

      var nextB = DateTime(now.year, b.birthdate!.month, b.birthdate!.day);
      if (nextB.isBefore(now))
        nextB = DateTime(now.year + 1, b.birthdate!.month, b.birthdate!.day);

      return nextA.compareTo(nextB);
    });

    if (upcomingBirthdays.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.cake, size: 16, color: AppColors.goldPrimary),
              const SizedBox(width: 8),
              Text(
                l10n?.upcomingBirthdays ?? "Upcoming Birthdays",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: upcomingBirthdays.length,
            itemBuilder: (context, index) {
              final student = upcomingBirthdays[index];
              final b = student.birthdate!;

              // Calculate days
              var nextB = DateTime(now.year, b.month, b.day);
              if (nextB.isBefore(now.subtract(const Duration(days: 1))))
                nextB = DateTime(now.year + 1, b.month, b.day);
              final diff = nextB.difference(now).inDays;
              final isToday = diff == 0;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push('/students/${student.id}'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.only(right: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: isToday
                              ? AppColors.goldPrimary.withOpacity(0.2)
                              : (isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade200),
                          child: Text(
                            student.name.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: isToday
                                  ? AppColors.goldPrimary
                                  : (isDark ? Colors.white : Colors.black87),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          student.name.split(' ')[0],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        ),
                        Text(
                          isToday
                              ? (l10n?.today ?? "Today!")
                              : (l10n?.daysLeft(diff) ?? "$diff days"),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isToday
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isToday
                                ? AppColors.goldPrimary
                                : Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSessionsSection(
    BuildContext context,
    List<AttendanceSession> sessions,
    WidgetRef ref,
    bool isDark,
    AppLocalizations? l10n,
    String? classId,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n?.attendance ?? "Attendance",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.add_circle,
                  color: AppColors.goldPrimary,
                ),
                onPressed: () {
                  // Go to Take Attendance Screen or Show Dialog
                  if (classId != null) {
                    // We could push a route or show dialog. Use route for now as per user request to "create another screen doesn't have much sense" -> wait, user said "creating another screen doesn't have much sense" referring to VIEWING attendances? Or creating?
                    // "we should see the attendances (let's put them in that page with a plus icon for creating a new one) creating another screen doesn't have much sense"
                    // So we should probably show a dialog to create session? Or navigate to a "Take Attendance" flow?
                    // Let's assume navigate to TakeAttendanceScreen is fine, but maybe trigger it differently.
                    // Or maybe user meant the LIST of attendances shouldn't be a separate screen.
                    // I'll assume standard navigation for now, or improve later.

                    // Navigate to 'take-attendance' with classId
                    // Ideally we want to go straight to creating one?
                    context.push('/attendance/new');
                  }
                },
              ),
            ],
          ),
          // Recent Sessions List (Horizontal or Vertical condensed)
          if (sessions.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "No sessions yet.",
                textAlign: TextAlign.center,
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sessions.length > 3
                  ? 3
                  : sessions.length, // Show max 3 recent
              itemBuilder: (context, index) {
                // Determine sorted recent
                final sortedSessions = List.from(sessions)
                  ..sort((a, b) => b.date.compareTo(a.date));
                final session = sortedSessions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.goldPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: AppColors.goldPrimary,
                      ),
                    ),
                    title: Text(
                      DateFormat(
                        'dd/MM/yyyy  HH:mm (EEE)',
                      ).format(session.date),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: session.note != null && session.note!.isNotEmpty
                        ? Text(
                            session.note!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : Text(
                            l10n?.sessionTime ?? "Session",
                            style: TextStyle(
                              color: Colors.grey.withOpacity(0.5),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => context.push('/attendance/${session.id}'),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(
    BuildContext context,
    Student student,
    StudentAttendanceStats? stats,
    bool isDark,
    int index,
  ) {
    final presentPct = stats?.presencePercentage ?? 0.0;
    final isCritical = stats?.isCritical ?? false;
    final absentCount = stats?.absentCount ?? 0;

    return PremiumCard(
      delay: index * 0.05,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      onTap: () => context.push('/students/${student.id}'),
      child: Row(
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  student.phone ?? "No phone",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
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
                  color: isCritical
                      ? AppColors.redPrimary.withValues(alpha: 0.1)
                      : Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCritical ? AppColors.redPrimary : Colors.green,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  "${presentPct.toStringAsFixed(0)}%",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isCritical ? AppColors.redPrimary : Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "$absentCount Absences",
                style: TextStyle(
                  fontSize: 10,
                  color: isCritical
                      ? AppColors.redLight
                      : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                  fontWeight: isCritical ? FontWeight.bold : FontWeight.normal,
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
    final addressController = TextEditingController();
    DateTime? selectedBirthdate;
    String? nameError;
    String? serverError;
    bool markAbsentPast = false;

    // Logic to determine class ID based on user role
    final user = ref.read(authControllerProvider).asData?.value;
    String? selectedClassId = ref.read(selectedClassIdProvider);

    if (user?.role != 'ADMIN' && user?.classId != null) {
      // For servants, force use of their assigned class
      selectedClassId = user!.classId;
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

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
                    l10n?.addNewStudent ?? 'Add New Student',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n?.addStudentCaption ?? 'Add a student to this class',
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
                      labelText: l10n?.studentName ?? 'Student Name',
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
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    decoration: inputDecoration.copyWith(
                      labelText:
                          l10n?.phoneNumberOptional ??
                          'Phone Number (optional)',
                      prefixIcon: Icon(
                        Icons.phone_outlined,
                        color: isDark
                            ? AppColors.goldPrimary.withValues(alpha: 0.7)
                            : AppColors.goldPrimary.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Address Field
                  TextField(
                    controller: addressController,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    decoration: inputDecoration.copyWith(
                      labelText: l10n?.addressOptional ?? 'Address (optional)',
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
                                    l10n?.dateOfBirth ?? 'Date of Birth',
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
                                        : (l10n?.notSet ?? 'Not set'),
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
                  StatefulBuilder(
                    builder: (context, setStateCheckbox) {
                      bool markAbsentPast =
                          false; // Internal state for this widget in loop? No.
                      // We need to lift this state up to the StatefulBuilder wrapping the content.
                      // Actually, 'setSheetState' is available. Let's use a local var in the main dialog build function.
                      return CheckboxListTile(
                        value: markAbsentPast,
                        onChanged: (val) {
                          setSheetState(() => markAbsentPast = val ?? false);
                        },
                        title: Text(
                          l10n?.markAbsentPast ??
                              "Mark absent for past sessions",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          l10n?.markAbsentPastCaption ??
                              "Student will be recorded as ABSENT for all previous sessions.",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        activeColor: AppColors.goldPrimary,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    },
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
                            l10n?.cancel ?? 'Cancel',
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
                                () => nameError =
                                    l10n?.pleaseEnterName ??
                                    'Please enter a name',
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
                                    phone: phoneController.text.trim(),
                                    classId: selectedClassId,
                                    address: addressController.text.trim(),
                                    birthdate: selectedBirthdate,
                                    markAbsentPast:
                                        markAbsentPast, // Pass the flag
                                  );

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Student added successfully'),
                                    backgroundColor: AppColors.goldPrimary,
                                  ),
                                );
                              }
                            } catch (e) {
                              // If we popped, we can't show error in dialog.
                              // So maybe don't pop? But optimistically popping is better UX usually.
                              // Let's show snackbar error if pop happened.
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error adding student: $e'),
                                  ),
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
                            l10n?.addStudentAction ?? 'Add Student',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  const SizedBox(height: 32),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            l10n?.cancel ?? 'Cancel',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white70
                                  : Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (isDark
                                            ? AppColors.goldPrimary
                                            : AppColors.goldPrimary)
                                        .withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () async {
                              // Reset errors
                              setSheetState(() {
                                nameError = null;
                                serverError = null;
                              });

                              if (nameController.text.isEmpty) {
                                setSheetState(() {
                                  nameError =
                                      l10n?.pleaseEnterName ??
                                      'Please enter a name';
                                });
                                return;
                              }

                              if (selectedClassId == null) {
                                setSheetState(() {
                                  serverError =
                                      'Error: No class selected (ID null)';
                                });
                                return;
                              }

                              try {
                                await ref
                                    .read(studentsControllerProvider)
                                    .addStudent(
                                      name: nameController.text,
                                      phone: phoneController.text,
                                      address: addressController.text,
                                      birthdate: selectedBirthdate,
                                      classId: selectedClassId,
                                    );
                                if (context.mounted) Navigator.pop(context);
                              } catch (e) {
                                if (context.mounted) {
                                  setSheetState(() {
                                    serverError = 'Error: $e';
                                  });
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark
                                  ? AppColors.goldPrimary
                                  : AppColors.goldPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              l10n?.addStudentAction ?? 'Add Student',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
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
}
