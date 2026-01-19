import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/components/premium_card.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/admin/data/admin_controller.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ClassManagerAssignmentScreen extends ConsumerStatefulWidget {
  final String classId;
  final String className;

  const ClassManagerAssignmentScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  ConsumerState<ClassManagerAssignmentScreen> createState() =>
      _ClassManagerAssignmentScreenState();
}

class _ClassManagerAssignmentScreenState
    extends ConsumerState<ClassManagerAssignmentScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final managersAsync = ref.watch(classManagersProvider(widget.classId));
    final allUsersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(l10n.managersForClass(widget.className)),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppColors.backgroundDark, AppColors.surfaceDark]
                : [AppColors.backgroundLight, Colors.white],
          ),
        ),
        child: managersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) =>
              Center(child: Text(l10n.errorGeneric(e.toString()))),
          data: (managers) {
            return allUsersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) =>
                  Center(child: Text(l10n.errorGeneric(e.toString()))),
              data: (allUsers) {
                // Server returns ClassManager with nested user, extract userId
                final managerIds = managers
                    .map((m) => m['userId'] ?? m['id'])
                    .toSet();

                // 1. Current Managers
                final currentManagers = managers;

                // 2. Available Users (Enabled, Not Deleted, Not Admin, Not already manager)
                final availableUsers = allUsers.where((u) {
                  return !managerIds.contains(u['id']) &&
                      u['role'] != 'ADMIN' &&
                      u['isEnabled'] == true &&
                      u['isDeleted'] != true;
                }).toList();

                // Sort available users by name
                availableUsers.sort((a, b) {
                  final nameA = (a['name'] as String?) ?? '';
                  final nameB = (b['name'] as String?) ?? '';
                  return nameA.compareTo(nameB);
                });

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(classManagersProvider(widget.classId));
                    ref.invalidate(allUsersProvider);
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Current Managers Section
                      _SectionHeader(
                        title: l10n.currentManagers,
                        icon: Icons.manage_accounts,
                        isDark: isDark,
                        count: currentManagers.length,
                      ),
                      const SizedBox(height: 12),
                      if (currentManagers.isEmpty)
                        _EmptySection(
                          text: l10n.noManagersAssigned,
                          icon: Icons.person_off_outlined,
                          isDark: isDark,
                        )
                      else
                        ...currentManagers.asMap().entries.map((entry) {
                          return _ManagerCard(
                            user: entry.value,
                            isManager: true,
                            classId: widget.classId,
                            l10n: l10n,
                            isDark: isDark,
                            index: entry.key,
                          );
                        }),

                      const SizedBox(height: 32),

                      // Separator
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    isDark ? Colors.white24 : Colors.black12,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Icon(
                              Icons.add_circle_outline,
                              color: isDark ? Colors.white38 : Colors.black26,
                              size: 20,
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    isDark ? Colors.white24 : Colors.black12,
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Available Users Section
                      _SectionHeader(
                        title: l10n.availableUsers,
                        icon: Icons.person_add_alt_1,
                        isDark: isDark,
                        count: availableUsers.length,
                      ),
                      const SizedBox(height: 12),
                      if (availableUsers.isEmpty)
                        _EmptySection(
                          text: l10n.noUsersFound,
                          icon: Icons.people_outline,
                          isDark: isDark,
                        )
                      else
                        ...availableUsers.asMap().entries.map((entry) {
                          return _ManagerCard(
                            user: entry.value,
                            isManager: false,
                            classId: widget.classId,
                            l10n: l10n,
                            isDark: isDark,
                            index: entry.key,
                          );
                        }),
                      const SizedBox(height: 40),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;
  final int count;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.isDark,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.goldPrimary.withOpacity(0.15)
                : AppColors.goldPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.goldPrimary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool isDark;

  const _EmptySection({
    required this.text,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: isDark ? Colors.white24 : Colors.black26),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black45,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _ManagerCard extends ConsumerWidget {
  final Map<String, dynamic> user;
  final bool isManager;
  final String classId;
  final AppLocalizations l10n;
  final bool isDark;
  final int index;

  const _ManagerCard({
    required this.user,
    required this.isManager,
    required this.classId,
    required this.l10n,
    required this.isDark,
    required this.index,
  });

  // Handle both flat user structure and nested user structure from ClassManager
  Map<String, dynamic>? get _userData =>
      user['user'] as Map<String, dynamic>? ?? user;
  String get userName => (_userData?['name'] as String?) ?? l10n.unknown;
  String get userEmail => (_userData?['email'] as String?) ?? '';
  String get userId =>
      (user['userId'] as String?) ?? (_userData?['id'] as String?) ?? '';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child:
          PremiumCard(
                color: isManager
                    ? (isDark
                          ? Colors.green.withOpacity(0.08)
                          : Colors.green.withOpacity(0.05))
                    : null,
                child: InkWell(
                  onTap: () => _handleTap(context, ref),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: isManager
                                ? AppColors.goldGradient
                                : LinearGradient(
                                    colors: isDark
                                        ? [
                                            Colors.grey.shade700,
                                            Colors.grey.shade800,
                                          ]
                                        : [
                                            Colors.grey.shade200,
                                            Colors.grey.shade300,
                                          ],
                                  ),
                            shape: BoxShape.circle,
                            boxShadow: isManager
                                ? [
                                    BoxShadow(
                                      color: AppColors.goldPrimary.withOpacity(
                                        0.3,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              userName.isNotEmpty
                                  ? userName.substring(0, 1).toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: isManager
                                    ? Colors.white
                                    : (isDark
                                          ? Colors.white70
                                          : Colors.black54),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // User Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimaryLight,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (userEmail.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  userEmail,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Action Button
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isManager
                                ? AppColors.redPrimary.withOpacity(0.1)
                                : AppColors.goldPrimary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isManager
                                ? Icons.person_remove_rounded
                                : Icons.person_add_rounded,
                            color: isManager
                                ? AppColors.redPrimary
                                : AppColors.goldPrimary,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .animate()
              .fade(duration: const Duration(milliseconds: 300))
              .slideX(begin: 0.05, delay: Duration(milliseconds: index * 40)),
    );
  }

  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
    final displayName = userName;

    // Show quick feedback
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isManager
              ? l10n.removingManager(displayName)
              : l10n.addingManager(displayName),
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    if (isManager) {
      await ref
          .read(adminControllerProvider.notifier)
          .removeClassManager(classId, userId);
    } else {
      await ref
          .read(adminControllerProvider.notifier)
          .assignClassManager(classId, userId);
    }
  }
}
