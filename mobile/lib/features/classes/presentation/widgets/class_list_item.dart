import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/premium_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/database/app_database.dart';
import '../../data/classes_controller.dart';
import 'class_dialogs.dart';

import '../../../../features/attendance/data/attendance_controller.dart';

/// Provider to get managers for a specific class
final classManagerNamesProvider = FutureProvider.family<String, String>((
  ref,
  classId,
) async {
  final controller = ref.watch(classesControllerProvider);
  final managers = await controller.getManagersForClass(classId);
  if (managers.isEmpty) return '';
  return managers.map((m) => m.name).join(', ');
});

class ClassListItem extends ConsumerWidget {
  final ClassesData cls;
  final bool isAdmin;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback? onRefresh;

  const ClassListItem({
    super.key,
    required this.cls,
    required this.isAdmin,
    required this.isDark,
    required this.onTap,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final managersAsync = ref.watch(classManagerNamesProvider(cls.id));
    final percentageAsync = ref.watch(
      classAttendancePercentageProvider(cls.id),
    );

    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              // Class Icon
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            AppColors.goldPrimary.withValues(alpha: 0.3),
                            AppColors.goldDark.withValues(alpha: 0.2),
                          ]
                        : [
                            AppColors.goldPrimary.withValues(alpha: 0.15),
                            AppColors.goldLight.withValues(alpha: 0.1),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.class_,
                  color: isDark ? AppColors.goldPrimary : AppColors.goldDark,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cls.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    // Grade subtitle
                    if (cls.grade != null && cls.grade!.isNotEmpty)
                      Text(
                        cls.grade!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    // Managers subtitle
                    managersAsync.when(
                      data: (managers) {
                        if (managers.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 12,
                                color: isDark
                                    ? AppColors.goldPrimary.withValues(
                                        alpha: 0.7,
                                      )
                                    : AppColors.goldDark.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  managers,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    color: isDark
                                        ? AppColors.goldPrimary.withValues(
                                            alpha: 0.7,
                                          )
                                        : AppColors.goldDark.withValues(
                                            alpha: 0.7,
                                          ),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              // Menu or arrow
              if (isAdmin)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  onSelected: (value) async {
                    if (value == 'rename') {
                      await showRenameClassDialog(context, ref, cls);
                      onRefresh?.call();
                    } else if (value == 'delete') {
                      await showDeleteClassDialog(context, ref, cls);
                      onRefresh?.call();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'rename',
                      child: Row(
                        children: [
                          const Icon(Icons.edit, size: 20),
                          const SizedBox(width: 8),
                          Text(l10n.rename),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete,
                            size: 20,
                            color: isDark
                                ? AppColors.redLight
                                : AppColors.redPrimary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.delete,
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.redLight
                                  : AppColors.redPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 18,
                    color: isDark
                        ? AppColors.goldPrimary
                        : AppColors.goldPrimary,
                  ),
                ),
            ],
          ),
          // Progress Bar
          if (isAdmin) ...[
            const SizedBox(height: 12),
            percentageAsync.when(
              data: (percentage) {
                return Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: isDark
                              ? Colors.white10
                              : Colors.black.withOpacity(0.05),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark ? AppColors.goldPrimary : AppColors.goldDark,
                          ),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.goldPrimary
                            : AppColors.goldDark,
                      ),
                    ),
                  ],
                );
              },
              loading: () => const SizedBox(height: 4), // Placeholder height
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ],
      ),
    );
  }
}
