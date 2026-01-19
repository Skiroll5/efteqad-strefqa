import 'package:flutter/material.dart';
import 'dart:async'; // For Timer
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile/features/admin/data/admin_controller.dart';
import 'package:mobile/features/admin/presentation/screens/class_manager_assignment_screen.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_loading_screen.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_error_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/premium_card.dart';
import '../../../../core/database/app_database.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/data/auth_controller.dart';
import '../../../classes/presentation/widgets/class_list_item.dart';
import '../../../classes/presentation/widgets/class_dialogs.dart';
import '../../../sync/data/sync_service.dart';
import '../widgets/user_status_toggle.dart';

class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen> {
  Timer? _retryTimer;
  bool _isAutoRetrying = false;
  bool _hasLoadedFreshData =
      false; // Track if we've loaded fresh data since screen entry

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

  /// Force invalidate all providers to ensure fresh data fetch
  void _forceRefreshAll() {
    ref.invalidate(adminClassesProvider);
    ref.invalidate(pendingUsersProvider);
    ref.invalidate(allUsersProvider);
    ref.read(syncServiceProvider).pullChanges();
  }

  /// Start the connectivity check loop for auto-retry
  void _startConnectivityLoop() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;

      final classesState = ref.read(adminClassesProvider);
      final pendingState = ref.read(pendingUsersProvider);
      final allUsersState = ref.read(allUsersProvider);

      // Check if any provider has an error (connection failed)
      final hasError =
          classesState.hasError ||
          pendingState.hasError ||
          allUsersState.hasError;

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

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  /// Manual refresh triggered by user
  Future<void> _refreshAll() async {
    setState(() => _hasLoadedFreshData = false);
    _forceRefreshAll();
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

    // Watch all providers to determine unified loading/error state
    final classesAsync = ref.watch(adminClassesProvider);
    final pendingUsersAsync = ref.watch(pendingUsersProvider);
    final allUsersAsync = ref.watch(allUsersProvider);

    // Track when fresh data has been loaded
    final hasAllData =
        classesAsync.hasValue &&
        pendingUsersAsync.hasValue &&
        allUsersAsync.hasValue;
    final hasError =
        classesAsync.hasError ||
        pendingUsersAsync.hasError ||
        allUsersAsync.hasError;
    final isLoading =
        classesAsync.isLoading ||
        pendingUsersAsync.isLoading ||
        allUsersAsync.isLoading;

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
    final firstError =
        classesAsync.error ?? pendingUsersAsync.error ?? allUsersAsync.error;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.adminPanel ?? 'Admin Panel'),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          // Manual refresh button - always show if we have fresh data
          if (_hasLoadedFreshData)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshAll,
              tooltip: l10n?.tryAgain ?? 'Refresh',
            ),
        ],
      ),
      body: _buildBody(
        context,
        showLoading: showLoading,
        showError: showError,
        firstError: firstError,
        isDark: isDark,
        l10n: l10n,
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required bool showLoading,
    required bool showError,
    required Object? firstError,
    required bool isDark,
    required AppLocalizations? l10n,
  }) {
    // Full-page Loading State - only until first fresh load
    if (showLoading) {
      return AdminLoadingScreen(
        message: l10n?.loadingAdminPanel ?? 'Loading Admin Panel...',
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
    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Class Management Section
          _ClassesSection(isDark: isDark, onRefresh: _refreshAll),

          const SizedBox(height: 24),

          // 2. User Management Section
          _UsersSection(isDark: isDark, onRefresh: _refreshAll),
        ],
      ),
    );
  }
}

class _ClassesSection extends ConsumerWidget {
  final bool isDark;
  final VoidCallback onRefresh;

  const _ClassesSection({required this.isDark, required this.onRefresh});

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
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  await showAddClassDialog(context, ref);
                  ref.invalidate(adminClassesProvider);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.goldPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppColors.goldPrimary.withValues(alpha: 0.2)
                          : AppColors.goldPrimary.withValues(alpha: 0.3),
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
        ),
        const SizedBox(height: 8),
        // Use valueOrNull to keep showing data during background refreshes
        Builder(
          builder: (context) {
            final classes = classesAsync.valueOrNull ?? [];

            if (classes.isEmpty && !classesAsync.isLoading) {
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
                  managerNames: classData['managerNames'] as String?,
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
  final VoidCallback onRefresh;

  const _UsersSection({required this.isDark, required this.onRefresh});

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

        // Pending Users Sub-section - use Consumer to properly access ref
        Consumer(
          builder: (context, ref, _) {
            final users = ref.watch(pendingUsersProvider).valueOrNull ?? [];
            final controller = ref.watch(adminControllerProvider.notifier);
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
                            final success = await controller.activateUser(
                              user['id'],
                            );
                            if (context.mounted) {
                              _showActionFeedback(
                                context,
                                success: success,
                                successMessage:
                                    l10n?.userActivated ?? 'User activated!',
                                failureMessage:
                                    l10n?.actionFailedCheckConnection ??
                                    'Action failed. Check your internet connection.',
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

        // Use Consumer to properly access ref and keep UI in sync
        Consumer(
          builder: (context, ref, _) {
            final users = ref.watch(allUsersProvider).valueOrNull ?? [];
            final controller = ref.watch(adminControllerProvider.notifier);

            if (users.isEmpty && !allUsersAsync.isLoading) {
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
                final isEnabled = user['isEnabled'] == true;
                final isAdmin = user['role'] == 'ADMIN';

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isAdmin
                          ? Colors.amber.shade100
                          : (isEnabled
                                ? Colors.green.shade100
                                : Colors.grey.shade200),
                      child: Icon(
                        isAdmin ? Icons.admin_panel_settings : Icons.person,
                        color: isAdmin
                            ? Colors.amber.shade700
                            : (isEnabled ? Colors.green : Colors.grey),
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
                        if (!isActive && !isAdmin) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              l10n?.pending ?? 'Pending',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(user['email'] ?? ''),
                    trailing: isAdmin
                        ? null // Don't allow modifying admin users
                        : UserStatusToggle(
                            isEnabled: isEnabled,
                            enabledLabel: l10n?.enabled ?? 'Enabled',
                            disabledLabel: l10n?.disabled ?? 'Disabled',
                            onToggle: (newValue) async {
                              final success = newValue
                                  ? await controller.enableUser(user['id'])
                                  : await controller.disableUser(user['id']);
                              if (context.mounted && !success) {
                                _showActionFeedback(
                                  context,
                                  success: false,
                                  successMessage: '',
                                  failureMessage:
                                      l10n?.actionFailedCheckConnection ??
                                      'Action failed. Check your internet connection.',
                                );
                              }
                              return success;
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
