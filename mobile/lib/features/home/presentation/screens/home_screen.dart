import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/premium_card.dart';
import '../../../classes/data/classes_controller.dart';
import '../../../auth/data/auth_controller.dart';
import '../../../sync/data/sync_service.dart';
import '../../../students/data/students_controller.dart';
import '../../../../core/database/app_database.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).asData?.value;
    final classesAsync = ref.watch(classesStreamProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get first name for greeting (capitalized)
    final rawName = user?.name.split(' ').first ?? 'User';
    final firstName = rawName.isNotEmpty
        ? rawName[0].toUpperCase() + rawName.substring(1).toLowerCase()
        : 'User';

    return Scaffold(
      appBar: AppBar(
        centerTitle: false, // Align to start (left in LTR, right in RTL)
        title: RichText(
          text: TextSpan(
            style: theme.textTheme.titleLarge,
            children: [
              TextSpan(
                text: 'Hi, ',
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              TextSpan(
                text: firstName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.goldPrimary : AppColors.bluePrimary,
                ),
              ),
              const TextSpan(text: ' 👋'),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync',
            onPressed: () {
              ref.read(syncServiceProvider).sync();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Syncing...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
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
                        ? 'No classes yet'
                        : 'No class assigned',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ).animate().fade(delay: 200.ms),
                  if (user?.role == 'ADMIN') ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showAddClassDialog(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Class'),
                    ).animate().fade(delay: 400.ms).slideY(begin: 0.2, end: 0),
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
                  user?.role == 'ADMIN' ? 'Your Classes' : 'Your Class',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fade(),
                const SizedBox(height: 4),
                Text(
                  'Select a class to manage students and attendance',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ).animate().fade(delay: 100.ms),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: classes.length,
                    itemBuilder: (context, index) {
                      final cls = classes[index];
                      return PremiumCard(
                        delay: index * 0.1,
                        margin: const EdgeInsets.only(bottom: 16),
                        onTap: () {
                          ref.read(selectedClassIdProvider.notifier).state =
                              cls.id;
                          context.push('/students');
                        },
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDark
                                      ? [
                                          AppColors.goldPrimary.withOpacity(
                                            0.3,
                                          ),
                                          AppColors.goldDark.withOpacity(0.2),
                                        ]
                                      : [
                                          AppColors.bluePrimary.withOpacity(
                                            0.15,
                                          ),
                                          AppColors.blueLight.withOpacity(0.1),
                                        ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.class_,
                                color: isDark
                                    ? AppColors.goldPrimary
                                    : AppColors.bluePrimary,
                                size: 32,
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
                            // Admin: Show menu with edit/delete options
                            if (user?.role == 'ADMIN')
                              PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                                onSelected: (value) {
                                  if (value == 'rename') {
                                    _showRenameClassDialog(context, ref, cls);
                                  } else if (value == 'delete') {
                                    _showDeleteClassDialog(context, ref, cls);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'rename',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 20),
                                        SizedBox(width: 8),
                                        Text('Rename'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete,
                                          size: 20,
                                          color: AppColors.redPrimary,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Delete',
                                          style: TextStyle(
                                            color: AppColors.redPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            else
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black.withOpacity(0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.arrow_forward,
                                  size: 20,
                                  color: isDark
                                      ? AppColors.goldPrimary
                                      : AppColors.bluePrimary,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // Admin: Add Class button at bottom
                if (user?.role == 'ADMIN')
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddClassDialog(context, ref),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Class'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: isDark
                              ? AppColors.goldPrimary
                              : AppColors.bluePrimary,
                          foregroundColor: Colors.white,
                        ),
                      ).animate().fade(delay: 500.ms),
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

  void _showAddClassDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final gradeController = TextEditingController();
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
              // Drag Handle
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
              // Title
              Text(
                'Create New Class',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add a new class to manage students',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 24),
              // Name Field
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Class Name',
                  hintText: 'e.g. Sunday School - Grade 3',
                  prefixIcon: Icon(
                    Icons.class_,
                    color: isDark
                        ? AppColors.goldPrimary
                        : AppColors.bluePrimary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.goldPrimary
                          : AppColors.bluePrimary,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Grade Field
              TextField(
                controller: gradeController,
                decoration: InputDecoration(
                  labelText: 'Grade (optional)',
                  hintText: 'e.g. Grade 3',
                  prefixIcon: Icon(
                    Icons.grade,
                    color: isDark
                        ? AppColors.goldPrimary
                        : AppColors.bluePrimary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.goldPrimary
                          : AppColors.bluePrimary,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Buttons
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
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.isNotEmpty) {
                          await ref
                              .read(classesControllerProvider)
                              .addClass(
                                nameController.text,
                                gradeController.text.isNotEmpty
                                    ? gradeController.text
                                    : null,
                              );
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? AppColors.goldPrimary
                            : AppColors.bluePrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Create',
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

  void _showRenameClassDialog(
    BuildContext context,
    WidgetRef ref,
    ClassesData cls,
  ) {
    final nameController = TextEditingController(text: cls.name);
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
              // Drag Handle
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
              // Title
              Text(
                'Rename Class',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              // Name Field
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Class Name',
                  prefixIcon: Icon(
                    Icons.class_,
                    color: isDark
                        ? AppColors.goldPrimary
                        : AppColors.bluePrimary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.goldPrimary
                          : AppColors.bluePrimary,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Buttons
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
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.isNotEmpty) {
                          await ref
                              .read(classesControllerProvider)
                              .updateClass(cls.id, nameController.text);
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? AppColors.goldPrimary
                            : AppColors.bluePrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save',
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

  void _showDeleteClassDialog(
    BuildContext context,
    WidgetRef ref,
    ClassesData cls,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Warning Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.redPrimary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_forever,
                  color: AppColors.redPrimary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                'Delete "${cls.name}"?',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'This will permanently remove this class and all its students. This action cannot be undone.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Buttons
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
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await ref
                            .read(classesControllerProvider)
                            .deleteClass(cls.id);
                        if (context.mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.redPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Delete',
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
}
