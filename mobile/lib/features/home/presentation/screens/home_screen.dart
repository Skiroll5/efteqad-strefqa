import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/premium_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/data/auth_controller.dart';
import '../../../classes/data/classes_controller.dart';

import '../../../../core/components/upcoming_birthdays_section.dart';
import '../../../../core/components/last_session_card.dart';
import '../../../../core/components/global_at_risk_widget.dart';
import '../../../statistics/data/statistics_repository.dart';
import '../../../students/data/students_controller.dart';
import '../../../sync/data/sync_service.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/features/home/data/home_insights_repository.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).asData?.value;
    final classesAsync = ref.watch(classesStreamProvider);
    // Ensure SyncService is alive and syncing
    ref.watch(syncServiceProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

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
                text: '${l10n?.hi ?? 'Hi'}, ',
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
                  color: isDark ? AppColors.goldPrimary : AppColors.goldDark,
                ),
              ),
              const TextSpan(text: ' 👋'),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n?.settings ?? 'Settings',
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

          if (classes.isEmpty && user?.role != 'ADMIN') {
            // Only show empty state if not admin (admin might have dashboard but no classes yet)
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
                        ? (l10n?.noClassesYet ?? 'No classes yet')
                        : (l10n?.noClassAssigned ?? 'No class assigned'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ).animate().fade(delay: 200.ms),
                  if (user?.role == 'ADMIN') ...[const SizedBox(height: 16)],
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Insights Section
              // Admin Panel Entry Point
              if (user?.role == 'ADMIN') ...[
                PremiumCard(
                  margin: EdgeInsets.zero,
                  child: InkWell(
                    onTap: () => context.push('/admin'),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [
                                        AppColors.goldPrimary,
                                        AppColors.goldDark,
                                      ]
                                    : [
                                        AppColors.goldPrimary,
                                        AppColors.goldLight,
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Admin Panel',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Manage users, classes & data',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward,
                            color: isDark
                                ? AppColors.goldPrimary
                                : AppColors.goldDark,
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fade().slideY(begin: -0.2, end: 0),
                const SizedBox(height: 24),

                const _InsightsSection(),
                const SizedBox(height: 24),
              ],

              if (classes.isNotEmpty || user?.role == 'ADMIN') ...[
                Row(
                  children: [
                    Text(
                      user?.role == 'ADMIN'
                          ? (l10n?.yourClasses ?? 'Your Classes')
                          : (l10n?.yourClass ?? 'Your Class'),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const Spacer(),
                    if (user?.role == 'ADMIN')
                      Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showAddClassDialog(context, ref),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.goldPrimary.withValues(
                                          alpha: 0.1,
                                        )
                                      : AppColors.goldPrimary.withValues(
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
                                      l10n?.createClass ?? 'Create Class',
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
                          .fade(delay: 300.ms)
                          .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
                  ],
                ).animate().fade(),
                const SizedBox(height: 4),
                Text(
                  l10n?.selectClassToManage ??
                      'Select a class to manage students and attendance',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ).animate().fade(delay: 100.ms),
                const SizedBox(height: 20),

                // Classes List
                ...classes.map((cls) {
                  return PremiumCard(
                    key: ValueKey(cls.id),
                    margin: const EdgeInsets.only(bottom: 12),
                    onTap: () {
                      ref.read(selectedClassIdProvider.notifier).state = cls.id;
                      context.push('/students');
                    },
                    child: Row(
                      children: [
                        // Class Icon
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [
                                      AppColors.goldPrimary.withValues(
                                        alpha: 0.3,
                                      ),
                                      AppColors.goldDark.withValues(alpha: 0.2),
                                    ]
                                  : [
                                      AppColors.goldPrimary.withValues(
                                        alpha: 0.15,
                                      ),
                                      AppColors.goldLight.withValues(
                                        alpha: 0.1,
                                      ),
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
                                : AppColors
                                      .goldDark, // goldDark for contrast on light
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cls.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                              if (cls.grade != null && cls.grade!.isNotEmpty)
                                Text(
                                  cls.grade!,
                                  style: theme.textTheme.bodySmall?.copyWith(
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
                              PopupMenuItem(
                                value: 'rename',
                                child: Row(
                                  children: [
                                    const Icon(Icons.edit, size: 20),
                                    const SizedBox(width: 8),
                                    Text(l10n?.rename ?? 'Rename'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      size: 20,
                                      color: isDark
                                          ? AppColors.redLight
                                          : AppColors.redPrimary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      l10n?.delete ?? 'Delete',
                                      style: TextStyle(
                                        color: isDark
                                            ? AppColors.redLight
                                            : AppColors.redPrimary,
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
                              size: 18,
                              color: isDark
                                  ? AppColors.goldPrimary
                                  : AppColors.goldPrimary,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ],
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
              // Drag Handle
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
              // Title
              Text(
                l10n?.createNewClass ?? 'Create New Class',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n?.addClassCaption ?? 'Add a new class to manage students',
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
                  labelText: l10n?.className ?? 'Class Name',
                  hintText:
                      l10n?.classNameHint ?? 'e.g. Sunday School - Grade 3',
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
                          : AppColors.goldPrimary, // Unified Gold
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
                  labelText: l10n?.gradeOptional ?? 'Grade (optional)',
                  hintText: l10n?.gradeHint ?? 'e.g. Grade 3',
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
                          : AppColors.goldPrimary, // Unified Gold
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
                      child: Text(l10n?.cancel ?? 'Cancel'),
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
                        backgroundColor: AppColors.goldPrimary,
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
                    color: isDark
                        ? AppColors.dragHandleDark
                        : AppColors.dragHandleLight,
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
                        : AppColors.goldPrimary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.goldPrimary
                          : AppColors.goldPrimary, // Unified Gold
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
                            : AppColors.goldPrimary,
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
              // Warning Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.redPrimary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_forever,
                  color: isDark ? AppColors.redLight : AppColors.redPrimary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                'Delete "${cls.name}"?',
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

class _InsightsSection extends ConsumerWidget {
  const _InsightsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final atRiskAsync = ref.watch(atRiskStudentsProvider);
    final classesSessionsAsync = ref.watch(classesLatestSessionsProvider);
    final allStudentsAsync = ref.watch(studentsStreamProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Class Awareness (Latest Sessions)
        classesSessionsAsync.when(
          data: (sessions) {
            final activeSessions = sessions.where((s) => s.hasSession).toList();
            if (activeSessions.isEmpty) return const SizedBox.shrink();

            return Container(
              height: 160,
              margin: const EdgeInsets.only(bottom: 24),
              child: PageView.builder(
                controller: PageController(viewportFraction: 0.92),
                padEnds: false,
                itemCount: activeSessions.length,
                itemBuilder: (context, index) {
                  final session = activeSessions[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: LastSessionCard(sessionStatus: session),
                  );
                },
              ),
            );
          },
          loading: () => const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // 2. Global At Risk
        atRiskAsync.when(
          data: (students) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: GlobalAtRiskWidget(
                atRiskStudents: students,
                isDark: isDark,
              ),
            );
          },
          loading: () => const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // 3. Upcoming Birthdays
        allStudentsAsync.when(
          data: (students) {
            if (students.isEmpty) return const SizedBox.shrink();
            return UpcomingBirthdaysSection(students: students, isDark: isDark);
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}
