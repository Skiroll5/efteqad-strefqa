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

/// Provider for optimistic class order - shared between HomeScreen and InsightsSection
final optimisticClassOrderProvider = StateProvider<List<String>?>(
  (ref) => null,
);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _hasAutoNavigated = false;

  @override
  void initState() {
    super.initState();
    // Trigger a pull on home load to ensure data is fresh,
    // especially for new users who just got assigned a class.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncServiceProvider).pullChanges();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).asData?.value;
    // Watch raw classes stream and order separately to handle optimistic updates
    final classesAsync = ref.watch(userClassesStreamProvider);
    final orderAsync = ref.watch(classOrderProvider);

    // Ensure SyncService is alive
    ref.watch(syncServiceProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    // Get first name for greeting
    final fallbackName = l10n?.user ?? 'User';
    final rawName = user?.name.split(' ').first ?? fallbackName;
    final firstName = rawName.isNotEmpty
        ? rawName[0].toUpperCase() + rawName.substring(1).toLowerCase()
        : fallbackName;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
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
          // Auto-redirect for single-class managers (non-admins)
          // If user has exactly 1 class and hasn't been redirected yet, go directly to students
          if (!_hasAutoNavigated &&
              classes.length == 1 &&
              user?.role != 'ADMIN') {
            _hasAutoNavigated = true;
            // Navigate synchronously in the next microtask to avoid visible flash
            Future.microtask(() {
              ref.read(selectedClassIdProvider.notifier).state =
                  classes.first.id;
              context.go('/students');
            });
            // Return blank scaffold (not spinner) for seamless transition
            return const SizedBox.shrink();
          }

          if (classes.isEmpty && user?.role != 'ADMIN') {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated illustration container
                    Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isDark
                                  ? [
                                      AppColors.goldPrimary.withValues(
                                        alpha: 0.15,
                                      ),
                                      AppColors.goldPrimary.withValues(
                                        alpha: 0.05,
                                      ),
                                    ]
                                  : [
                                      AppColors.goldPrimary.withValues(
                                        alpha: 0.1,
                                      ),
                                      Colors.orange.shade50,
                                    ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.school_rounded,
                            size: 56,
                            color: AppColors.goldPrimary,
                          ),
                        )
                        .animate()
                        .scale(duration: 500.ms, curve: Curves.easeOutBack)
                        .then()
                        .shimmer(
                          duration: 1500.ms,
                          color: AppColors.goldPrimary.withValues(alpha: 0.3),
                        ),
                    const SizedBox(height: 32),
                    // Title
                    Text(
                      l10n?.noClassAssigned ?? 'No class assigned',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fade(delay: 200.ms).slideY(begin: 0.2),
                    const SizedBox(height: 12),
                    // Description
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        l10n?.contactAdminForActivation ??
                            'Please contact the administrator to be assigned to a class',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: isDark ? Colors.white60 : Colors.black54,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fade(delay: 300.ms).slideY(begin: 0.2),
                    ),
                    const SizedBox(height: 32),
                    // Subtle hint card
                    Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: isDark
                                    ? Colors.white54
                                    : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  l10n?.waitingForClassAssignment ??
                                      'Waiting for class assignment',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fade(delay: 400.ms)
                        .scale(begin: const Offset(0.95, 0.95)),
                  ],
                ),
              ),
            );
          }

          // Apply Sorting
          final optimisticOrder = ref.watch(optimisticClassOrderProvider);
          final order = optimisticOrder ?? orderAsync.value ?? [];
          final sortedClasses = [...classes];

          if (order.isNotEmpty) {
            sortedClasses.sort((a, b) {
              final indexA = order.indexOf(a.id);
              final indexB = order.indexOf(b.id);

              if (indexA == -1 && indexB == -1) return a.name.compareTo(b.name);
              if (indexA == -1) return 1;
              if (indexB == -1) return -1;
              return indexA.compareTo(indexB);
            });
          } else {
            // Default sort by name if no order
            sortedClasses.sort((a, b) => a.name.compareTo(b.name));
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(syncServiceProvider).pullChanges();
            },
            child: ReorderableListView(
              buildDefaultDragHandles: false,
              padding: const EdgeInsets.all(16),
              onReorder: (oldIndex, newIndex) {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }

                // 1. Update optimistic order via provider (shared with InsightsSection)
                final item = sortedClasses.removeAt(oldIndex);
                sortedClasses.insert(newIndex, item);

                final newOrderIds = sortedClasses.map((c) => c.id).toList();
                ref.read(optimisticClassOrderProvider.notifier).state =
                    newOrderIds;

                // 2. Persist to storage
                ref
                    .read(classesControllerProvider)
                    .updateClassOrder(newOrderIds);
              },
              header: Column(
                children: [
                  // Admin Panel Card - only for admins
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
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
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
                                      style: theme.textTheme.bodySmall
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
                  ],

                  // Insights Section - show for ALL users with classes (not just admins)
                  if (classes.isNotEmpty) ...[const _InsightsSection()],

                  if (classes.isNotEmpty || user?.role == 'ADMIN') ...[
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                // Show "Your Classes" for admin or if user has multiple classes
                                (user?.role == 'ADMIN' || classes.length > 1)
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
                                    onTap: () =>
                                        showAddClassDialog(context, ref),
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
                                              ? AppColors.goldPrimary
                                                    .withValues(alpha: 0.2)
                                              : AppColors.goldPrimary
                                                    .withValues(alpha: 0.3),
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
                                ),
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
              children: [
                for (int i = 0; i < sortedClasses.length; i++)
                  ClassListItem(
                    key: ValueKey(sortedClasses[i].id),
                    cls: sortedClasses[i],
                    isAdmin: user?.role == 'ADMIN',
                    isDark: isDark,
                    showDragHandle: true,
                    reorderIndex: i,
                    onTap: () {
                      ref.read(selectedClassIdProvider.notifier).state =
                          sortedClasses[i].id;
                      context.push('/students');
                    },
                  ),
              ],
            ),
          );
        },

        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Text(l10n.errorGeneric(err.toString())),
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
    final optimisticOrder = ref.watch(optimisticClassOrderProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Upcoming Birthdays
        allStudentsAsync.when(
          data: (students) {
            if (students.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: UpcomingBirthdaysSection(
                students: students,
                isDark: isDark,
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // 2. Class Awareness (Latest Sessions)
        classesSessionsAsync.when(
          data: (sessions) {
            var activeSessions = sessions.where((s) => s.hasSession).toList();
            if (activeSessions.isEmpty) return const SizedBox.shrink();

            // Apply optimistic order if available
            if (optimisticOrder != null && optimisticOrder.isNotEmpty) {
              activeSessions.sort((a, b) {
                final indexA = optimisticOrder.indexOf(a.classId);
                final indexB = optimisticOrder.indexOf(b.classId);
                if (indexA == -1 && indexB == -1) return 0;
                if (indexA == -1) return 1;
                if (indexB == -1) return -1;
                return indexA.compareTo(indexB);
              });
            }

            return Container(
              height: 145,
              margin: const EdgeInsets.only(bottom: 24),
              child: ClipRect(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsetsDirectional.only(start: 0, end: 0),
                  itemCount: activeSessions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final session = activeSessions[index];
                    final screenWidth = MediaQuery.of(context).size.width;
                    return SizedBox(
                      width: screenWidth - 32 - 48,
                      child: LastSessionCard(sessionStatus: session),
                    );
                  },
                ),
              ),
            );
          },
          loading: () => Container(
            height: 160,
            margin: const EdgeInsets.only(bottom: 24),
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // 3. Global At Risk
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
          loading: () => Container(
            height: 200,
            margin: const EdgeInsets.only(bottom: 24),
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}
