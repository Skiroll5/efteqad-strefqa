import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/premium_card.dart';
import '../../data/admin_controller.dart';
import 'package:mobile/l10n/app_localizations.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(l10n.userManagement),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
          unselectedLabelStyle: Theme.of(context).textTheme.labelLarge,
          tabs: [
            Tab(
              text: l10n.pendingActivation,
              icon: const Icon(Icons.pending_actions),
            ),
            Tab(text: l10n.allUsers, icon: const Icon(Icons.people)),
            Tab(text: l10n.abortedActivations, icon: const Icon(Icons.block)),
          ],
        ),
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
        child: TabBarView(
          controller: _tabController,
          children: const [
            _PendingUsersTab(),
            _AllUsersTab(),
            _AbortedUsersTab(),
          ],
        ),
      ),
    );
  }
}

class _PendingUsersTab extends ConsumerWidget {
  const _PendingUsersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingUsers = ref.watch(pendingUsersProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return pendingUsers.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l10n.errorGeneric(e.toString()))),
      data: (users) {
        if (users.isEmpty) {
          return _EmptyState(
            icon: Icons.check_circle,
            iconColor: Colors.green,
            message: l10n.noPendingUsers,
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(pendingUsersProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return _UserCard(
                    user: user,
                    isDark: isDark,
                    delay: index * 0.1,
                    actions: [
                      _ActionButton(
                        icon: Icons.check,
                        label: l10n.activate,
                        color: Colors.green,
                        onPressed: () =>
                            _activateUser(context, ref, user['id'], l10n),
                      ),
                      _ActionButton(
                        icon: Icons.close,
                        label: l10n.abortActivation,
                        color: AppColors.redPrimary,
                        onPressed: () =>
                            _showAbortConfirmation(context, ref, user, l10n),
                      ),
                    ],
                  )
                  .animate()
                  .fade(delay: Duration(milliseconds: (index * 100)))
                  .slideX(begin: 0.1);
            },
          ),
        );
      },
    );
  }

  Future<void> _activateUser(
    BuildContext context,
    WidgetRef ref,
    String userId,
    AppLocalizations l10n,
  ) async {
    final success = await ref
        .read(adminControllerProvider.notifier)
        .activateUser(userId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? l10n.userActivated : l10n.userActivationFailed,
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _showAbortConfirmation(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> user,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.abortActivation),
        content: Text(l10n.abortActivationConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.redPrimary,
            ),
            child: Text(l10n.abortActivation),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await ref
          .read(adminControllerProvider.notifier)
          .abortActivation(user['id']);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? l10n.userActivationAborted : l10n.errorUpdateUser,
            ),
            backgroundColor: success ? Colors.orange : Colors.red,
          ),
        );
      }
    }
  }
}

class _AllUsersTab extends ConsumerWidget {
  const _AllUsersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allUsers = ref.watch(allUsersProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return allUsers.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l10n.errorGeneric(e.toString()))),
      data: (users) {
        if (users.isEmpty) {
          return _EmptyState(
            icon: Icons.people_outline,
            iconColor: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
            message: l10n.noUsersFound,
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(allUsersProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return _UserManagementItem(
                key: ValueKey(user['id']),
                user: user,
                isDark: isDark,
                index: index,
              );
            },
          ),
        );
      },
    );
  }
}

class _AbortedUsersTab extends ConsumerWidget {
  const _AbortedUsersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final abortedUsers = ref.watch(abortedUsersProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return abortedUsers.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l10n.errorGeneric(e.toString()))),
      data: (users) {
        if (users.isEmpty) {
          return _EmptyState(
            icon: Icons.block,
            iconColor: Colors.red,
            message: l10n.noAbortedUsers,
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(abortedUsersProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return _UserCard(
                    user: user,
                    isDark: isDark,
                    delay: index * 0.1,
                    actions: [
                      _ActionButton(
                        icon: Icons.refresh,
                        label: l10n.reactivate,
                        color: Colors.orange,
                        onPressed: () =>
                            _reactivateUser(context, ref, user['id'], l10n),
                      ),
                    ],
                  )
                  .animate()
                  .fade(delay: Duration(milliseconds: (index * 100)))
                  .slideX(begin: 0.1);
            },
          ),
        );
      },
    );
  }

  Future<void> _reactivateUser(
    BuildContext context,
    WidgetRef ref,
    String userId,
    AppLocalizations l10n,
  ) async {
    final success = await ref
        .read(adminControllerProvider.notifier)
        .activateUser(userId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? l10n.userActivated : l10n.userActivationFailed,
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}

class _UserManagementItem extends ConsumerStatefulWidget {
  final Map<String, dynamic> user;
  final bool isDark;
  final int index;

  const _UserManagementItem({
    super.key,
    required this.user,
    required this.isDark,
    required this.index,
  });

  @override
  ConsumerState<_UserManagementItem> createState() =>
      _UserManagementItemState();
}

class _UserManagementItemState extends ConsumerState<_UserManagementItem> {
  // Optimistic state for the switch
  late bool _isEnabled;

  @override
  void initState() {
    super.initState();
    _isEnabled = widget.user['isEnabled'] == true;
  }

  @override
  void didUpdateWidget(covariant _UserManagementItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user['isEnabled'] != widget.user['isEnabled']) {
      _isEnabled = widget.user['isEnabled'] == true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isActive = widget.user['isActive'] == true;
    final isAdmin = widget.user['role'] == 'ADMIN';
    final activationDenied = widget.user['activationDenied'] == true;

    return _UserCard(
          user: widget.user,
          isDark: widget.isDark,
          delay: widget.index * 0.1,
          showStatusBadge: true,
          isActive: isActive,
          isEnabled: _isEnabled,
          isAdmin: isAdmin,
          actions: isAdmin
              ? []
              : isActive
                  ? [
                      // Active users: Enable/Disable toggle and Delete
                      _SwitchAction(
                        value: _isEnabled,
                        label: _isEnabled ? l10n.enabled : l10n.disabled,
                        onChanged: (val) async {
                          setState(() {
                            _isEnabled = val;
                          });

                          final success = val
                              ? await ref
                                    .read(adminControllerProvider.notifier)
                                    .enableUser(widget.user['id'])
                              : await ref
                                    .read(adminControllerProvider.notifier)
                                    .disableUser(widget.user['id']);

                          if (!success && context.mounted) {
                            setState(() {
                              _isEnabled = !val;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.errorUpdateUser),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                      _ActionButton(
                        icon: Icons.delete,
                        label: l10n.deleteUser,
                        color: Colors.grey,
                        onPressed: () => _showDeleteConfirmation(
                          context,
                          ref,
                          widget.user,
                          l10n,
                        ),
                      ),
                    ]
                  : activationDenied
                      ? [
                          // Denied users: Reactivate option
                          _ActionButton(
                            icon: Icons.refresh,
                            label: l10n.reactivate,
                            color: Colors.orange,
                            onPressed: () => _activateUser(context, ref, l10n),
                          ),
                          _ActionButton(
                            icon: Icons.delete,
                            label: l10n.deleteUser,
                            color: Colors.grey,
                            onPressed: () => _showDeleteConfirmation(
                              context,
                              ref,
                              widget.user,
                              l10n,
                            ),
                          ),
                        ]
                      : [
                          // Pending users: Activate or Reject
                          _ActionButton(
                            icon: Icons.check,
                            label: l10n.activate,
                            color: Colors.green,
                            onPressed: () => _activateUser(context, ref, l10n),
                          ),
                          _ActionButton(
                            icon: Icons.close,
                            label: l10n.abortActivation,
                            color: AppColors.redPrimary,
                            onPressed: () => _showAbortConfirmation(
                              context,
                              ref,
                              widget.user,
                              l10n,
                            ),
                          ),
                        ],
        )
        .animate()
        .fade(delay: Duration(milliseconds: (widget.index * 100)))
        .slideX(begin: 0.1);
  }

  Future<void> _activateUser(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final success = await ref
        .read(adminControllerProvider.notifier)
        .activateUser(widget.user['id']);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? l10n.userActivated : l10n.userActivationFailed,
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _showAbortConfirmation(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> user,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.abortActivation),
        content: Text(l10n.abortActivationConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.redPrimary,
            ),
            child: Text(l10n.abortActivation),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await ref
          .read(adminControllerProvider.notifier)
          .abortActivation(user['id']);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? l10n.userActivationAborted : l10n.errorUpdateUser,
            ),
            backgroundColor: success ? Colors.orange : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> user,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteUser),
        content: Text(l10n.deleteUserConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.redPrimary,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await ref
          .read(adminControllerProvider.notifier)
          .deleteUser(user['id']);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? l10n.userDeleted : l10n.errorUpdateUser),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}

// ===== Reusable Widgets =====

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.iconColor,
    required this.message,
  });

  final IconData icon;
  final Color iconColor;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: iconColor),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(fontSize: 18)),
        ],
      ).animate().fade().scale(begin: const Offset(0.9, 0.9)),
    );
  }
}

class _SwitchAction extends StatelessWidget {
  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  const _SwitchAction({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Custom Toggle Switch
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            width: 52,
            height: 28,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: value
                  ? LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade600],
                    )
                  : null,
              color: value
                  ? null
                  : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: value
                      ? Colors.green.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    value ? Icons.check : Icons.close,
                    size: 14,
                    color: value ? Colors.green.shade600 : Colors.grey.shade500,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Label
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: value
                  ? (isDark ? Colors.green.shade300 : Colors.green.shade700)
                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.isDark,
    required this.delay,
    required this.actions,
    this.showStatusBadge = false,
    this.isActive = false,
    this.isEnabled = true,
    this.isAdmin = false,
  });

  final Map<String, dynamic> user;
  final bool isDark;
  final double delay;
  final List<Widget> actions;
  final bool showStatusBadge;
  final bool isActive;
  final bool isEnabled;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        delay: delay,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isAdmin
                        ? AppColors.goldPrimary.withValues(alpha: 0.2)
                        : (isEnabled
                              ? Colors.green.withValues(alpha: 0.2)
                              : (isDark
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade300)
                                    .withValues(alpha: 0.2)),
                    child: Icon(
                      isAdmin ? Icons.admin_panel_settings : Icons.person,
                      color: isAdmin
                          ? AppColors.goldPrimary
                          : (isEnabled
                                ? Colors.green
                                : (isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                user['name'] ?? 'Unknown',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
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
                                  gradient: AppColors.goldGradient,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  l10n.admin,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user['email'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showStatusBadge && !isAdmin)
                    _StatusBadge(
                      isActive: isActive,
                      isEnabled: isEnabled,
                      isDark: isDark,
                    ),
                ],
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: actions),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.isActive,
    required this.isEnabled,
    required this.isDark,
  });

  final bool isActive;
  final bool isEnabled;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    Color bgColor;
    String text;

    if (!isEnabled) {
      bgColor = AppColors.redPrimary;
      text = l10n.disabled;
    } else if (isActive) {
      bgColor = Colors.green;
      text = l10n.active;
    } else {
      bgColor = Colors.orange;
      text = l10n.pending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bgColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: bgColor,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
