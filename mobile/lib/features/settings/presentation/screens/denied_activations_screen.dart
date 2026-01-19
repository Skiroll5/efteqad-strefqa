import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/premium_card.dart';
import '../../../admin/data/admin_controller.dart';
import 'package:mobile/l10n/app_localizations.dart';

class DeniedActivationsScreen extends ConsumerWidget {
  const DeniedActivationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final abortedUsers = ref.watch(abortedUsersProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.abortedActivations),
        centerTitle: false,
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
        child: abortedUsers.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.redPrimary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.errorGeneric(e.toString()),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
          data: (users) {
            if (users.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_outline,
                          size: 40,
                          color: Colors.green,
                        ),
                      ).animate().scale(
                            duration: 500.ms,
                            curve: Curves.easeOutBack,
                          ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.noAbortedUsers,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fade(delay: 100.ms),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(abortedUsersProvider),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return _DeniedUserCard(
                    user: user,
                    isDark: isDark,
                    onReactivate: () =>
                        _reactivateUser(context, ref, user['id'], user['name'] ?? 'Unknown', l10n),
                  )
                      .animate()
                      .fade(delay: Duration(milliseconds: (index * 100)))
                      .slideX(begin: 0.1);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _reactivateUser(
    BuildContext context,
    WidgetRef ref,
    String userId,
    String userName,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.person_add_alt_1_rounded,
          color: Colors.orange.shade600,
          size: 32,
        ),
        title: Text(l10n.reactivate),
        content: Text(
          l10n.reactivateConfirmation(userName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: Text(l10n.reactivate),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final success =
        await ref.read(adminControllerProvider.notifier).activateUser(userId);
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

class _DeniedUserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isDark;
  final VoidCallback onReactivate;

  const _DeniedUserCard({
    required this.user,
    required this.isDark,
    required this.onReactivate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.redPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  (user['name'] as String?)?.isNotEmpty == true
                      ? user['name'][0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.redPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['name'] ?? 'Unknown',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user['email'] ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                  if (user['createdAt'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(user['createdAt']),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Reactivate Button
            FilledButton.icon(
              onPressed: onReactivate,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.reactivate),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }
}
