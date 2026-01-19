import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/admin/data/admin_controller.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_loading_screen.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_error_screen.dart';
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
  Timer? _retryTimer;
  bool _isAutoRetrying = false;
  bool _hasLoadedFreshData = false; // Track if we've loaded fresh data since screen entry

  @override
  void initState() {
    super.initState();
    // CRITICAL: Force fresh data on every screen entry
    // Must use postFrameCallback since ref is not available until after initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _forceRefreshAll();
      _startConnectivityLoop();
    });
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  /// Force invalidate providers to ensure fresh data fetch
  void _forceRefreshAll() {
    ref.invalidate(classManagersProvider(widget.classId));
    ref.invalidate(allUsersProvider);
  }

  /// Start the connectivity check loop for auto-retry
  void _startConnectivityLoop() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;

      final managersState = ref.read(classManagersProvider(widget.classId));
      final allUsersState = ref.read(allUsersProvider);

      // Check if any provider has an error (connection failed)
      final hasError = managersState.hasError || allUsersState.hasError;

      if (hasError && !_isAutoRetrying) {
        // Mark as auto-retrying and refresh
        if (mounted) {
          setState(() => _isAutoRetrying = true);
        }
        _forceRefreshAll();
        // Reset auto-retry state after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() => _isAutoRetrying = false);
          }
        });
      }
    });
  }

  /// Manual refresh triggered by user
  Future<void> _refreshAll() async {
    setState(() => _hasLoadedFreshData = false);
    _forceRefreshAll();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final managersAsync = ref.watch(classManagersProvider(widget.classId));
    final allUsersAsync = ref.watch(allUsersProvider);

    // Track when fresh data has been loaded
    final hasAllData = managersAsync.hasValue && allUsersAsync.hasValue;
    final hasError = managersAsync.hasError || allUsersAsync.hasError;
    final isLoading = managersAsync.isLoading || allUsersAsync.isLoading;

    // Mark fresh data loaded when we successfully get data AFTER an invalidation
    // This ensures we don't show stale cached data
    if (hasAllData && !hasError && !_hasLoadedFreshData && !isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _hasLoadedFreshData = true);
      });
    }

    // Show loading until we've confirmed fresh data is loaded
    // This prevents showing stale cache on first frame
    final showLoading = !_hasLoadedFreshData;
    // Show error only if we have an error AND haven't loaded fresh data
    final showError = hasError && !_hasLoadedFreshData && !isLoading;
    final firstError = managersAsync.error ?? allUsersAsync.error;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: false,
        title: Text(
          l10n.managersForClass(widget.className),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimaryLight,
          ),
        ),
      ),
      body: _buildBody(
        context,
        l10n: l10n,
        isDark: isDark,
        showLoading: showLoading,
        showError: showError,
        firstError: firstError,
        managersAsync: managersAsync,
        allUsersAsync: allUsersAsync,
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required AppLocalizations l10n,
    required bool isDark,
    required bool showLoading,
    required bool showError,
    required Object? firstError,
    required AsyncValue<List<Map<String, dynamic>>> managersAsync,
    required AsyncValue<List<Map<String, dynamic>>> allUsersAsync,
  }) {
    // Full-page Loading State - only until first fresh load
    if (showLoading) {
      return AdminLoadingScreen(
        message: l10n.loadingClassManagers,
        onRetry: _refreshAll,
      );
    }

    // Full-page Error State - only if no fresh data loaded
    if (showError && firstError != null) {
      return AdminErrorScreen(
        error: firstError,
        onRetry: _refreshAll,
        isAutoRetrying: _isAutoRetrying,
      );
    }

    // Content State - show data (keep showing even during background refresh)
    final managers = managersAsync.valueOrNull ?? [];
    final allUsers = allUsersAsync.valueOrNull ?? [];

    // Server returns ClassManager with nested user, extract userId
    final managerIds = managers.map((m) => m['userId'] ?? m['id']).toSet();

    // Available Users (Enabled, Not Deleted, Not Admin, Not already manager)
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
      onRefresh: _refreshAll,
      color: AppColors.goldPrimary,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // Stats Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.star_rounded,
                      label: l10n.currentManagers,
                      count: managers.length,
                      color: AppColors.goldPrimary,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.person_add_rounded,
                      label: l10n.availableUsers,
                      count: availableUsers.length,
                      color: Colors.blue,
                      isDark: isDark,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1),
            ),
          ),

          // Current Managers Section Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _SectionHeader(
                title: l10n.currentManagers,
                icon: Icons.star_rounded,
                isDark: isDark,
                count: managers.length,
                accentColor: AppColors.goldPrimary,
              ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
            ),
          ),

          // Managers List
          if (managers.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _EmptySection(
                  text: l10n.noManagersAssigned,
                  icon: Icons.person_off_outlined,
                  isDark: isDark,
                ).animate().fadeIn(delay: 150.ms, duration: 300.ms),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _ManagerCard(
                      user: managers[index],
                      isManager: true,
                      classId: widget.classId,
                      l10n: l10n,
                      isDark: isDark,
                      index: index,
                      onActionComplete: _forceRefreshAll,
                    )
                        .animate()
                        .fadeIn(
                          delay: Duration(milliseconds: 150 + (index * 40)),
                          duration: 250.ms,
                        )
                        .slideX(begin: -0.03, curve: Curves.easeOut);
                  },
                  childCount: managers.length,
                ),
              ),
            ),

          // Spacer
          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Available Users Section Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _SectionHeader(
                title: l10n.availableUsers,
                icon: Icons.person_add_rounded,
                isDark: isDark,
                count: availableUsers.length,
                accentColor: Colors.blue,
              ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
            ),
          ),

          // Available Users List
          if (availableUsers.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _EmptySection(
                  text: l10n.noUsersFound,
                  icon: Icons.people_outline,
                  isDark: isDark,
                ).animate().fadeIn(delay: 250.ms, duration: 300.ms),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _ManagerCard(
                      user: availableUsers[index],
                      isManager: false,
                      classId: widget.classId,
                      l10n: l10n,
                      isDark: isDark,
                      index: index,
                      onActionComplete: _forceRefreshAll,
                    )
                        .animate()
                        .fadeIn(
                          delay: Duration(milliseconds: 250 + (index * 30)),
                          duration: 250.ms,
                        )
                        .slideX(begin: 0.03, curve: Curves.easeOut);
                  },
                  childCount: availableUsers.length,
                ),
              ),
            ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 40),
          ),
        ],
      ),
    );
  }
}

/// Stat card widget for showing counts
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? color.withValues(alpha: 0.1)
            : color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.2 : 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const Spacer(),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;
  final int count;
  final Color accentColor;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.isDark,
    required this.count,
    this.accentColor = AppColors.goldPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black54,
            letterSpacing: 0.3,
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
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.02)
            : Colors.black.withValues(alpha: 0.015),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: isDark ? Colors.white30 : Colors.black26),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 13,
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
  final VoidCallback? onActionComplete;

  const _ManagerCard({
    required this.user,
    required this.isManager,
    required this.classId,
    required this.l10n,
    required this.isDark,
    required this.index,
    this.onActionComplete,
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _handleTap(context, ref),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isManager
                        ? AppColors.goldPrimary.withValues(alpha: 0.15)
                        : Colors.blue.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      userName.isNotEmpty
                          ? userName.substring(0, 1).toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: isManager ? AppColors.goldPrimary : Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        userName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (userEmail.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            userEmail,
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black45,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Action Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isManager
                        ? AppColors.redPrimary.withValues(alpha: isDark ? 0.15 : 0.1)
                        : AppColors.goldPrimary.withValues(alpha: isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isManager ? Icons.remove_rounded : Icons.add_rounded,
                        color: isManager ? AppColors.redPrimary : AppColors.goldPrimary,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isManager ? l10n.remove : l10n.addManager,
                        style: TextStyle(
                          color: isManager ? AppColors.redPrimary : AppColors.goldPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
    final displayName = userName;

    if (isManager) {
      // Show confirmation dialog for removing manager
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          final theme = Theme.of(context);
          final dialogIsDark = theme.brightness == Brightness.dark;

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.redPrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_remove,
                    color: AppColors.redPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.removeManager,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: dialogIsDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              l10n.removeManagerConfirmation(displayName),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: dialogIsDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.redPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(l10n.remove),
              ),
            ],
          );
        },
      );

      if (confirmed != true || !context.mounted) return;

      // Show processing feedback - clear all queued snackbars for fast response
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.removingManager(displayName)),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      final success = await ref
          .read(adminControllerProvider.notifier)
          .removeClassManager(classId, userId);

      // Force refresh the providers to update UI immediately
      ref.invalidate(classManagersProvider(classId));
      onActionComplete?.call();

      if (context.mounted) {
        _showActionFeedback(
          context,
          success: success,
          successMessage: l10n.managerRemoved,
          failureMessage: l10n.actionFailedCheckConnection,
        );
      }
    } else {
      // Show confirmation dialog for adding manager
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          final theme = Theme.of(context);
          final dialogIsDark = theme.brightness == Brightness.dark;

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.goldPrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_add,
                    color: AppColors.goldPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.addManager,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: dialogIsDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              l10n.addManagerConfirmation(displayName),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: dialogIsDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.goldPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(l10n.addManager),
              ),
            ],
          );
        },
      );

      if (confirmed != true || !context.mounted) return;

      // Show processing feedback - clear all queued snackbars for fast response
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.addingManager(displayName)),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      final success = await ref
          .read(adminControllerProvider.notifier)
          .assignClassManager(classId, userId);

      // Force refresh the providers to update UI immediately
      ref.invalidate(classManagersProvider(classId));
      onActionComplete?.call();

      if (context.mounted) {
        _showActionFeedback(
          context,
          success: success,
          successMessage: l10n.managerAssigned,
          failureMessage: l10n.actionFailedCheckConnection,
        );
      }
    }
  }
}

/// Helper method to show action feedback snackbar
void _showActionFeedback(
  BuildContext context, {
  required bool success,
  required String successMessage,
  required String failureMessage,
}) {
  // Clear all queued snackbars for instant response on rapid actions
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            success ? Icons.check_circle : Icons.error_outline,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              success ? successMessage : failureMessage,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: success ? Colors.green.shade600 : Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: Duration(seconds: success ? 2 : 4),
    ),
  );
}
