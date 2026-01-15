import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/premium_card.dart';
import '../../../../core/components/premium_button.dart';
import '../../../../core/components/premium_text_field.dart'; // Use for dialogs if possible, or standard for now
import '../../../../core/database/app_database.dart';
import 'package:mobile/l10n/app_localizations.dart';
import '../../data/students_controller.dart';
import '../../data/notes_controller.dart';

class StudentDetailScreen extends ConsumerWidget {
  final String studentId;

  const StudentDetailScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentProvider(studentId));
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.students ?? 'Student Details'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showEditDialog(context, ref, studentAsync.value!),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.redPrimary),
            onPressed: () => _showDeleteDialog(context, ref),
          ),
        ],
      ),
      body: studentAsync.when(
        data: (student) {
          if (student == null) {
            return const Center(child: Text('Student not found'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar Section
                Hero(
                  tag: 'student_avatar_${student.id}',
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.goldPrimary,
                        width: 2,
                      ),
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
                ),
                const SizedBox(height: 16),
                Text(
                  student.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fade().slideY(begin: 0.1, end: 0, delay: 100.ms),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bluePrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.phone, size: 16, color: AppColors.bluePrimary),
                      const SizedBox(width: 8),
                      Text(
                        student.phone?.isNotEmpty == true
                            ? student.phone!
                            : 'No Phone',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.bluePrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ).animate().fade().slideY(begin: 0.1, end: 0, delay: 200.ms),

                const SizedBox(height: 32),

                // Info Cards
                PremiumCard(
                  delay: 0.3,
                  isGlass: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(context, "Details"),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        context,
                        Icons.location_on_outlined,
                        "Address",
                        student.address ?? "No address provided",
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        context,
                        Icons.cake_outlined,
                        "Birthdate",
                        student.birthdate?.toString().split(" ")[0] ??
                            "Not set",
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Visitation Notes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionHeader(context, "Visitation Notes"),
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
                            child: const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('No visitation notes yet.'),
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
                                  backgroundColor: AppColors.bluePrimary
                                      .withOpacity(0.1),
                                  child: const Icon(
                                    Icons.note,
                                    color: AppColors.bluePrimary,
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

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimaryLight,
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  // --- Dialogs (Refactored to look cleaner) ---

  void _showAddNoteDialog(BuildContext context, WidgetRef ref) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Add Note'),
          content: TextField(
            controller: noteController,
            decoration: const InputDecoration(
              hintText: 'Enter note content...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            PremiumButton(
              label: 'Add',
              onPressed: () async {
                if (noteController.text.isNotEmpty) {
                  await ref
                      .read(notesControllerProvider.notifier)
                      .addNote(studentId, noteController.text);
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Student student) {
    final nameController = TextEditingController(text: student.name);
    final phoneController = TextEditingController(text: student.phone);
    final addressController = TextEditingController(text: student.address);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Edit Student'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            PremiumButton(
              label: 'Save',
              onPressed: () async {
                final updatedStudent = student.copyWith(
                  name: nameController.text,
                  phone: Value(phoneController.text),
                  address: Value(addressController.text),
                );
                await ref
                    .read(studentsControllerProvider)
                    .updateStudent(updatedStudent);
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Delete Student'),
          content: const Text('Are you sure? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            PremiumButton(
              label: 'Delete',
              variant: ButtonVariant.danger,
              onPressed: () async {
                await ref
                    .read(studentsControllerProvider)
                    .deleteStudent(studentId);
                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }
}
