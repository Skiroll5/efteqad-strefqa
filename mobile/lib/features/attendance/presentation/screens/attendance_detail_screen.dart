import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/components/premium_card.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:mobile/features/attendance/data/attendance_controller.dart';

class AttendanceDetailScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final String? highlightStudentId;

  const AttendanceDetailScreen({
    super.key,
    required this.sessionId,
    this.highlightStudentId,
  });

  @override
  ConsumerState<AttendanceDetailScreen> createState() =>
      _AttendanceDetailScreenState();
}

class _AttendanceDetailScreenState
    extends ConsumerState<AttendanceDetailScreen> {
  bool _isEditMode = false;

  // Track record IDs of newly added arrivals (to delete on cancel)
  Set<String> _addedRecordIds = {};
  // Track status changes for existing records (recordId -> newStatus)
  Map<String, String> _pendingStatusChanges = {};

  AttendanceSortOption _sortBy = AttendanceSortOption.name;
  final GlobalKey _highlightKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.highlightStudentId != null) {
      // Scroll to item
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Delay slightly to ensure layout/animations settle
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_highlightKey.currentContext != null) {
            Scrollable.ensureVisible(
              _highlightKey.currentContext!,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              alignment: 0.5,
            );
          }
        });
      });
    }
  }

  void _enterEditMode() {
    setState(() {
      _isEditMode = true;
      _addedRecordIds = {};
      _pendingStatusChanges = {};
    });
  }

  Future<void> _cancelEdit() async {
    // Delete all newly added records
    final controller = ref.read(attendanceControllerProvider.notifier);
    for (final recordId in _addedRecordIds) {
      await controller.deleteRecord(recordId);
    }

    setState(() {
      _isEditMode = false;
      _addedRecordIds = {};
      _pendingStatusChanges = {};
    });
    ref.invalidate(sessionRecordsWithStudentsProvider(widget.sessionId));
  }

  Future<void> _saveChanges() async {
    final controller = ref.read(attendanceControllerProvider.notifier);

    // Apply all pending status changes
    for (final entry in _pendingStatusChanges.entries) {
      await controller.updateRecordStatus(entry.key, entry.value);
    }

    setState(() {
      _isEditMode = false;
      _addedRecordIds = {};
      _pendingStatusChanges = {};
    });
    // Invalidate to fetch fresh data
    ref.invalidate(sessionRecordsWithStudentsProvider(widget.sessionId));
  }

  // Add a new arrival and track the record ID for potential cancellation
  Future<void> _addNewArrival(String studentId) async {
    final controller = ref.read(attendanceControllerProvider.notifier);
    await controller.createRecord(
      sessionId: widget.sessionId,
      studentId: studentId,
      status: 'PRESENT',
    );

    // Get the newly created record ID
    ref.invalidate(sessionRecordsWithStudentsProvider(widget.sessionId));

    // Wait a bit for the provider to refresh, then find the record ID
    await Future.delayed(const Duration(milliseconds: 100));
    final records = ref
        .read(sessionRecordsWithStudentsProvider(widget.sessionId))
        .value;
    final newRecord = records?.firstWhere(
      (r) => r.studentId == studentId && r.record != null,
      orElse: () => throw Exception('Record not found'),
    );

    if (newRecord?.record != null) {
      setState(() {
        _addedRecordIds.add(newRecord!.record!.id);
      });
    }
  }

  Future<void> _showEditSessionDialog(
    BuildContext context,
    WidgetRef ref,
    AttendanceSession session,
  ) async {
    final noteController = TextEditingController(text: session.note);
    // Remove (optional) from default if it was saved that way? No, assume clean string.

    DateTime selectedDate = session.date;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(session.date);

    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            l10n.editSessionNote,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Date & Time Pickers Row
              Row(
                children: [
                  // Date Picker
                  Expanded(
                    flex: 3,
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => selectedDate = date);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? Colors.white12
                                : Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_month,
                              size: 18,
                              color: isDark
                                  ? AppColors.goldPrimary
                                  : AppColors.goldDark,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Builder(
                                builder: (context) {
                                  final localeCode = Localizations.localeOf(
                                    context,
                                  ).languageCode;
                                  final year = DateFormat(
                                    'yyyy',
                                    'en',
                                  ).format(selectedDate);
                                  if (localeCode == 'ar') {
                                    final dayNum = DateFormat(
                                      'd',
                                      'en',
                                    ).format(selectedDate);
                                    final dayName = DateFormat(
                                      'EEE',
                                      'ar',
                                    ).format(selectedDate);
                                    final monthName = DateFormat(
                                      'MMM',
                                      'ar',
                                    ).format(selectedDate);
                                    return Text(
                                      '$dayName, $dayNum $monthName $year',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  } else {
                                    return Text(
                                      DateFormat(
                                        'EEE, MMM d, yyyy',
                                        localeCode,
                                      ).format(selectedDate),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Time Picker
                  Expanded(
                    flex: 2,
                    child: InkWell(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (time != null) {
                          setState(() => selectedTime = time);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? Colors.white12
                                : Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 18,
                              color: isDark
                                  ? AppColors.goldPrimary
                                  : AppColors.goldDark,
                            ),
                            const SizedBox(width: 8),
                            Builder(
                              builder: (context) {
                                final localeCode = Localizations.localeOf(
                                  context,
                                ).languageCode;
                                final tempTime = DateTime(
                                  2000,
                                  1,
                                  1,
                                  selectedTime.hour,
                                  selectedTime.minute,
                                );
                                String timeStr;
                                if (localeCode == 'ar') {
                                  final timeNum = DateFormat(
                                    'h:mm',
                                    'en',
                                  ).format(tempTime);
                                  final period = selectedTime.hour >= 12
                                      ? 'م'
                                      : 'ص';
                                  timeStr = '$timeNum $period';
                                } else {
                                  timeStr = DateFormat(
                                    'h:mm a',
                                    'en',
                                  ).format(tempTime);
                                }
                                return Text(
                                  timeStr,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Note Field
              TextField(
                controller: noteController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: l10n.sessionNote,
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () async {
                final newDate = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                final newNote = noteController.text.trim();
                final updatedSession = session.copyWith(
                  date: newDate,
                  note: Value(newNote.isNotEmpty ? newNote : null),
                );

                await ref
                    .read(attendanceControllerProvider.notifier)
                    .updateSession(updatedSession);

                if (context.mounted) Navigator.pop(context);
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(
      sessionRecordsWithStudentsProvider(widget.sessionId),
    );
    final sessionsAsync = ref.watch(attendanceSessionsProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get session info for date display
    // Get session info for date display and title
    String titleText = l10n.attendanceDetails;
    String? subtitleText; // If empty, no subtitle

    sessionsAsync.whenData((sessions) {
      final session = sessions
          .where((s) => s.id == widget.sessionId)
          .firstOrNull;
      if (session != null) {
        String dateText;
        // Custom date formatting logic to match TakeAttendanceScreen
        final localeCode = l10n.localeName;
        final year = DateFormat('yyyy', 'en').format(session.date);
        var time = DateFormat(
          'hh:mm a',
          'en',
        ).format(session.date); // 12h format

        if (localeCode == 'ar') {
          final dayNum = DateFormat('d', 'en').format(session.date);
          final dayName = DateFormat('EEE', 'ar').format(session.date);
          final monthName = DateFormat('MMM', 'ar').format(session.date);

          // Manual AM/PM translation
          time = time.replaceAll('AM', 'ص').replaceAll('PM', 'م');

          dateText = '$dayName, $dayNum $monthName $year • $time';
        } else {
          dateText = DateFormat(
            'EEE, d MMM yyyy • hh:mm a',
            'en',
          ).format(session.date);
        }

        // Header Logic based on Note
        if (session.note != null && session.note!.isNotEmpty) {
          titleText = session.note!;
          subtitleText = dateText;
        } else {
          titleText = dateText;
          subtitleText = l10n.attendanceDetails;
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                  titleText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
                .animate()
                .fade(duration: 300.ms)
                .slideY(
                  begin: 0.1,
                  curve: Curves.easeOut,
                ), // Zero initial delay
            if (subtitleText != null)
              Text(
                    subtitleText!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  )
                  .animate()
                  .fade(duration: 300.ms)
                  .slideY(begin: 0.1, curve: Curves.easeOut),
          ],
        ),
        // No delete button in AppBar anymore
        actions: [
          sessionsAsync.when(
            data: (sessions) {
              final session = sessions
                  .where((s) => s.id == widget.sessionId)
                  .firstOrNull;
              if (session == null) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditSessionDialog(context, ref, session),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: recordsAsync.when(
        data: (records) {
          // Count present students considering pending changes
          int presentCount = 0;
          for (final record in records) {
            // New Arrivals (no record) are NOT included in stats
            if (record.record == null) continue;

            final currentStatus =
                _pendingStatusChanges[record.record!.id] ??
                record.record!.status;
            if (currentStatus == 'PRESENT') {
              presentCount++;
            }
          }

          // Total only includes students WITH a record in this session
          final total = records.where((r) => r.record != null).length;
          final percentage = total > 0 ? (presentCount / total) : 0.0;

          return Column(
            children: [
              // 1. Pinned Header: Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: _buildActionButtons(context, isDark, l10n),
              ),

              // 2. Scrollable Content
              Expanded(
                child: records.isEmpty
                    ? Center(
                        child: Text(
                          l10n.noAttendanceRecords,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      )
                    : Builder(
                        builder: (context) {
                          // Separate students with records from those without
                          final existingStudents = records
                              .where((r) => r.record != null)
                              .toList();
                          final newStudents = records
                              .where((r) => r.record == null)
                              .toList();

                          // Sort Existing Students
                          existingStudents.sort((a, b) {
                            if (_sortBy == AttendanceSortOption.name) {
                              return a.studentName.compareTo(b.studentName);
                            } else {
                              final statusA =
                                  (_pendingStatusChanges[a.record!.id] ??
                                          a.record!.status) ==
                                      'PRESENT'
                                  ? 0
                                  : 1;
                              final statusB =
                                  (_pendingStatusChanges[b.record!.id] ??
                                          b.record!.status) ==
                                      'PRESENT'
                                  ? 0
                                  : 1;
                              if (statusA != statusB) {
                                return statusA.compareTo(statusB);
                              }
                              return a.studentName.compareTo(b.studentName);
                            }
                          });

                          return SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Stats Card
                                _buildStatsCard(
                                  context,
                                  theme,
                                  isDark,
                                  percentage,
                                  presentCount,
                                  total,
                                  l10n,
                                ),
                                const SizedBox(height: 24),

                                // Title Row
                                _buildTitleRow(
                                  context,
                                  theme,
                                  isDark,
                                  total,
                                  l10n,
                                ),
                                const SizedBox(height: 16),

                                // Existing Students Section
                                ...existingStudents.asMap().entries.map((
                                  entry,
                                ) {
                                  final index = entry.key;
                                  final item = entry.value;

                                  // Determine status checking pending changes
                                  final currentStatus =
                                      _pendingStatusChanges[item.record!.id] ??
                                      item.record!.status;
                                  final isPresent = currentStatus == 'PRESENT';
                                  final isHighlight =
                                      item.studentId ==
                                      widget.highlightStudentId;

                                  return Container(
                                    key:
                                        item.studentId ==
                                            widget.highlightStudentId
                                        ? _highlightKey
                                        : ValueKey(item.studentId),
                                    child:
                                        PremiumCard(
                                              // Staggered list animation
                                              // Staggered list animation - faster delays
                                              delay:
                                                  (index * 0.05).clamp(
                                                    0.0,
                                                    0.5,
                                                  ) +
                                                  0.1,
                                              margin: const EdgeInsets.only(
                                                bottom: 8,
                                              ),
                                              color: isPresent
                                                  ? AppColors.goldPrimary
                                                        .withValues(
                                                          alpha: isDark
                                                              ? 0.1
                                                              : 0.05,
                                                        )
                                                  : null,
                                              onTap: _isEditMode
                                                  ? () async {
                                                      // Toggle attendance in pending map
                                                      setState(() {
                                                        final newStatus =
                                                            isPresent
                                                            ? 'ABSENT'
                                                            : 'PRESENT';
                                                        // If new status matches original DB status, remove from map
                                                        if (newStatus ==
                                                            item
                                                                .record!
                                                                .status) {
                                                          _pendingStatusChanges
                                                              .remove(
                                                                item.record!.id,
                                                              );
                                                        } else {
                                                          _pendingStatusChanges[item
                                                                  .record!
                                                                  .id] =
                                                              newStatus;
                                                        }
                                                      });
                                                    }
                                                  : () {
                                                      context.push(
                                                        '/students/${item.studentId}',
                                                      );
                                                    },
                                              child: Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 18,
                                                    backgroundColor: isPresent
                                                        ? AppColors.goldPrimary
                                                        : (isDark
                                                              ? Colors
                                                                    .grey
                                                                    .shade700
                                                              : Colors
                                                                    .grey
                                                                    .shade200),
                                                    child: Text(
                                                      item.studentName[0]
                                                          .toUpperCase(),
                                                      style: TextStyle(
                                                        color: isPresent
                                                            ? Colors.white
                                                            : (isDark
                                                                  ? Colors
                                                                        .white70
                                                                  : Colors
                                                                        .grey),
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      item.studentName,
                                                      style: theme.textTheme.titleMedium?.copyWith(
                                                        fontWeight: isPresent
                                                            ? FontWeight.bold
                                                            : FontWeight.normal,
                                                        color: isDark
                                                            ? (isPresent
                                                                  ? Colors
                                                                        .grey
                                                                        .shade400
                                                                  : Colors
                                                                        .grey
                                                                        .shade600)
                                                            : (isPresent
                                                                  ? Colors
                                                                        .grey
                                                                        .shade600
                                                                  : Colors
                                                                        .grey
                                                                        .shade400),
                                                      ),
                                                    ),
                                                  ),
                                                  // Show circular checkbox in edit mode
                                                  // Animated Checkbox
                                                  AnimatedScale(
                                                    scale: _isEditMode
                                                        ? 1.0
                                                        : 0.0,
                                                    duration: const Duration(
                                                      milliseconds: 250,
                                                    ),
                                                    curve: Curves.easeOutBack,
                                                    child: _isEditMode
                                                        ? Container(
                                                            width: 26,
                                                            height: 26,
                                                            decoration: BoxDecoration(
                                                              shape: BoxShape
                                                                  .circle,
                                                              color: isPresent
                                                                  ? AppColors
                                                                        .goldPrimary
                                                                  : Colors
                                                                        .transparent,
                                                              border: Border.all(
                                                                color: isPresent
                                                                    ? AppColors
                                                                          .goldPrimary
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
                                                                    color: Colors
                                                                        .white,
                                                                  )
                                                                : null,
                                                          )
                                                        : const SizedBox(
                                                            width: 0,
                                                            height: 26,
                                                          ),
                                                  ),
                                                  // Only show chevron if NOT in edit mode
                                                  if (!_isEditMode)
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          isPresent
                                                              ? Icons
                                                                    .check_circle
                                                              : Icons
                                                                    .cancel_outlined,
                                                          color: isPresent
                                                              ? AppColors
                                                                    .goldPrimary
                                                              : Colors
                                                                    .grey
                                                                    .shade400,
                                                          size: 22,
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Icon(
                                                          Icons.chevron_right,
                                                          color: isDark
                                                              ? Colors
                                                                    .grey
                                                                    .shade600
                                                              : Colors
                                                                    .grey
                                                                    .shade400,
                                                          size: 20,
                                                        ),
                                                      ],
                                                    ),
                                                ],
                                              ),
                                            )
                                            .animate(
                                              target: isHighlight ? 1 : 0,
                                            )
                                            .shimmer(
                                              duration: 600.ms,
                                              delay: 200.ms,
                                              color: isPresent
                                                  ? AppColors.goldPrimary
                                                  : (isDark
                                                        ? Colors
                                                              .blueGrey
                                                              .shade400
                                                        : Colors
                                                              .blueGrey
                                                              .shade300),
                                              curve: Curves.linear,
                                            ),
                                  );
                                }),

                                // New Students Section (show in both view and edit modes)
                                if (newStudents.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    "${l10n.newArrivals} (${newStudents.length})",
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.grey.shade500
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _isEditMode
                                        ? l10n.tapToAddToSession
                                        : l10n.notInSession,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isDark
                                          ? Colors.grey.shade600
                                          : Colors.grey.shade500,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ...newStudents.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final item = entry.value;

                                    return PremiumCard(
                                      delay: index * 0.02,
                                      margin: const EdgeInsets.only(bottom: 8),
                                      color: isDark
                                          ? Colors.blue.withValues(alpha: 0.08)
                                          : Colors.blue.withValues(alpha: 0.05),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.blue.withValues(alpha: 0.3)
                                            : Colors.blue.withValues(
                                                alpha: 0.2,
                                              ),
                                        style: BorderStyle.solid,
                                      ),
                                      onTap: _isEditMode
                                          ? () async {
                                              // Add student using helper to track for cancel
                                              await _addNewArrival(
                                                item.studentId,
                                              );
                                            }
                                          : () {
                                              // Navigate to student detail
                                              context.push(
                                                '/students/${item.studentId}',
                                              );
                                            },
                                      child: Row(
                                        children: [
                                          // Dashed circle with + icon
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.blue.withValues(
                                                  alpha: 0.5,
                                                ),
                                                width: 2,
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                item.studentName[0]
                                                    .toUpperCase(),
                                                style: TextStyle(
                                                  color: Colors.blue.shade400,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.studentName,
                                                  style: theme
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: isDark
                                                            ? Colors
                                                                  .blue
                                                                  .shade300
                                                            : Colors
                                                                  .blue
                                                                  .shade700,
                                                      ),
                                                ),
                                                Text(
                                                  l10n.notInSession,
                                                  style: theme
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: isDark
                                                            ? Colors
                                                                  .grey
                                                                  .shade600
                                                            : Colors
                                                                  .grey
                                                                  .shade500,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Add icon in edit mode, chevron in view mode
                                          if (_isEditMode)
                                            Container(
                                              width: 26,
                                              height: 26,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.blue.withValues(
                                                  alpha: 0.2,
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.add,
                                                size: 18,
                                                color: Colors.blue.shade400,
                                              ),
                                            )
                                          else
                                            Icon(
                                              Icons.chevron_right,
                                              color: isDark
                                                  ? Colors.grey.shade600
                                                  : Colors.grey.shade400,
                                              size: 20,
                                            ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
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
        error: (err, st) =>
            Center(child: Text(l10n.errorGeneric(err.toString()))),
      ),
    );
  }

  Color _getProgressColor(double percentage, bool isDark) {
    if (percentage >= 0.75) {
      return isDark ? Colors.green.shade400 : Colors.green;
    }
    if (percentage >= 0.5) return Colors.orange;
    // Fix: Use brighter red in dark mode for visibility
    return isDark ? AppColors.redLight : AppColors.redPrimary;
  }

  Widget _buildActionButtons(
    BuildContext context,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return AnimatedCrossFade(
          firstChild: Row(
            key: const ValueKey('view_mode'),
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _enterEditMode,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : Colors.black87,
                    side: BorderSide(
                      color: isDark
                          ? Colors.grey.shade600
                          : Colors.grey.shade400,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.edit, size: 18),
                  label: Text(l10n.edit),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showDeleteSheet(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.redPrimary.withValues(
                      alpha: isDark ? 0.25 : 0.1,
                    ),
                    foregroundColor: isDark
                        ? Colors.redAccent.shade200
                        : AppColors.redPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: AppColors.redPrimary.withValues(
                          alpha: isDark ? 0.6 : 0.3,
                        ),
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(l10n.delete),
                ),
              ),
            ],
          ),
          secondChild: Row(
            key: const ValueKey('edit_mode'),
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _cancelEdit,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark
                        ? Colors.grey.shade400
                        : Colors.grey.shade700,
                    side: BorderSide(
                      color: isDark
                          ? Colors.grey.shade600
                          : Colors.grey.shade400,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.close, size: 18),
                  label: Text(l10n.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(l10n.save),
                ),
              ),
            ],
          ),
          crossFadeState: _isEditMode
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        )
        .animate()
        .fade(delay: 100.ms, duration: 300.ms)
        .slideY(begin: 0.1, curve: Curves.easeOut);
  }

  Widget _buildStatsCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    double percentage,
    int presentCount,
    int total,
    AppLocalizations l10n,
  ) {
    return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      AppColors.goldPrimary.withValues(alpha: 0.15),
                      AppColors.goldDark.withValues(alpha: 0.05),
                    ]
                  : [
                      AppColors.goldPrimary.withValues(alpha: 0.1),
                      AppColors.goldLight.withValues(alpha: 0.02),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (isDark ? AppColors.goldPrimary : AppColors.goldPrimary)
                  .withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.attendanceRate,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(percentage * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: _getProgressColor(percentage, isDark),
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.check_circle,
                        label: l10n.present,
                        count: presentCount,
                        color: AppColors.goldPrimary,
                        isDark: isDark,
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        color: isDark ? Colors.white12 : Colors.grey.shade300,
                      ),
                      _StatChip(
                        icon: Icons.cancel,
                        label: l10n.absent,
                        count: total > 0 ? total - presentCount : 0,
                        color: Colors.grey,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Stack(
                  children: [
                    Container(
                      height: 10,
                      width: double.infinity,
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          height: 10,
                          width: constraints.maxWidth * percentage,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            gradient: LinearGradient(
                              colors: [
                                _getProgressColor(percentage, isDark),
                                _getProgressColor(
                                  percentage,
                                  isDark,
                                ).withValues(alpha: 0.7),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate()
        .fade(duration: 400.ms)
        .slideY(begin: 0.1, curve: Curves.easeOut);
  }

  Widget _buildTitleRow(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    int total,
    AppLocalizations l10n,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
              "${l10n.students} ($total)",
              key: const ValueKey('students_title'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            )
            .animate()
            .fade(delay: 100.ms, duration: 300.ms)
            .slideY(begin: 0.1, curve: Curves.easeOut),
        _SortingToggle(
              current: _sortBy,
              onChanged: (value) => setState(() => _sortBy = value),
              l10n: l10n,
              isDark: isDark,
            )
            .animate()
            .fade(delay: 200.ms, duration: 300.ms)
            .slideY(begin: 0.1, curve: Curves.easeOut),
      ],
    );
  }

  void _showDeleteSheet(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

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
                  color: AppColors.redPrimary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_forever,
                  color: AppColors.redPrimary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.deleteSessionConfirmTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.deleteSessionConfirmMessage,
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
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await ref
                            .read(attendanceControllerProvider.notifier)
                            .deleteSession(widget.sessionId);
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
                      child: Text(
                        l10n.delete,
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

class _SortingToggle extends StatelessWidget {
  final AttendanceSortOption current;
  final ValueChanged<AttendanceSortOption> onChanged;
  final AppLocalizations l10n;
  final bool isDark;

  const _SortingToggle({
    required this.current,
    required this.onChanged,
    required this.l10n,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOption(context, AttendanceSortOption.name, l10n.sortByName),
          _buildOption(context, AttendanceSortOption.status, l10n.sortByStatus),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    AttendanceSortOption option,
    String label,
  ) {
    final isSelected = current == option;
    return GestureDetector(
      onTap: () => onChanged(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.goldPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          ),
        ),
      ),
    );
  }
}

enum AttendanceSortOption { name, status }
