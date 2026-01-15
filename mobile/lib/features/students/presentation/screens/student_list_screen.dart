import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/students_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/premium_card.dart';
import 'package:mobile/features/classes/data/classes_controller.dart';
import 'package:mobile/features/auth/data/auth_controller.dart';
import 'package:mobile/features/sync/data/sync_service.dart';
import 'package:mobile/l10n/app_localizations.dart';

class StudentListScreen extends ConsumerWidget {
  const StudentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(classStudentsProvider);
    final user = ref.watch(authControllerProvider).asData?.value;
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: user?.role == 'ADMIN'
            ? Consumer(
                builder: (context, ref, _) {
                  final classesAsync = ref.watch(classesStreamProvider);
                  final selectedInfo = ref.watch(selectedClassIdProvider);
                  return classesAsync.when(
                    data: (classes) {
                      if (classes.isEmpty) return const Text('Manage Classes');
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedInfo,
                            hint: const Text(
                              'Select Class',
                              style: TextStyle(color: Colors.white),
                            ),
                            dropdownColor: AppColors.bluePrimary,
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.white,
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            items: classes
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                ref
                                        .read(selectedClassIdProvider.notifier)
                                        .state =
                                    val;
                              }
                            },
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox(),
                    error: (_, __) => const Text('Error'),
                  );
                },
              )
            : Text(
                l10n?.students ?? 'My Class',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync Now',
            onPressed: () {
              ref.read(syncServiceProvider).sync();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sync started...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () {
              // TODO: Implement Search
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
                    size: 80,
                    color: AppColors.textSecondaryLight.withOpacity(0.5),
                  ).animate().scale(
                    duration: 500.ms,
                    curve: Curves.easeOutBack,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No students found',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textSecondaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fade(delay: 200.ms),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: students.length,
            // Add extra padding at bottom to clear the floating navbar
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemBuilder: (context, index) {
              final student = students[index];
              return PremiumCard(
                delay: index * 0.05, // Staggered animation
                margin: const EdgeInsets.only(bottom: 12),
                onTap: () => context.push('/students/${student.id}'),
                child: Row(
                  children: [
                    Hero(
                      tag: 'student_avatar_${student.id}',
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.goldPrimary,
                        child: Text(
                          student.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.phone,
                                size: 14,
                                color: AppColors.textSecondaryLight,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                student.phone?.isNotEmpty == true
                                    ? student.phone!
                                    : 'No phone',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppColors.textSecondaryLight,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppColors.textSecondaryLight.withOpacity(0.5),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
          bottom: 90,
        ), // Lift above floating navbar
        child: FloatingActionButton.extended(
          onPressed: () => _showAddStudentDialog(context, ref),
          backgroundColor: AppColors.goldPrimary,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            'Add Student',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ).animate().scale(delay: 1.seconds, curve: Curves.elasticOut),
      ),
    );
  }

  void _showAddStudentDialog(BuildContext context, WidgetRef ref) {
    // Keeping logic same, just UI update if needed later
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final user = ref.read(authControllerProvider).asData?.value;
    String? selectedClassId = user?.classId;
    final bool isAdmin = user?.classId == null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Student'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Student Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              if (isAdmin) ...[
                const SizedBox(height: 16),
                Consumer(
                  builder: (context, ref, child) {
                    final classesAsync = ref.watch(classesStreamProvider);
                    return classesAsync.when(
                      data: (classes) {
                        if (classes.isEmpty)
                          return const Text('No classes available');
                        return DropdownButtonFormField<String>(
                          value: selectedClassId,
                          decoration: const InputDecoration(
                            labelText: 'Assign Class',
                            prefixIcon: Icon(Icons.class_),
                            border: OutlineInputBorder(),
                          ),
                          items: classes
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setState(() => selectedClassId = val);
                          },
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (e, s) => Text('Error loading classes: $e'),
                    );
                  },
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldPrimary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (nameController.text.isNotEmpty && selectedClassId != null) {
                  try {
                    await ref
                        .read(studentsControllerProvider)
                        .addStudent(
                          name: nameController.text,
                          phone: phoneController.text,
                          classId: selectedClassId,
                        );
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter name and select class'),
                    ),
                  );
                }
              },
              child: const Text('Add Student'),
            ),
          ],
        ),
      ),
    );
  }
}
