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

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).asData?.value;
    final classesAsync = ref.watch(classesStreamProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get first name for greeting
    final firstName = user?.name.split(' ').first ?? 'User';

    return Scaffold(
      appBar: AppBar(
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
                      onPressed: () => context.push('/classes'),
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
                          // Select class and navigate to students
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
                // Admin: Manage Classes button
                if (user?.role == 'ADMIN')
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/classes'),
                        icon: const Icon(Icons.edit),
                        label: const Text('Manage Classes'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          side: BorderSide(
                            color: isDark
                                ? AppColors.goldPrimary
                                : AppColors.bluePrimary,
                          ),
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
}
