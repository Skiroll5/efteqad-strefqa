import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile/features/admin/data/admin_controller.dart';
import 'package:mobile/features/admin/presentation/screens/class_management_screen.dart';
import 'package:mobile/features/admin/presentation/screens/class_manager_assignment_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/premium_card.dart';
import '../../../../core/database/app_database.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/data/auth_controller.dart';
import '../../../classes/presentation/widgets/class_list_item.dart';
import '../../../classes/presentation/widgets/class_dialogs.dart';
import '../../../sync/data/sync_service.dart';

class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger sync on admin panel load to ensure fresh data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncServiceProvider).pullChanges();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.asData?.value;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    // Check if user is admin
    if (user?.role != 'ADMIN') {
      return Scaffold(
        appBar: AppBar(title: Text(l10n?.accessDenied ?? 'Access Denied')),
        body: Center(
          child: Text(
            l10n?.noAdminPrivileges ?? 'You do not have admin privileges.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.adminPanel ?? 'Admin Panel'),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Class Management Section
          _ClassesSection(isDark: isDark),

          const SizedBox(height: 24),

          // 2. User Management Section
          _UsersSection(isDark: isDark),
        ],
      ),
    );
  }
}

class _ClassesSection extends ConsumerWidget {
  final bool isDark;

  const _ClassesSection({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final classesAsync = ref.watch(adminClassesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n?.classes ?? 'Classes',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
              ),
            ),
            IconButton.filled(
              onPressed: () async {
                await showAddClassDialog(context, ref);
                ref.invalidate(adminClassesProvider);
              },
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.goldPrimary
                    : AppColors.goldPrimary,
                foregroundColor: isDark ? Colors.black : Colors.white,
              ),
              tooltip: l10n?.addClass ?? 'Add Class',
            ),
          ],
        ),
        const SizedBox(height: 8),
        classesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(l10n?.errorGeneric(e.toString()) ?? "Error: $e"),
          ),
          data: (classes) {
            if (classes.isEmpty) {
              return PremiumCard(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.class_outlined,
                          size: 48,
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n?.noClassesFoundAdd ??
                              'No classes found. Add one!',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: classes.map((classData) {
                // Manually construct ClassesData from Map since Admin logic uses Map
                final cls = ClassesData(
                  id: classData['id'] as String? ?? '',
                  name: classData['name'] as String? ?? 'Unknown',
                  grade: classData['grade'] as String?,
                  createdAt: DateTime.now(), // Dummy for display
                  updatedAt: DateTime.now(), // Dummy for display
                  isDeleted: false,
                );

                return ClassListItem(
                  key: ValueKey(cls.id),
                  cls: cls,
                  isAdmin: true, // User is Admin in this screen
                  isDark: isDark,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ClassManagerAssignmentScreen(
                          classId: cls.id,
                          className: cls.name,
                        ),
                      ),
                    );
                  },
                  onRefresh: () => ref.invalidate(adminClassesProvider),
                );
              }).toList(),
            );
          },
        ),
      ],
    ).animate().fade();
  }
}

class _UsersSection extends ConsumerWidget {
  final bool isDark;

  const _UsersSection({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // We fetch separate providers for pending and all users
    final pendingUsersAsync = ref.watch(pendingUsersProvider);
    final allUsersAsync = ref.watch(allUsersProvider);
    final adminController = ref.watch(adminControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.userManagement ?? 'User Management',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 8),

        // Pending Users Sub-section
        Consumer(
          builder: (context, ref, _) {
            return pendingUsersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  const SizedBox.shrink(), // Don't show error here to avoid clutter
              data: (users) {
                if (users.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        l10n?.pendingActivation ?? 'Pending Activation',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.goldPrimary
                              : AppColors.goldDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: isDark
                              ? AppColors.goldPrimary.withValues(alpha: 0.1)
                              : Colors.orange.shade50,
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person_outline),
                            ),
                            title: Text(user['name'] ?? 'Unknown'),
                            subtitle: Text(user['email'] ?? ''),
                            trailing: FilledButton.icon(
                              icon: const Icon(Icons.check, size: 16),
                              label: Text(l10n?.activate ?? 'Activate'),
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () async {
                                final success = await adminController
                                    .activateUser(user['id']);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        success
                                            ? (l10n?.userActivated ??
                                                  'User activated!')
                                            : (l10n?.userActivationFailed ??
                                                  'Failed to activate'),
                                      ),
                                      backgroundColor: success
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            );
          },
        ),

        // All Users Sub-section
        Text(
          l10n?.allUsers ?? 'All Users',
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),

        allUsersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(l10n?.errorGeneric(e.toString()) ?? "Error: $e"),
          ),
          data: (users) {
            if (users.isEmpty) {
              return Center(
                child: Text(l10n?.noUsersFound ?? 'No users found'),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final isActive = user['isActive'] == true;
                final isAdmin = user['role'] == 'ADMIN';

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isAdmin
                          ? Colors.amber.shade100
                          : (isActive
                                ? Colors.green.shade100
                                : Colors.grey.shade200),
                      child: Icon(
                        isAdmin ? Icons.admin_panel_settings : Icons.person,
                        color: isAdmin
                            ? Colors.amber.shade700
                            : (isActive ? Colors.green : Colors.grey),
                        size: 20,
                      ),
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            user['name'] ?? 'Unknown',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isAdmin) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              l10n?.admin ?? 'Admin',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(user['email'] ?? ''),
                    trailing: isAdmin
                        ? null // Don't allow modifying admin users
                        : Switch(
                            value: isActive,
                            onChanged: (value) async {
                              final success = value
                                  ? await adminController.enableUser(user['id'])
                                  : await adminController.disableUser(
                                      user['id'],
                                    );
                              if (context.mounted && !success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      l10n?.errorUpdateUser ??
                                          'Failed to update user',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                          ),
                  ),
                );
              },
            );
          },
        ),
      ],
    ).animate().fade(delay: 100.ms);
  }
}
