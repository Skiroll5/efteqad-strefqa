import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/premium_card.dart';
import '../../data/attendance_controller.dart';
import '../../../students/data/students_controller.dart';
import '../../../classes/data/classes_controller.dart';

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
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(classStudentsProvider);
    final selectedClassId = ref.watch(selectedClassIdProvider);
    final classesAsync = ref.watch(classesStreamProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get class name
    String? className;
    classesAsync.whenData((classes) {
      className = classes
          .where((c) => c.id == selectedClassId)
          .firstOrNull
          ?.name;
    });

    // Calculate stats
    final totalStudents = studentsAsync.value?.length ?? 0;
    final presentCount = _attendance.values.where((v) => v).length;
    final percentage = totalStudents > 0 ? presentCount / totalStudents : 0.0;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEE, MMM d • HH:mm').format(_selectedDate),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              className ?? 'New Attendance',
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
          // Date & Time Picker
          IconButton(
            icon: Icon(
              Icons.edit_calendar,
              color: isDark ? AppColors.goldPrimary : AppColors.goldDark,
            ),
            tooltip: 'Change Date & Time',
            onPressed: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (pickedDate != null) {
                if (context.mounted) {
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_selectedDate),
                  );

                  if (pickedTime != null) {
                    setState(() {
                      _selectedDate = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        pickedTime.hour,
                        pickedTime.minute,
                      );
                    });
                  }
                }
              }
            },
          ),
        ],
      ),
      body: studentsAsync.when(
        data: (students) {
          if (students.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No students in this class',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Stats Bar
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            AppColors.goldPrimary.withOpacity(0.15),
                            AppColors.goldDark.withOpacity(0.1),
                          ]
                        : [
                            AppColors.goldPrimary.withOpacity(0.08),
                            AppColors.goldLight.withOpacity(0.05),
                          ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    // Progress Circle
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: percentage,
                            strokeWidth: 4,
                            backgroundColor: isDark
                                ? Colors.white12
                                : Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation(
                              isDark
                                  ? AppColors.goldPrimary
                                  : AppColors.goldPrimary,
                            ),
                          ),
                          Center(
                            child: Text(
                              '${(percentage * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.goldPrimary
                                    : AppColors.goldDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$presentCount of $totalStudents present',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Tap students to mark attendance',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Mark All Button
                    TextButton(
                      onPressed: () {
                        setState(() {
                          final allPresent = students.every(
                            (s) => _attendance[s.id] == true,
                          );
                          for (final s in students) {
                            _attendance[s.id] = !allPresent;
                          }
                        });
                      },
                      child: Text(
                        students.every((s) => _attendance[s.id] == true)
                            ? 'Clear'
                            : 'All',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.goldPrimary
                              : AppColors.goldDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fade().slideY(begin: -0.1, end: 0),

              // Student List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final isPresent = _attendance[student.id] ?? false;

                    return PremiumCard(
                      delay: index * 0.02,
                      margin: const EdgeInsets.only(bottom: 8),
                      color: isPresent
                          ? AppColors.goldPrimary.withOpacity(
                              isDark ? 0.12 : 0.06,
                            )
                          : null,
                      border: isPresent
                          ? Border.all(
                              color: AppColors.goldPrimary.withOpacity(0.4),
                            )
                          : null,
                      onTap: () =>
                          setState(() => _attendance[student.id] = !isPresent),
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
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 26,
                            height: 26,
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
                                    size: 16,
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
      // Bottom Action Bar
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Note Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showNoteSheet(context),
                  icon: Icon(
                    _noteController.text.isNotEmpty
                        ? Icons.note
                        : Icons.note_add_outlined,
                    size: 20,
                  ),
                  label: Text(
                    _noteController.text.isNotEmpty ? 'Edit Note' : 'Add Note',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Save Button
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveAttendance,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save, size: 20),
                  label: Text(_isSaving ? 'Saving...' : 'Save Attendance'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? AppColors.goldPrimary
                        : AppColors.goldPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNoteSheet(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
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
                'Session Note',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                autofocus: true,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add any notes about this session...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.goldPrimary
                          : AppColors.goldPrimary,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {});
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? AppColors.goldPrimary
                        : AppColors.goldPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
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

    setState(() => _isSaving = true);

    final controller = ref.read(attendanceControllerProvider.notifier);
    final session = await controller.createSessionWithAttendance(
      classId: selectedClassId,
      date: _selectedDate,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
      attendance: _attendance,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (session != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Attendance saved!'),
            backgroundColor: AppColors.goldPrimary,
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
}
