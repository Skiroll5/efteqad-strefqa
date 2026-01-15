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
    final user = ref.watch(authControllerProvider).asData?.value;
    final selectedClassId = ref.watch(selectedClassIdProvider);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // If no class is selected, show class selection
    if (selectedClassId == null) {
      return _buildClassSelectionView(context, ref, user, isDark, theme);
    }

    // Class is selected, show students
    return _buildStudentListView(context, ref, user, l10n, theme, isDark);
  }

  Widget _buildClassSelectionView(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
    bool isDark,
    ThemeData theme,
  ) {
    final classesAsync = ref.watch(classesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Class'),
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
        ],
      ),
      body: classesAsync.when(
        data: (allClasses) {
          // Filter classes based on user role
          final classes = user?.role == 'ADMIN'
              ? allClasses
              : allClasses.where((c) => c.id == user?.classId).toList();

          if (classes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.class_outlined,
                    size: 80,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ).animate().scale(
                    duration: 500.ms,
                    curve: Curves.easeOutBack,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.role == 'ADMIN'
                        ? 'No classes found'
                        : 'No class assigned',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ).animate().fade(delay: 200.ms),
                  if (user?.role == 'ADMIN') ...[
                    const SizedBox(height: 8),
                    Text(
                      'Go to Classes tab to create one',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ).animate().fade(delay: 400.ms),
                  ],
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.role == 'ADMIN'
                      ? 'Choose a class to manage:'
                      : 'Your class:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fade(),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: classes.length,
                    itemBuilder: (context, index) {
                      final cls = classes[index];
                      return PremiumCard(
                        delay: index * 0.1,
                        margin: const EdgeInsets.only(bottom: 12),
                        onTap: () {
                          ref.read(selectedClassIdProvider.notifier).state =
                              cls.id;
                        },
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.bluePrimary.withOpacity(
                                  isDark ? 0.3 : 0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.class_,
                                color: isDark
                                    ? AppColors.goldPrimary
                                    : AppColors.bluePrimary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cls.name,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (cls.grade != null &&
                                      cls.grade!.isNotEmpty)
                                    Text(
                                      cls.grade!,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: isDark
                                                ? AppColors.textSecondaryDark
                                                : AppColors.textSecondaryLight,
                                          ),
                                    ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildStudentListView(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
    AppLocalizations? l10n,
    ThemeData theme,
    bool isDark,
  ) {
    final studentsAsync = ref.watch(classStudentsProvider);
    final classesAsync = ref.watch(classesStreamProvider);
    final selectedClassId = ref.watch(selectedClassIdProvider);

    // Get class name for title
    String? className;
    classesAsync.whenData((classes) {
      final cls = classes.where((c) => c.id == selectedClassId).firstOrNull;
      className = cls?.name;
    });

    return Scaffold(
      appBar: AppBar(
        leading: user?.role == 'ADMIN'
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  ref.read(selectedClassIdProvider.notifier).state = null;
                },
              )
            : null,
        title: Text(className ?? l10n?.students ?? 'Students'),
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
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ).animate().scale(
                    duration: 500.ms,
                    curve: Curves.easeOutBack,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No students yet',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ).animate().fade(delay: 200.ms),
                  const SizedBox(height: 8),
                  Text(
                    'Tap below to add the first student',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ).animate().fade(delay: 400.ms),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: students.length,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemBuilder: (context, index) {
              final student = students[index];
              return PremiumCard(
                delay: index * 0.05,
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
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.phone,
                                size: 14,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                student.phone?.isNotEmpty == true
                                    ? student.phone!
                                    : 'No phone',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
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
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
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
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddStudentDialog(context, ref),
          backgroundColor: AppColors.goldPrimary,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Add Student',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ).animate().scale(delay: 500.ms, curve: Curves.elasticOut),
      ),
    );
  }

  void _showAddStudentDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final selectedClassId = ref.read(selectedClassIdProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Student'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  const SnackBar(content: Text('Please enter a name')),
                );
              }
            },
            child: const Text('Add Student'),
          ),
        ],
      ),
    );
  }
}
