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
import '../../../settings/data/settings_controller.dart';
import '../../../../l10n/app_localizations.dart';

class TakeAttendanceScreen extends ConsumerStatefulWidget {
  const TakeAttendanceScreen({super.key});

  @override
  ConsumerState<TakeAttendanceScreen> createState() =>
      _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends ConsumerState<TakeAttendanceScreen> {
  final Map<String, bool> _attendance = {};
  late final TextEditingController _noteController;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  bool _noteError = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with default note
    final defaultNote = ref.read(defaultNoteProvider);
    _noteController = TextEditingController(text: defaultNote);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(classStudentsProvider);
    final selectedClassId = ref.watch(selectedClassIdProvider);
    final classesAsync = ref.watch(classesStreamProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

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
        title: Text(
          className ?? (l10n?.newAttendance ?? 'New Attendance'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
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
                    l10n?.noStudentsInClass ?? 'No students in this class',
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
                            AppColors.goldPrimary.withValues(alpha: 0.15),
                            AppColors.goldDark.withValues(alpha: 0.1),
                          ]
                        : [
                            AppColors.goldPrimary.withValues(alpha: 0.08),
                            AppColors.goldLight.withValues(alpha: 0.05),
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
                                    ? Colors
                                          .white // Better contrast in dark mode
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
                            l10n?.attendancePresentCount(
                                  presentCount,
                                  totalStudents,
                                ) ??
                                '$presentCount of $totalStudents present',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : null,
                            ),
                          ),
                          Text(
                            l10n?.tapToMark ??
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
                            ? (l10n?.clearAll ?? 'Clear')
                            : (l10n?.markAll ?? 'All'),
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

              // Date & Time Picker (Button/Field Style)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: IgnorePointer(
                    child: InputDecorator(
                      decoration: InputDecoration(
                        // labelText removed as per request
                        prefixIcon: Icon(
                          Icons.calendar_month,
                          color: isDark
                              ? AppColors.goldPrimary
                              : AppColors.goldDark,
                        ),
                        suffixIcon: Icon(
                          Icons.edit,
                          size: 18,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                      ),
                      child: Builder(
                        builder: (context) {
                          final localeCode = Localizations.localeOf(
                            context,
                          ).languageCode;
                          String dateStr;
                          final year = DateFormat(
                            'yyyy',
                            'en',
                          ).format(_selectedDate);
                          final tempTime = DateTime(
                            2000,
                            1,
                            1,
                            _selectedDate.hour,
                            _selectedDate.minute,
                          );
                          if (localeCode == 'ar') {
                            final dayNum = DateFormat(
                              'd',
                              'en',
                            ).format(_selectedDate);
                            final dayName = DateFormat(
                              'EEE',
                              'ar',
                            ).format(_selectedDate);
                            final monthName = DateFormat(
                              'MMM',
                              'ar',
                            ).format(_selectedDate);
                            final timeNum = DateFormat(
                              'h:mm',
                              'en',
                            ).format(tempTime);
                            final period = _selectedDate.hour >= 12 ? 'م' : 'ص';
                            final formattedTime = '$timeNum $period';

                            dateStr =
                                '$dayName, $dayNum $monthName $year • $formattedTime';
                          } else {
                            final formattedTime = DateFormat(
                              'h:mm a',
                              'en',
                            ).format(tempTime);
                            dateStr =
                                DateFormat(
                                  'EEE, MMM d, yyyy',
                                  localeCode,
                                ).format(_selectedDate) +
                                ' • $formattedTime';
                          }
                          return Text(
                            dateStr,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              // Inline Note Field
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: TextField(
                  onChanged: (value) {
                    setState(() => _noteError = value.trim().isEmpty);
                  },
                  controller: _noteController,
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText:
                        (l10n?.sessionNoteHint ?? 'Add session note...') + ' *',
                    prefixIcon: Icon(
                      Icons.edit_note,
                      color: _noteError
                          ? Colors.redAccent
                          : (isDark
                                ? AppColors.goldPrimary
                                : AppColors.goldDark),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: _noteError
                          ? const BorderSide(
                              color: Colors.redAccent,
                              width: 1.5,
                            )
                          : BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: _noteError
                          ? const BorderSide(
                              color: Colors.redAccent,
                              width: 1.5,
                            )
                          : BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                  ),
                  style: theme.textTheme.bodyMedium,
                ),
              ).animate().fade(delay: 100.ms),

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
      // Bottom Action Bar - Just Save Button
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
          child: SizedBox(
            width: double.infinity,
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
                  : const Icon(Icons.check, size: 20),
              label: Text(
                _isSaving
                    ? (l10n?.saving ?? 'Saving...')
                    : (l10n?.saveAttendance ?? 'Save Attendance'),
              ),
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
        ),
      ),
    );
  }

  void _saveAttendance() async {
    final selectedClassId = ref.read(selectedClassIdProvider);
    final l10n = AppLocalizations.of(context);

    if (selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No class selected')),
      ); // Should be impossible in flow, but kept safe.
      return;
    }

    final noteContent = _noteController.text.trim();
    if (noteContent.isEmpty) {
      setState(() => _noteError = true);
      return;
    }

    setState(() => _isSaving = true);

    // Ensure all students are included in the map (unselected = absent)
    final allStudents = ref.read(classStudentsProvider).valueOrNull ?? [];
    final completeAttendance = <String, bool>{};

    for (final student in allStudents) {
      completeAttendance[student.id] = _attendance[student.id] ?? false;
    }

    final controller = ref.read(attendanceControllerProvider.notifier);
    final session = await controller.createSessionWithAttendance(
      classId: selectedClassId,
      date: _selectedDate,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
      attendance: completeAttendance,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (session != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.attendanceSaved ?? 'Attendance saved!'),
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

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null && mounted) {
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
}
