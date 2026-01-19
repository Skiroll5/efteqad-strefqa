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
import 'package:mobile/features/home/data/home_insights_repository.dart';
import '../../../classes/presentation/widgets/class_list_item.dart';
import '../../../classes/presentation/widgets/class_dialogs.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).asData?.value;
    // Use userClassesStreamProvider which returns classes based on user role
    final classesAsync = ref.watch(userClassesStreamProvider);
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
        data: (classes) {
          // The userClassesStreamProvider already filters based on user role
          // Admin sees all, Servant sees only assigned classes

          if (classes.isEmpty && user?.role != 'ADMIN') {
            // Non-admin with no assigned classes
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
                    l10n?.noClassAssigned ?? 'No class assigned',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ).animate().fade(delay: 200.ms),
                  const SizedBox(height: 8),
                  Text(
                    l10n?.contactAdminForActivation ??
                        'Please contact the administrator to be assigned to a class',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fade(delay: 300.ms),
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
                                  l10n?.adminPanel ?? 'Admin Panel',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n?.adminPanelDesc ??
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
                              onTap: () => showAddClassDialog(context, ref),
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
                  return ClassListItem(
                    key: ValueKey(cls.id),
                    cls: cls,
                    isAdmin: user?.role == 'ADMIN',
                    isDark: isDark,
                    onTap: () {
                      ref.read(selectedClassIdProvider.notifier).state = cls.id;
                      context.push('/students');
                    },
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
