import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/components/premium_card.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/admin/data/admin_controller.dart';
import 'package:mobile/features/classes/presentation/widgets/class_list_item.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageClassManagers),
        subtitle: Text(widget.className, style: const TextStyle(fontSize: 14)),
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
          error: (e, st) => Center(child: Text(l10n.errorGeneric(e.toString()))),
          data: (managers) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _HeaderSection(
                  className: widget.className,
                  managerCount: managers.length,
                  l10n: l10n,
                  isDark: isDark,
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.currentManagers,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => _showAddManagerDialog(context, ref, widget.classId, l10n),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l10n.addManager),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.goldPrimary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (managers.isEmpty)
                  _EmptyState(l10n: l10n, isDark: isDark)
                else
                  ...managers.map((manager) => _ManagerCard(
                        manager: manager,
                        classId: widget.classId,
                        l10n: l10n,
                        isDark: isDark,
                      )),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _showAddManagerDialog(
    BuildContext context,
    WidgetRef ref,
    String classId,
    AppLocalizations l10n,
  ) async {
    showDialog(
      context: context,
      builder: (ctx) => _AddManagerDialog(classId: classId),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final String className;
  final int managerCount;
  final AppLocalizations l10n;
  final bool isDark;

  const _HeaderSection({
    required this.className,
    required this.managerCount,
    required this.l10n,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.manage_accounts,
              size: 48,
              color: isDark ? AppColors.goldPrimary : AppColors.goldDark,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.classManagersDescription(className),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppLocalizations l10n;
  final bool isDark;

  const _EmptyState({required this.l10n, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: isDark ? Colors.white24 : Colors.black12,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noManagersAssigned,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManagerCard extends ConsumerWidget {
  final Map<String, dynamic> manager;
  final String classId;
  final AppLocalizations l10n;
  final bool isDark;

  const _ManagerCard({
    required this.manager,
    required this.classId,
    required this.l10n,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.goldPrimary.withValues(alpha: 0.2),
            child: Text(
              (manager['name'] as String).substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: AppColors.goldPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            manager['name'],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(manager['email'] ?? ''),
          trailing: IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: AppColors.redPrimary),
            onPressed: () => _confirmRemove(context, ref),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.removeManagerTitle),
        content: Text(l10n.removeManagerConfirm(manager['name'])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.redPrimary),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await ref
          .read(adminControllerProvider.notifier)
          .removeClassManager(classId, manager['id']);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? l10n.managerRemoved : l10n.errorGeneric('Failed')),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}

class _AddManagerDialog extends ConsumerStatefulWidget {
  final String classId;

  const _AddManagerDialog({required this.classId});

  @override
  ConsumerState<_AddManagerDialog> createState() => _AddManagerDialogState();
}

class _AddManagerDialogState extends ConsumerState<_AddManagerDialog> {
  String? _selectedUserId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final allUsersAsync = ref.watch(allUsersProvider);
    final currentManagersAsync = ref.watch(
      classManagersProvider(widget.classId),
    );

    return AlertDialog(
      title: Text(l10n.addManager),
      content: allUsersAsync.when(
        data: (allUsers) {
          return currentManagersAsync.when(
            data: (managers) {
              final managerIds = managers.map((m) => m['id']).toSet();
              // Filter out admins and existing managers
              final eligibleUsers =
                  allUsers
                      .where(
                        (u) =>
                            !managerIds.contains(u['id']) &&
                            u['role'] != 'ADMIN' &&
                            u['isActive'] == true &&
                            u['isDeleted'] == false,
                      )
                      .toList();

              if (eligibleUsers.isEmpty) {
                return Text(l10n.allUsersAreManagers);
              }

              return DropdownButtonFormField<String>(
                value: _selectedUserId,
                hint: Text(l10n.selectClassToManage), // "Select..."
                isExpanded: true,
                items:
                    eligibleUsers.map((user) {
                      return DropdownMenuItem(
                        value: user['id'] as String,
                        child: Text(user['name']),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedUserId = value;
                  });
                },
              );
            },
            loading:
                () => const SizedBox(
                  height: 50,
                  child: Center(child: CircularProgressIndicator()),
                ),
            error: (e, _) => Text(l10n.errorGeneric(e.toString())),
          );
        },
        loading:
            () => const SizedBox(
              height: 50,
              child: Center(child: CircularProgressIndicator()),
            ),
        error: (e, _) => Text(l10n.errorGeneric(e.toString())),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed:
              _selectedUserId == null
                  ? null
                  : () async {
                    final success = await ref
                        .read(adminControllerProvider.notifier)
                        .assignClassManager(widget.classId, _selectedUserId!);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? l10n.managerAdded('') // Placeholder
                                : l10n.managerAddFailed,
                          ),
                          backgroundColor:
                              success ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  },
          style: FilledButton.styleFrom(backgroundColor: AppColors.goldPrimary),
          child: Text(l10n.add),
        ),
      ],
    );
  }
}
