import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/premium_card.dart';
import '../../../../core/database/app_database.dart';
import 'package:mobile/l10n/app_localizations.dart';
import '../../data/students_controller.dart';
import '../../data/notes_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart' as intl;
import '../../../attendance/data/attendance_controller.dart';
import '../../../attendance/data/attendance_repository.dart';

class StudentDetailScreen extends ConsumerWidget {
  final String studentId;

  const StudentDetailScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentProvider(studentId));
    final historyAsync = ref.watch(studentAttendanceHistoryProvider(studentId));
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.studentDetails ?? 'Student Details'),
        centerTitle: true,
      ),
      body: studentAsync.when(
        data: (student) {
          if (student == null) {
            return Center(
              child: Text(l10n?.studentNotFound ?? 'Student not found'),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar Section
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.goldPrimary, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.goldPrimary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: AppColors.goldPrimary,
                    child: Text(
                      student.name.substring(0, 1).toUpperCase(),
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  student.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fade().slideY(begin: 0.1, end: 0, delay: 100.ms),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    if (student.phone != null && student.phone!.isNotEmpty) {
                      final Uri launchUri = Uri(
                        scheme: 'tel',
                        path: student.phone!,
                      );
                      if (await canLaunchUrl(launchUri)) {
                        await launchUrl(launchUri);
                      }
                    }
                  },
                  onLongPress: () {
                    if (student.phone != null && student.phone!.isNotEmpty) {
                      Clipboard.setData(ClipboardData(text: student.phone!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Phone number copied')),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.goldPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.phone,
                          size: 18,
                          color: AppColors.goldDark,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          student.phone?.isNotEmpty == true
                              ? _formatPhone(student.phone!)
                              : (l10n?.noPhone ?? 'No Phone'),
                          textDirection: TextDirection.ltr,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.goldDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fade().slideY(begin: 0.1, end: 0, delay: 200.ms),

                const SizedBox(height: 16),

                // Info Cards (Stacked)
                _buildBirthdayCard(
                  context,
                  student,
                  l10n,
                  isDark,
                ).animate().fade().slideY(begin: 0.2, end: 0, delay: 300.ms),

                const SizedBox(height: 12),

                _buildAddressCard(
                  context,
                  student,
                  l10n,
                  isDark,
                ).animate().fade().slideY(begin: 0.2, end: 0, delay: 350.ms),

                const SizedBox(height: 24),

                // Attendance History Logic
                if (historyAsync.valueOrNull != null &&
                    historyAsync.valueOrNull!.isNotEmpty)
                  _buildAttendanceHistory(
                    context,
                    historyAsync.value!,
                    isDark,
                    l10n,
                  ).animate().fade().slideY(begin: 0.3, end: 0, delay: 400.ms),

                const SizedBox(height: 24),

                // Visitation Notes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionHeader(
                      context,
                      l10n?.visitationNotes ?? "Visitation Notes",
                      isDark,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle,
                        color: AppColors.goldPrimary,
                      ),
                      onPressed: () => _showAddNoteDialog(context, ref),
                    ).animate().scale(delay: 400.ms),
                  ],
                ),
                const SizedBox(height: 8),
                Consumer(
                  builder: (context, ref, child) {
                    final notesAsync = ref.watch(
                      studentNotesProvider(studentId),
                    );
                    return notesAsync.when(
                      data: (notes) {
                        if (notes.isEmpty) {
                          return PremiumCard(
                            delay: 0.4,
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  l10n?.noNotes ?? 'No visitation notes yet.',
                                ),
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: notes.asMap().entries.map((entry) {
                            final index = entry.key;
                            final note = entry.value;
                            return PremiumCard(
                              delay: 0.4 + (index * 0.1),
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.goldPrimary
                                      .withOpacity(0.1),
                                  child: const Icon(
                                    Icons.note,
                                    color: AppColors.goldDark,
                                    size: 18,
                                  ),
                                ),
                                title: Text(
                                  note.content,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  note.createdAt.toString().split(' ')[0],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, s) => Text('Error: $e'),
                    );
                  },
                ),

                const SizedBox(height: 48),

                // Edit/Delete Buttons
                // Edit/Delete Buttons (Swapped & Styled)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _showEditDialog(context, ref, studentAsync.value!),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.goldPrimary,
                          side: const BorderSide(color: AppColors.goldPrimary),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(l10n?.edit ?? 'Edit'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showDeleteDialog(context, ref),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.redPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: Text(l10n?.delete ?? 'Delete'),
                      ),
                    ),
                  ],
                ).animate().fade().slideY(begin: 0.4, end: 0, delay: 500.ms),

                // Add bottom padding for better scroll
                const SizedBox(height: 100),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, bool isDark) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      ),
    );
  }

  Widget _buildBirthdayCard(
    BuildContext context,
    Student student,
    AppLocalizations? l10n,
    bool isDark,
  ) {
    if (student.birthdate == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final birthdate = student.birthdate!;
    int age = (now.year - birthdate.year).toInt();
    if (now.month < birthdate.month ||
        (now.month == birthdate.month && now.day < birthdate.day)) {
      age--;
    }

    // Localization for Age
    final ageText = l10n?.yearsOld(age) ?? "$age years old";

    // Next Birthday Calculation
    DateTime nextBirthday = DateTime(now.year, birthdate.month, birthdate.day);
    if (nextBirthday.isBefore(now.subtract(const Duration(days: 1)))) {
      nextBirthday = DateTime(now.year + 1, birthdate.month, birthdate.day);
    }

    final difference = nextBirthday.difference(now);
    final daysUntil = difference.inDays;
    final months = daysUntil ~/ 30;
    final days = daysUntil % 30;

    String nextBirthdayText;
    bool isToday = daysUntil == 0;

    if (isToday) {
      nextBirthdayText = l10n?.todayIsBirthday ?? "Today is their birthday! 🎉";
    } else {
      nextBirthdayText =
          l10n?.birthdayCountdown(months, days) ??
          "In $months months, $days days";
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.goldPrimary.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.4),
                ]
              : [AppColors.goldPrimary.withValues(alpha: 0.1), Colors.white],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.goldPrimary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldPrimary.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative Circle
          Positioned(
            top: -20,
            right: -20,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.goldPrimary.withValues(alpha: 0.05),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    // Icon Container
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.goldPrimary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.cake,
                        color: AppColors.goldPrimary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Date & Age
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.birthdate ?? "Birthdate",
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            student.birthdate?.toString().split(" ")[0] ?? "",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.black54
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              ageText,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Countdown Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n?.nextBirthday ?? "Next Birthday",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        nextBirthdayText,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isToday
                              ? AppColors.goldPrimary
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(
    BuildContext context,
    Student student,
    AppLocalizations? l10n,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.location_on_outlined,
            color: isDark ? AppColors.goldPrimary : AppColors.goldDark,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.address ?? "Address",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  student.address ?? (l10n?.noAddress ?? "No address provided"),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceHistory(
    BuildContext context,
    List<AttendanceRecordWithSession> history,
    bool isDark,
    AppLocalizations? l10n,
  ) {
    // Group by Month
    final grouped = <String, List<AttendanceRecordWithSession>>{};
    for (var item in history) {
      final key = intl.DateFormat('MMMM yyyy').format(item.session.date);
      if (!grouped.containsKey(key)) grouped[key] = [];
      grouped[key]!.add(item);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          l10n?.attendanceHistory ?? "Attendance History",
          isDark,
        ),
        const SizedBox(height: 16),
        ...grouped.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 4),
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.goldPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
              ...entry.value.map((item) {
                final status = item.record.status; // PRESENT, ABSENT, EXCUSED
                final isPresent = status == 'PRESENT';
                final isAbsent = status == 'ABSENT';

                Color statusColor;
                IconData statusIcon;
                String statusText;

                if (isPresent) {
                  statusColor = Colors.green;
                  statusIcon = Icons.check_circle;
                  statusText = l10n?.present ?? "Present";
                } else if (isAbsent) {
                  statusColor = AppColors.redPrimary;
                  statusIcon = Icons.cancel;
                  statusText = l10n?.absent ?? "Absent";
                } else {
                  statusColor = Colors.orange;
                  statusIcon = Icons.info;
                  statusText = l10n?.excused ?? "Excused";
                }

                return PremiumCard(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Date Box
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.black26
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                intl.DateFormat('dd').format(item.session.date),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                intl.DateFormat(
                                  'EEE',
                                ).format(item.session.date).toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Time & Note
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                intl.DateFormat(
                                  'hh:mm a',
                                ).format(item.session.date),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              if (item.session.note != null &&
                                  item.session.note!.isNotEmpty)
                                Text(
                                  item.session.note!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),

                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 14, color: statusColor),
                              const SizedBox(width: 4),
                              Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        }),
      ],
    );
  }

  // --- Dialogs (Refactored to look cleaner) ---

  void _showAddNoteDialog(BuildContext context, WidgetRef ref) {
    final noteController = TextEditingController();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

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
                l10n?.addNote ?? 'Add Note',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n?.addNoteCaption ??
                    'Add a visitation note for this student',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: noteController,
                autofocus: true,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      l10n?.whatHappened ?? 'What happened during the visit?',
                  prefixIcon: Icon(
                    Icons.note_outlined,
                    color: isDark ? AppColors.goldPrimary : AppColors.goldDark,
                  ),
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
                      child: Text(l10n?.cancel ?? 'Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (noteController.text.isNotEmpty) {
                          await ref
                              .read(notesControllerProvider.notifier)
                              .addNote(studentId, noteController.text);
                          if (context.mounted) Navigator.pop(context);
                        }
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
                      child: Text(
                        l10n?.addNote ?? 'Add Note',
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

  void _showEditDialog(BuildContext context, WidgetRef ref, Student student) {
    final nameController = TextEditingController(text: student.name);
    final phoneController = TextEditingController(text: student.phone ?? '');
    final addressController = TextEditingController(
      text: student.address ?? '',
    );
    DateTime? selectedBirthdate = student.birthdate;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: isDark
          ? Colors.white.withOpacity(0.05)
          : Colors.grey.withOpacity(0.05),
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
                    l10n?.editStudent ?? 'Edit Student',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Name
                  TextField(
                    controller: nameController,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    decoration: inputDecoration.copyWith(
                      labelText: l10n?.name ?? 'Name',
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: isDark
                            ? AppColors.goldPrimary.withOpacity(0.7)
                            : AppColors.goldDark.withOpacity(0.7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    decoration: inputDecoration.copyWith(
                      labelText: l10n?.phone ?? 'Phone',
                      prefixIcon: Icon(
                        Icons.phone_outlined,
                        color: isDark
                            ? AppColors.goldPrimary.withOpacity(0.7)
                            : AppColors.goldDark.withOpacity(0.7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Address
                  TextField(
                    controller: addressController,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    decoration: inputDecoration.copyWith(
                      labelText: l10n?.address ?? 'Address',
                      prefixIcon: Icon(
                        Icons.location_on_outlined,
                        color: isDark
                            ? AppColors.goldPrimary.withOpacity(0.7)
                            : AppColors.goldDark.withOpacity(0.7),
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
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.transparent),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.cake_outlined,
                              color: isDark
                                  ? AppColors.goldPrimary.withOpacity(0.7)
                                  : AppColors.goldDark.withOpacity(0.7),
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
                                        .withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () async {
                              final updatedStudent = student.copyWith(
                                name: nameController.text,
                                phone: Value(
                                  phoneController.text.isNotEmpty
                                      ? phoneController.text
                                      : null,
                                ),
                                address: Value(
                                  addressController.text.isNotEmpty
                                      ? addressController.text
                                      : null,
                                ),
                                birthdate: Value(selectedBirthdate),
                              );
                              await ref
                                  .read(studentsControllerProvider)
                                  .updateStudent(updatedStudent);
                              if (context.mounted) Navigator.pop(context);
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
                              l10n?.save ?? 'Save Changes',
                              style: TextStyle(
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

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

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
                child: Icon(
                  Icons.person_remove,
                  color: isDark ? AppColors.redLight : AppColors.redPrimary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n?.deleteStudentQuestion ?? 'Delete Student?',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n?.deleteStudentWarning ??
                    'This student and all their records will be permanently removed. This action cannot be undone.',
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
                      child: Text(l10n?.cancel ?? 'Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await ref
                            .read(studentsControllerProvider)
                            .deleteStudent(studentId);
                        if (context.mounted) {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? AppColors.redLight
                            : AppColors.redPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n?.delete ?? 'Delete',
                        style: const TextStyle(fontWeight: FontWeight.bold),
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

  String _formatPhone(String phone) {
    // Remove any non-digit characters
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');

    // Check if it's an 11-digit number
    if (cleaned.length == 11) {
      // 4 digits + space + 3 digits + space + 4 digits
      return '${cleaned.substring(0, 4)} ${cleaned.substring(4, 7)} ${cleaned.substring(7, 11)}';
    }

    return phone;
  }
}
