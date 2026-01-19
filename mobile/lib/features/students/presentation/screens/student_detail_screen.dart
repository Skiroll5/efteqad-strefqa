import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/premium_card.dart';
import '../../../../core/database/app_database.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../data/students_controller.dart';
import '../../data/notes_controller.dart';
import '../../data/notes_repository.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart' as intl;
import '../../../attendance/data/attendance_controller.dart';
import 'package:mobile/features/attendance/data/attendance_repository.dart';
import '../../../auth/data/auth_controller.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import '../../../attendance/presentation/screens/attendance_detail_screen.dart';

final studentCustomMessageProvider = FutureProvider.autoDispose
    .family<String?, String>((ref, studentId) async {
      final controller = ref.read(studentsControllerProvider);
      return controller.getStudentPreference(studentId);
    });

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
                        color: AppColors.goldPrimary.withValues(alpha: 0.3),
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
                ).animate().fade(duration: 400.ms),
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
                    )
                    .animate()
                    .fade(duration: 400.ms, delay: 50.ms)
                    .slideY(
                      begin: 0.2,
                      end: 0,
                      duration: 400.ms,
                      curve: Curves.easeOutQuart,
                    ),
                // Contact Actions - Two Lines (Compact)
                if (student.phone != null && student.phone!.isNotEmpty)
                  Padding(
                        padding: const EdgeInsets.only(
                          left: 64,
                          right: 64,
                          top: 16,
                        ),
                        child: Column(
                          children: [
                            // Phone Number Row (Dialer)
                            Container(
                              height: 42,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                child: InkWell(
                                  onTap: () async {
                                    final Uri launchUri = Uri(
                                      scheme: 'tel',
                                      path: student.phone!,
                                    );
                                    if (await canLaunchUrl(launchUri)) {
                                      await launchUrl(launchUri);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Directionality(
                                    textDirection: ui.TextDirection.ltr,
                                    child: Row(
                                      children: [
                                        // Phone icon
                                        const SizedBox(width: 12),
                                        Icon(
                                          Icons.phone_outlined,
                                          size: 18,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 8),
                                        // Phone number
                                        Expanded(
                                          child: Text(
                                            _formatPhone(student.phone!),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.grey.shade800,
                                            ),
                                          ),
                                        ),
                                        // Copy button
                                        Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () {
                                              Clipboard.setData(
                                                ClipboardData(
                                                  text: student.phone!,
                                                ),
                                              );
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    l10n?.phoneNumberCopied ?? 'Phone number copied',
                                                  ),
                                                ),
                                              );
                                            },
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(8),
                                              child: Icon(
                                                Icons.copy,
                                                size: 16,
                                                color: isDark
                                                    ? Colors.white38
                                                    : Colors.grey.shade400,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // WhatsApp Button Row
                            Container(
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFF25D366),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF25D366,
                                    ).withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Main WhatsApp Button
                                  Expanded(
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () async {
                                          // Refresh and wait for the latest value
                                          final customMessage = await ref
                                              .refresh(
                                                studentCustomMessageProvider(
                                                  studentId,
                                                ).future,
                                              );

                                          String message =
                                              customMessage ??
                                              _buildTemplateMessage(
                                                ref,
                                                student,
                                              );
                                          if (context.mounted) {
                                            await _launchWhatsApp(
                                              context,
                                              student,
                                              message,
                                            );
                                          }
                                        },
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(10),
                                          bottomLeft: Radius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const FaIcon(
                                              FontAwesomeIcons.whatsapp,
                                              size: 18,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              l10n?.whatsappButton ??
                                                  'WhatsApp',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Divider
                                  Container(
                                    width: 1,
                                    height: 24,
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                                  // Customize Button
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _showWhatsAppDialog(
                                        context,
                                        ref,
                                        student,
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(10),
                                        bottomRight: Radius.circular(10),
                                      ),
                                      child: const SizedBox(
                                        width: 42,
                                        height: 42,
                                        child: Center(
                                          child: FaIcon(
                                            FontAwesomeIcons.penToSquare,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fade(duration: 400.ms, delay: 100.ms)
                      .slideY(
                        begin: 0.2,
                        end: 0,
                        duration: 400.ms,
                        curve: Curves.easeOutQuart,
                      ),

                const SizedBox(height: 24),

                // Edit/Delete Buttons
                Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _showEditDialog(context, ref, student),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.goldPrimary,
                              side: const BorderSide(
                                color: AppColors.goldPrimary,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            label: Text(l10n?.edit ?? 'Edit'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showDeleteDialog(context, ref),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.redPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.delete_outline, size: 20),
                            label: Text(l10n?.delete ?? 'Delete'),
                          ),
                        ),
                      ],
                    )
                    .animate()
                    .fade(duration: 400.ms, delay: 150.ms)
                    .slideY(
                      begin: 0.2,
                      end: 0,
                      duration: 400.ms,
                      curve: Curves.easeOutQuart,
                    ),

                const SizedBox(height: 16),

                // Info Cards (Stacked)
                _buildBirthdayCard(context, student, l10n, isDark)
                    .animate()
                    .fade(duration: 400.ms, delay: 200.ms)
                    .slideY(
                      begin: 0.2,
                      end: 0,
                      duration: 400.ms,
                      curve: Curves.easeOutQuart,
                    ),

                const SizedBox(height: 12),

                _buildAddressCard(context, student, l10n, isDark)
                    .animate()
                    .fade(duration: 400.ms, delay: 250.ms)
                    .slideY(
                      begin: 0.2,
                      end: 0,
                      duration: 400.ms,
                      curve: Curves.easeOutQuart,
                    ),

                const SizedBox(height: 24),

                // Attendance History Logic (No wrapper animation, handled internally)
                if (historyAsync.valueOrNull != null &&
                    historyAsync.valueOrNull!.isNotEmpty)
                  _buildAttendanceHistory(
                    context,
                    historyAsync.value!,
                    isDark,
                    l10n,
                  ),

                const SizedBox(height: 24),

                // Visitation Notes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionHeader(
                          context,
                          l10n?.visitationNotes ?? "Visitation Notes",
                          isDark,
                        )
                        .animate()
                        .fade(duration: 400.ms, delay: 500.ms)
                        .slideX(
                          begin: -0.1,
                          end: 0,
                          duration: 400.ms,
                          curve: Curves.easeOutQuart,
                        ),
                    Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () =>
                                _showAddNoteDialog(context, ref, student.id),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.goldPrimary.withValues(
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
                                    l10n?.addNote ?? 'Add Note',
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
                        .fade(duration: 400.ms, delay: 550.ms)
                        .slideX(
                          begin: 0.1,
                          end: 0,
                          duration: 400.ms,
                          curve: Curves.easeOutQuart,
                        ),
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
                            delay: 0.6,
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
                            final noteItem = entry.value;
                            return _NoteItem(
                                  // Using GlobalKey to maintain state if reordered, though list order is stable
                                  // key: ValueKey(noteItem.note.id),
                                  noteItem: noteItem,
                                  studentId: studentId,
                                )
                                .animate(
                                  delay: (0.6 + (index * 0.05)).seconds,
                                ) // Start after header
                                .fade(duration: 400.ms)
                                .slideX(
                                  begin: 0.1,
                                  end: 0,
                                  duration: 400.ms,
                                  curve: Curves.easeOutQuart,
                                );
                          }).toList(),
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, s) => Text(
                        AppLocalizations.of(
                          context,
                        )!.errorGeneric(e.toString()),
                      ),
                    );
                  },
                ),

                // Add bottom padding for better scroll
                const SizedBox(height: 100),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Text(AppLocalizations.of(context)!.errorGeneric(e.toString())),
        ),
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

  Future<void> _launchWhatsApp(
    BuildContext context,
    Student student,
    String message,
  ) async {
    if (student.phone == null || student.phone!.isEmpty) return;

    // Clean phone number (remove non-digits, ensure country code if strictly needed,
    // but usually local numbers work if saved in contacts, or full intl format is best.
    // Assuming simple usage for now).
    // WhatsApp URL scheme usually expects clean digits.
    String cleanPhone = student.phone!.replaceAll(RegExp(r'\D'), '');

    // Default to +2 (Egypt) if missing country code and looks like local mobile
    // If it's 11 digits and starts with '01' (e.g. 01007109211), make it 201007109211
    if (cleanPhone.length == 11 && cleanPhone.startsWith('01')) {
      cleanPhone = '2${cleanPhone.substring(1)}'; // 2 + 0100... -> 20100...
    } else if (cleanPhone.length == 10 && cleanPhone.startsWith('1')) {
      // Just in case stored without 0 but local
      cleanPhone = '2$cleanPhone';
    }

    final Uri appUrl = Uri.parse(
      "whatsapp://send?phone=$cleanPhone&text=${Uri.encodeComponent(message)}",
    );
    final Uri webUrl = Uri.parse(
      "https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}",
    );

    try {
      // Try to launch app directly
      bool launched = false;
      if (await canLaunchUrl(appUrl)) {
        launched = await launchUrl(
          appUrl,
          mode: LaunchMode.externalApplication,
        );
      }

      if (!launched) {
        // Fallback to web
        if (await canLaunchUrl(webUrl)) {
          await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.errorWhatsApp),
              ),
            );
          }
        }
      }
    } catch (e) {
      // If something crashes (like "component name null"), try web as fallback
      try {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } catch (e2) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.errorGeneric(e.toString()),
              ),
            ),
          );
        }
      }
    }
  }

  String _buildTemplateMessage(WidgetRef ref, Student student) {
    final user = ref.read(authControllerProvider).value;
    String initialMessage = user?.whatsappTemplate ?? '';

    if (initialMessage.isEmpty) {
      initialMessage = "Hi {firstname},";
    }

    final firstName = student.name.split(' ').first;
    initialMessage = initialMessage.replaceAll('{firstname}', firstName);
    initialMessage = initialMessage.replaceAll('{name}', student.name);

    if (student.birthdate != null) {
      final now = DateTime.now();
      final birthdate = student.birthdate!;
      int age = (now.year - birthdate.year).toInt();
      if (now.month < birthdate.month ||
          (now.month == birthdate.month && now.day < birthdate.day)) {
        age--;
      }
      initialMessage = initialMessage.replaceAll('{age}', age.toString());
    } else {
      initialMessage = initialMessage.replaceAll('{age}', '');
    }
    return initialMessage;
  }

  Future<void> _showWhatsAppDialog(
    BuildContext context,
    WidgetRef ref,
    Student student,
  ) async {
    if (student.phone == null || student.phone!.isEmpty) return;

    // Fetch customized message from backend
    final controller = ref.read(studentsControllerProvider);
    final customMessage = await controller.getStudentPreference(student.id);
    final initialMessage = customMessage ?? _buildTemplateMessage(ref, student);

    if (!context.mounted) return;

    final messageController = TextEditingController(text: initialMessage);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context);
          ui.TextDirection getDirection(String text) {
            if (text.trim().isEmpty) return ui.TextDirection.ltr;
            final firstChar = text.trim()[0];
            final isLatin = RegExp(r'^[a-zA-Z]').hasMatch(firstChar);
            return isLatin ? ui.TextDirection.ltr : ui.TextDirection.rtl;
          }

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
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
                        color: isDark
                            ? AppColors.dragHandleDark
                            : AppColors.dragHandleLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    l10n?.whatsappCustomize ?? 'Customize Message',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: messageController,
                    autofocus: true,
                    maxLines: 5,
                    textDirection: getDirection(messageController.text),
                    onChanged: (val) {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: l10n?.typeMessageHint ?? 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.withValues(alpha: 0.05),
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
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              await ref
                                  .read(studentsControllerProvider)
                                  .saveStudentPreference(
                                    student.id,
                                    messageController.text,
                                  );
                              ref.invalidate(
                                studentCustomMessageProvider(student.id),
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      l10n?.messageSaved ?? 'Message saved',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.errorSave(e.toString()),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.goldPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.check_rounded),
                          label: Text(l10n?.save ?? 'Save'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBirthdayCard(
    BuildContext context,
    Student student,
    AppLocalizations? l10n,
    bool isDark,
  ) {
    final hasBirthday = student.birthdate != null;
    final now = DateTime.now();

    String ageText = "--";
    String nextBirthdayText = l10n?.notSet ?? "Not Set";
    bool isToday = false;

    if (hasBirthday) {
      final birthdate = student.birthdate!;
      int age = (now.year - birthdate.year).toInt();
      if (now.month < birthdate.month ||
          (now.month == birthdate.month && now.day < birthdate.day)) {
        age--;
      }
      ageText = l10n?.yearsOld(age) ?? "$age years old";

      DateTime nextBirthday = DateTime(
        now.year,
        birthdate.month,
        birthdate.day,
      );
      if (nextBirthday.isBefore(now.subtract(const Duration(days: 1)))) {
        nextBirthday = DateTime(now.year + 1, birthdate.month, birthdate.day);
      }

      final difference = nextBirthday.difference(now);
      final daysUntil = difference.inDays;
      final months = daysUntil ~/ 30;
      final days = daysUntil % 30;

      isToday = daysUntil == 0;
      if (isToday) {
        nextBirthdayText =
            l10n?.todayIsBirthday ?? "Today is their birthday! 🎉";
      } else {
        nextBirthdayText =
            l10n?.birthdayCountdown(months, days) ??
            "In $months months, $days days";
      }
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
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.goldPrimary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.cake,
                        color: hasBirthday
                            ? AppColors.goldPrimary
                            : Colors.grey,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
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
                            hasBirthday
                                ? intl.DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(student.birthdate!)
                                : (l10n?.notSet ?? "Not Set"),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: hasBirthday ? 16 : 14,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          if (hasBirthday) ...[
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
                        ],
                      ),
                    ),
                  ],
                ),
                if (hasBirthday) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
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
                  (student.address?.isNotEmpty == true)
                      ? student.address!
                      : (l10n?.noAddress ?? "No address provided"),
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
    // 1. Sort History (Descending Date)
    final sortedHistory = List<AttendanceRecordWithSession>.from(history);
    sortedHistory.sort((a, b) => b.session.date.compareTo(a.session.date));

    // 2. Group by "yyyy-MM"
    final grouped = <String, List<AttendanceRecordWithSession>>{};
    for (var item in sortedHistory) {
      final key = intl.DateFormat('yyyy-MM').format(item.session.date);
      if (!grouped.containsKey(key)) grouped[key] = [];
      grouped[key]!.add(item);
    }

    // 3. Stats
    final totalPresent = history
        .where((s) => s.record.status == 'PRESENT')
        .length;
    final totalSessions = history.length;
    final overallRate = totalSessions == 0
        ? 0
        : ((totalPresent / totalSessions) * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(
                  context,
                  l10n?.attendanceHistory ?? "Attendance History",
                  isDark,
                )
                .animate()
                .fade(duration: 400.ms, delay: 300.ms)
                .slideX(
                  begin: -0.1,
                  end: 0,
                  duration: 400.ms,
                  curve: Curves.easeOutQuart,
                ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.goldPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "$overallRate% ${l10n?.present ?? 'Present'}",
                style: const TextStyle(
                  color: AppColors.goldDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ).animate().fade(duration: 400.ms, delay: 350.ms),
          ],
        ),
        const SizedBox(height: 16),
        PremiumCard(
          delay: 0.4,
          child: Padding(
            padding: const EdgeInsets.all(8), // Compact padding
            child: Column(
              children: grouped.entries.map((entry) {
                final dateStr = entry.key; // yyyy-MM
                final date = DateTime.parse("$dateStr-01");

                // Localize month name but keep digits Latin if needed
                final locale = Localizations.localeOf(context).toString();
                final monthName = intl.DateFormat(
                  'MMM',
                  locale,
                ).format(date); // Localized month

                // Force Latin digits for Year: use 'en' locale
                final yearName = intl.DateFormat(
                  'yyyy',
                  'en',
                ).format(date); // 2025

                final sessions = entry.value;

                // Reverse for Left-to-Right (Day 1 -> 30) visual flow
                final visualSessions = sessions.reversed.toList();

                final presentCount = sessions
                    .where((s) => s.record.status == 'PRESENT')
                    .length;
                final totalMonth = sessions.length;
                final monthRate = totalMonth == 0
                    ? 0
                    : ((presentCount / totalMonth) * 100).round();

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      // Month Label
                      SizedBox(
                        width: 48,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              monthName.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            Text(
                              yearName,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Dots Grid/Wrap
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: visualSessions.map((item) {
                            final status = item.record.status;
                            final isPresent = status == 'PRESENT';
                            final isAbsent = status == 'ABSENT';

                            Color color;
                            Color textColor;
                            Color? textShadowColor;
                            BoxBorder? border;
                            List<Color>? gradientColors;
                            List<BoxShadow>? shadows;

                            if (isPresent) {
                              // WhatsApp green - consistent with page theme
                              gradientColors = [
                                const Color(0xFF25D366),
                                const Color(0xFF4ADE80),
                              ];
                              color = Colors.transparent;
                              textColor = Colors.white;
                              textShadowColor = const Color(
                                0xFF1A9E4C,
                              ); // Darker WhatsApp green
                              shadows = [
                                BoxShadow(
                                  color: const Color(
                                    0xFF25D366,
                                  ).withValues(alpha: 0.5),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 2),
                                ),
                              ];
                            } else if (isAbsent) {
                              // AppColors.redPrimary - same as delete student button
                              gradientColors = [
                                AppColors.redPrimary,
                                const Color(0xFFD35D52), // Lighter shade
                              ];
                              color = Colors.transparent;
                              textColor = Colors.white;
                              textShadowColor = const Color(
                                0xFFB02A37,
                              ); // Darker red
                              shadows = [
                                BoxShadow(
                                  color: AppColors.redPrimary.withValues(
                                    alpha: 0.5,
                                  ),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 2),
                                ),
                              ];
                            } else {
                              // Excused / Other - Premium amber outline
                              gradientColors = null;
                              color = isDark
                                  ? Colors.amber.withValues(alpha: 0.1)
                                  : Colors.amber.withValues(alpha: 0.08);
                              textColor = Colors.amber;
                              textShadowColor =
                                  null; // No shadow for outline style
                              border = Border.all(
                                color: Colors.amber,
                                width: 2,
                              );
                              shadows = [
                                BoxShadow(
                                  color: Colors.amber.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ];
                            }

                            final dayStr = intl.DateFormat(
                              'd',
                            ).format(item.session.date);

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AttendanceDetailScreen(
                                          sessionId: item.session.id,
                                          highlightStudentId: studentId,
                                        ),
                                  ),
                                );
                              },
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: gradientColors == null ? color : null,
                                  gradient: gradientColors != null
                                      ? LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: gradientColors,
                                        )
                                      : null,
                                  shape: BoxShape.circle,
                                  border: border,
                                  boxShadow: shadows,
                                ),
                                child: Center(
                                  child: Text(
                                    dayStr,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: textColor,
                                      shadows: textShadowColor != null
                                          ? [
                                              Shadow(
                                                color: textShadowColor,
                                                blurRadius: 2,
                                                offset: const Offset(0, 1),
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      // Circular Progress Rate
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Background circle
                            CircularProgressIndicator(
                              value: 1.0,
                              strokeWidth: 3,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.08),
                              ),
                            ),
                            // Progress circle
                            CircularProgressIndicator(
                              value: monthRate / 100,
                              strokeWidth: 3,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                monthRate >= 75
                                    ? const Color(0xFF25D366) // WhatsApp green
                                    : (monthRate >= 50
                                          ? Colors.amber
                                          : AppColors
                                                .redPrimary), // Same as delete button
                              ),
                            ),
                            // Percentage text
                            Text(
                              "$monthRate",
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: monthRate >= 75
                                    ? const Color(0xFF25D366)
                                    : (monthRate >= 50
                                          ? Colors.amber
                                          : AppColors.redPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // --- Dialogs (Refactored to look cleaner) ---

  void _showAddNoteDialog(
    BuildContext context,
    WidgetRef ref,
    String studentId,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final noteController = TextEditingController(); // Renamed to match usage
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
              Text(
                l10n.addNote,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                autofocus: true,
                maxLines: 3,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: l10n.whatHappened,
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white30 : Colors.black38,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white24 : Colors.black12,
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
                        foregroundColor: isDark
                            ? Colors.white70
                            : Colors.black87,
                        side: BorderSide(
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                      ),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (noteController.text.isNotEmpty) {
                          ref
                              .read(notesControllerProvider.notifier)
                              .addNote(studentId, noteController.text);
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.goldPrimary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(l10n.save),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Student student) {
    final nameController = TextEditingController(text: student.name);
    // final phoneController = TextEditingController(text: student.phone ?? ''); // Not used with IntlPhoneField
    String? fullPhoneNumber = student.phone;
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
                            ? AppColors.goldPrimary.withValues(alpha: 0.7)
                            : AppColors.goldDark.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  Directionality(
                    textDirection: ui.TextDirection.ltr,
                    child: IntlPhoneField(
                      initialValue: student.phone,
                      initialCountryCode: 'EG',
                      textAlign: TextAlign.left,
                      decoration: inputDecoration.copyWith(
                        labelText: l10n?.phone ?? 'Phone',
                        counterText: '',
                      ),
                      disableLengthCheck: true,
                      languageCode: l10n?.localeName ?? 'en',
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
                          labelText: 'Search',
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
                            ? AppColors.goldPrimary.withValues(alpha: 0.7)
                            : AppColors.goldDark.withValues(alpha: 0.7),
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
                                  : AppColors.goldDark.withValues(alpha: 0.7),
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
                                        .withValues(alpha: 0.3),
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
                                  (fullPhoneNumber?.isNotEmpty == true)
                                      ? fullPhoneNumber
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
                  color: AppColors.redPrimary.withValues(alpha: 0.1),
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
}

class _NoteItem extends ConsumerStatefulWidget {
  final NoteWithAuthor noteItem;
  final String studentId;

  const _NoteItem({required this.noteItem, required this.studentId});

  @override
  ConsumerState<_NoteItem> createState() => _NoteItemState();
}

class _NoteItemState extends ConsumerState<_NoteItem> {
  bool isExpanded = false;

  TextDirection _getTextDirection(String text) {
    // Find the first letter character (ignoring symbols and numbers)
    // Arabic range: \u0600-\u06FF, Latin letters: a-zA-Z
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      // Check if Arabic letter
      if (RegExp(r'[\u0600-\u06FF]').hasMatch(char)) {
        return TextDirection.rtl;
      }
      // Check if Latin letter
      if (RegExp(r'[a-zA-Z]').hasMatch(char)) {
        return TextDirection.ltr;
      }
      // Continue if symbol/number/space
    }
    // Default to LTR if no letters found
    return TextDirection.ltr;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final note = widget.noteItem.note;
    final authorName = widget.noteItem.authorName;

    final currentUserState = ref.watch(authControllerProvider);
    final currentUser = currentUserState.value;
    final canEdit =
        currentUser != null &&
        (currentUser.role == 'ADMIN' || currentUser.id == note.authorId);

    // Format Date: dd/MM/yyyy • hh:mm a (Force Latin numerals with 'en')
    final date = note.createdAt;
    final datePart = intl.DateFormat('dd/MM/yyyy', 'en').format(date);
    final timePart = intl.DateFormat('hh:mm', 'en').format(date);
    final amPm = intl.DateFormat('a', 'en').format(date);

    // Manual AM/PM translation
    String localizedAmPm = amPm;
    if (l10n.localeName == 'ar') {
      localizedAmPm = amPm == 'AM' ? 'ص' : 'م';
    }

    final formattedDate = '$datePart • $timePart $localizedAmPm';
    final contentDirection = _getTextDirection(note.content);

    // Premium Card Design
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A1A1A), const Color(0xFF252525)]
              : [Colors.white, const Color(0xFFFAFAFA)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppColors.goldPrimary.withValues(alpha: 0.15)
              : AppColors.goldPrimary.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gold accent strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.grey.withValues(alpha: 0.03),
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? AppColors.goldPrimary.withValues(alpha: 0.1)
                        : AppColors.goldPrimary.withValues(alpha: 0.08),
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Author Avatar with gold ring
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.goldPrimary, AppColors.goldDark],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: isDark
                          ? const Color(0xFF1A1A1A)
                          : Colors.white,
                      child: Text(
                        authorName?.isNotEmpty == true
                            ? authorName![0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.goldPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Author Name & Date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authorName ?? l10n.unknown,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black87,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: isDark
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formattedDate,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? Colors.grey.shade500
                                    : Colors.grey.shade600,
                                fontSize: 11,
                                fontFamily: 'Roboto',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Action Menu
                  if (canEdit)
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      offset: const Offset(-8, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                      elevation: 12,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.more_vert_rounded,
                          size: 18,
                          color: isDark ? Colors.white70 : Colors.grey.shade700,
                        ),
                      ),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditNoteDialog(context, l10n, isDark);
                        } else if (value == 'delete') {
                          _showDeleteNoteDialog(context, l10n, isDark);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          height: 44,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.goldPrimary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.edit_rounded,
                                  size: 16,
                                  color: AppColors.goldPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                l10n.edit,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          height: 44,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.red.shade400.withValues(
                                          alpha: 0.15,
                                        )
                                      : AppColors.redPrimary.withValues(
                                          alpha: 0.1,
                                        ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.delete_rounded,
                                  size: 16,
                                  color: isDark
                                      ? const Color(0xFFFF6B6B)
                                      : AppColors.redPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                l10n.delete,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isDark
                                      ? const Color(0xFFFF6B6B)
                                      : AppColors.redPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final span = TextSpan(
                    text: note.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.85)
                          : Colors.black87,
                      height: 1.6,
                      fontSize: 14,
                    ),
                  );
                  final tp = TextPainter(
                    text: span,
                    textAlign: TextAlign.left,
                    textDirection: contentDirection,
                    maxLines: 4,
                  );
                  tp.layout(maxWidth: constraints.maxWidth);

                  if (tp.didExceedMaxLines) {
                    return Column(
                      crossAxisAlignment: contentDirection == TextDirection.rtl
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            note.content,
                            maxLines: isExpanded ? null : 4,
                            overflow: isExpanded ? null : TextOverflow.ellipsis,
                            textDirection: contentDirection,
                            textAlign: contentDirection == TextDirection.rtl
                                ? TextAlign.right
                                : TextAlign.left,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.85)
                                  : Colors.black87,
                              height: 1.6,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isExpanded = !isExpanded;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.goldPrimary.withValues(alpha: 0.15),
                                  AppColors.goldPrimary.withValues(alpha: 0.08),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isExpanded
                                      ? Icons.expand_less_rounded
                                      : Icons.expand_more_rounded,
                                  size: 16,
                                  color: AppColors.goldPrimary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isExpanded ? l10n.showLess : l10n.showMore,
                                  style: TextStyle(
                                    color: AppColors.goldPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return SizedBox(
                      width: double.infinity,
                      child: Text(
                        note.content,
                        textDirection: contentDirection,
                        textAlign: contentDirection == TextDirection.rtl
                            ? TextAlign.right
                            : TextAlign.left,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.85)
                              : Colors.black87,
                          height: 1.6,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditNoteDialog(
    BuildContext context,
    AppLocalizations? l10n,
    bool isDark,
  ) {
    final controller = TextEditingController(
      text: widget.noteItem.note.content,
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n?.edit ?? 'Edit Note',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: l10n?.whatHappened ?? 'What happened?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n?.cancel ?? 'Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (controller.text.isNotEmpty) {
                          await ref
                              .read(notesControllerProvider.notifier)
                              .updateNote(
                                widget.noteItem.note.id,
                                controller.text,
                              );
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.goldPrimary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(l10n?.save ?? 'Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteNoteDialog(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n.delete,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: Text(
          l10n.deleteWarning,
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
            ),
          ),
          TextButton(
            onPressed: () async {
              await ref
                  .read(notesControllerProvider.notifier)
                  .deleteNote(widget.noteItem.note.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(
              l10n.delete,
              style: const TextStyle(color: AppColors.redPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
