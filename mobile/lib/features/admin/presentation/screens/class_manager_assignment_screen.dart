import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/components/premium_card.dart';
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
      appBar: AppBar(
        centerTitle: false,
        title: Text(l10n.managersForClass(widget.className)),
        actions: [
          // Manual refresh button - always show if we have fresh data
          if (_hasLoadedFreshData)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshAll,
              tooltip: l10n.tryAgain,
            ),
        ],
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

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.backgroundDark, AppColors.surfaceDark]
              : [AppColors.backgroundLight, Colors.white],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _refreshAll,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Current Managers Section
            _SectionHeader(
              title: l10n.currentManagers,
              icon: Icons.manage_accounts,
              isDark: isDark,
              count: managers.length,
            ),
            const SizedBox(height: 12),
            if (managers.isEmpty)
              _EmptySection(
                text: l10n.noManagersAssigned,
                icon: Icons.person_off_outlined,
                isDark: isDark,
              )
            else
              ...managers.asMap().entries.map((entry) {
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
                ? AppColors.goldPrimary.withValues(alpha: 0.15)
                : AppColors.goldPrimary.withValues(alpha: 0.1),
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
            color: isDark
                ? Colors.white12
                : Colors.black.withValues(alpha: 0.05),
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
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
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
                          ? Colors.green.withValues(alpha: 0.08)
                          : Colors.green.withValues(alpha: 0.05))
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
                                      color: AppColors.goldPrimary.withValues(
                                        alpha: 0.3,
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
                                ? AppColors.redPrimary.withValues(alpha: 0.1)
                                : AppColors.goldPrimary.withValues(alpha: 0.1),
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

      // Show processing feedback
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
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

      if (context.mounted) {
        _showActionFeedback(
          context,
          success: success,
          successMessage: l10n.managerRemoved,
          failureMessage: l10n.actionFailedCheckConnection,
        );
      }
    } else {
      // Show processing feedback
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
