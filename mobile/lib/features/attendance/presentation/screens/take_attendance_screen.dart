import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/premium_card.dart';
import '../../data/attendance_controller.dart';
import '../../../students/data/students_controller.dart';

class TakeAttendanceScreen extends ConsumerStatefulWidget {
  const TakeAttendanceScreen({super.key});

  @override
  ConsumerState<TakeAttendanceScreen> createState() =>
      _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends ConsumerState<TakeAttendanceScreen> {
  final Map<String, bool> _attendance = {};
  final TextEditingController _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(classStudentsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Calculate stats
    final totalStudents = studentsAsync.value?.length ?? 0;
    final presentCount = _attendance.values.where((v) => v).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Attendance'),
        actions: [
          IconButton(
            onPressed: _saveAttendance,
            icon: Icon(
              Icons.check,
              color: isDark ? AppColors.goldPrimary : AppColors.bluePrimary,
            ),
            tooltip: 'Save',
          ),
        ],
      ),
      body: studentsAsync.when(
        data: (students) {
          if (students.isEmpty) {
            return Center(
              child: Text(
                'No students in this class.',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            );
          }

          return Column(
            children: [
              // Date and Note Header
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white10
                        : Colors.grey.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    // Date Picker Row
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: isDark
                                ? AppColors.goldPrimary
                                : AppColors.bluePrimary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat.yMMMEd().format(_selectedDate),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.edit,
                            size: 16,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Note Field
                    TextField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        hintText: 'Add a note (optional)',
                        prefixIcon: Icon(
                          Icons.note_outlined,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fade().slideY(begin: -0.1, end: 0),

              // Stats Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total: $totalStudents",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    Text(
                      "Present: $presentCount",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.goldPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Student List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final isPresent = _attendance[student.id] ?? false;

                    return PremiumCard(
                      delay: index * 0.03,
                      margin: const EdgeInsets.only(bottom: 8),
                      color: isPresent
                          ? AppColors.goldPrimary.withOpacity(
                              isDark ? 0.15 : 0.05,
                            )
                          : null,
                      border: isPresent
                          ? Border.all(
                              color: AppColors.goldPrimary.withOpacity(0.5),
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _attendance[student.id] =
                              !(_attendance[student.id] ?? false);
                        });
                      },
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
                              student.name[0].toUpperCase(),
                              style: TextStyle(
                                color: isPresent
                                    ? Colors.white
                                    : (isDark ? Colors.white70 : Colors.grey),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              student.name,
                              style: TextStyle(
                                fontWeight: isPresent
                                    ? FontWeight.bold
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
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isPresent
                                  ? AppColors.goldPrimary
                                  : Colors.transparent,
                              border: Border.all(
                                color: isPresent
                                    ? AppColors.goldPrimary
                                    : (isDark
                                          ? Colors.grey.shade600
                                          : Colors.grey.shade400),
                                width: 2,
                              ),
                            ),
                            child: isPresent
                                ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : null,
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

  void _saveAttendance() async {
    final selectedClassId = ref.read(selectedClassIdProvider);
    if (selectedClassId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No class selected')));
      return;
    }

    final controller = ref.read(attendanceControllerProvider.notifier);
    final session = await controller.createSessionWithAttendance(
      classId: selectedClassId,
      date: _selectedDate,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
      attendance: _attendance,
    );

    if (mounted && session != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Attendance saved!'),
          backgroundColor: AppColors.goldDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      context.pop();
    }
  }
}
