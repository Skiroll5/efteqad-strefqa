import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/database/app_database.dart';
import 'class_dialogs.dart';

import '../../../../features/attendance/data/attendance_controller.dart';

/// Provider to get managers for a specific class
// classManagerNamesProvider removed

class ClassListItem extends ConsumerWidget {
  final ClassesData cls;
  final bool isAdmin;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback? onRefresh;
  final bool showDragHandle;
  final int? reorderIndex;

  const ClassListItem({
    super.key,
    required this.cls,
    required this.isAdmin,
    required this.isDark,
    required this.onTap,
    this.onRefresh,
    this.showDragHandle = false,
    this.reorderIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    // Managers are now pre-fetched in the class object
    final managers = cls.managerNames ?? '';
    
    // DEBUG: Log manager names
    debugPrint('ClassListItem [${cls.name}]: managerNames = "${cls.managerNames}" (isEmpty: ${managers.isEmpty})');
    
    final percentageAsync = ref.watch(
      classAttendancePercentageProvider(cls.id),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Drag handle replaces class icon when reorderable
                    if (showDragHandle && reorderIndex != null)
                      ReorderableDragStartListener(
                        index: reorderIndex!,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.drag_indicator_rounded,
                              color: isDark ? Colors.white54 : Colors.black38,
                              size: 24,
                            ),
                          ),
                        ),
                      )
                    else
                      // Class Icon - when not reorderable
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.goldPrimary.withValues(alpha: 0.15)
                              : AppColors.goldPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.class_rounded,
                            color: AppColors.goldPrimary,
                            size: 22,
                          ),
                        ),
                      ),
                    const SizedBox(width: 14),
                    // Class Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cls.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.textPrimaryLight,
                            ),
                          ),
                          // Managers as subtitle
                          if (managers.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                managers,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark ? Colors.white54 : Colors.black45,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          else if (cls.grade != null && cls.grade!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                cls.grade!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark ? Colors.white54 : Colors.black45,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Actions
                    if (isAdmin)
                      // Menu button only
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: isDark ? Colors.white54 : Colors.black45,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
                                Icon(Icons.edit_rounded, size: 18, color: isDark ? Colors.white70 : Colors.black54),
                                const SizedBox(width: 10),
                                Text(l10n.rename),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.redPrimary),
                                const SizedBox(width: 10),
                                Text(
                                  l10n.delete,
                                  style: TextStyle(color: AppColors.redPrimary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      // Simple arrow for non-admin
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 24,
                        color: isDark ? Colors.white38 : Colors.black26,
                      ),
                  ],
                ),
                // Attendance progress bar with percentage (Admin only)
                if (isAdmin)
                  percentageAsync.when(
                    data: (percentage) {
                      Color progressColor = Colors.green;
                      if (percentage < 50) {
                        progressColor = AppColors.redPrimary;
                      } else if (percentage < 80) {
                        progressColor = Colors.orange;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          children: [
                            // Progress bar
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: percentage / 100,
                                  minHeight: 6,
                                  backgroundColor: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.black.withValues(alpha: 0.06),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    progressColor.withValues(alpha: 0.8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Percentage chip
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: progressColor.withValues(alpha: isDark ? 0.15 : 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${percentage.toInt()}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: progressColor,
                                ),
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
        ),
      ),
    );
  }
}
