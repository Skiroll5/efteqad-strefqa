import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/components/app_snackbar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/premium_card.dart';
// import '../../../../core/components/premium_button.dart';
import '../../data/admin_controller.dart';
// import '../../data/classes_controller.dart'; // Removed invalid import
import '../../../classes/data/classes_controller.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'class_manager_assignment_screen.dart';

class ClassManagementScreen extends ConsumerStatefulWidget {
  const ClassManagementScreen({super.key});

  @override
  ConsumerState<ClassManagementScreen> createState() =>
      _ClassManagementScreenState();
}

class _ClassManagementScreenState extends ConsumerState<ClassManagementScreen> {
  // Store optimistic order locally to prevent jitter
  List<String>? _optimisticOrder;

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(adminClassesProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.classManagement)),
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
        child: classesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(l10n.errorGeneric(e.toString()))),
          data: (classes) {
            if (classes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.class_outlined,
                      size: 64,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noClassesFound,
                      style: TextStyle(
                        fontSize: 18,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              );
            }

            // The classes list from provider is already sorted by order provider.
            // But if we have a local optimistic update, apply it here.
            var displayClasses = [...classes];
            if (_optimisticOrder != null) {
              displayClasses.sort((a, b) {
                final indexA = _optimisticOrder!.indexOf(a['id']);
                final indexB = _optimisticOrder!.indexOf(b['id']);
                if (indexA == -1 && indexB == -1) return 0;
                if (indexA == -1) return 1;
                if (indexB == -1) return -1;
                return indexA.compareTo(indexB);
              });
            }

            return ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: displayClasses.length,
              onReorder: (oldIndex, newIndex) {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }

                final item = displayClasses.removeAt(oldIndex);
                displayClasses.insert(newIndex, item);

                final newOrderIds = displayClasses
                    .map((c) => c['id'] as String)
                    .toList();

                setState(() {
                  _optimisticOrder = newOrderIds;
                });

                // Save to local storage
                ref
                    .read(classesControllerProvider)
                    .updateClassOrder(newOrderIds);
              },
              itemBuilder: (context, index) {
                final cls = displayClasses[index];
                return _AdminClassCard(
                  key: ValueKey(cls['id']),
                  classData: cls,
                  isDark: isDark,
                  index: index,
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAddClassDialog(context, ref, l10n),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.goldPrimary.withValues(alpha: 0.1)
                  : AppColors.goldPrimary.withValues(alpha: 0.1),
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
                  color: isDark ? AppColors.goldPrimary : AppColors.goldDark,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.addClass,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? AppColors.goldPrimary : AppColors.goldDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddClassDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final nameController = TextEditingController();
    final gradeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addNewClassTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: l10n.className,
                hintText: l10n.classNameHint,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: gradeController,
              decoration: InputDecoration(
                labelText: l10n.gradeOptional,
                hintText: l10n.gradeHint,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final success = await ref
                    .read(adminControllerProvider.notifier)
                    .createClass(
                      nameController.text,
                      gradeController.text, // Pass directly as String
                    );

                if (context.mounted) {
                  Navigator.pop(context);
                  if (success) {
                    AppSnackBar.show(
                      context,
                      message: l10n.classCreated,
                      type: AppSnackBarType.success,
                    );
                  } else {
                    AppSnackBar.show(
                      context,
                      message: l10n.classCreationError,
                      type: AppSnackBarType.error,
                    );
                  }
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.goldPrimary,
            ),
            child: Text(l10n.create),
          ),
        ],
      ),
    );
  }
}

class _AdminClassCard extends ConsumerWidget {
  const _AdminClassCard({
    super.key,
    required this.classData,
    required this.isDark,
    required this.index,
  });

  final Map<String, dynamic> classData;
  final bool isDark;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final classId = classData['id'] as String;
    final managersAsync = ref.watch(classManagersProvider(classId));

    // Calculate attendance percentage from backend data
    final attendancePercentage =
        (classData['attendancePercentage'] as num?)?.toDouble() ?? 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        delay: index * 0.05,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.goldPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.class_outlined,
                    color: isDark ? AppColors.goldPrimary : AppColors.goldDark,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        classData['name'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Subtitle: Manager names
                      managersAsync.when(
                        data: (managers) {
                          if (managers.isEmpty) {
                            return Text(
                              l10n.noManagersAssigned,
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            );
                          }
                          final names = managers
                              .map((m) => m['name'])
                              .join(' • ');
                          return Text(
                            names,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                        loading: () => const SizedBox(
                          height: 10,
                          width: 100,
                          child: LinearProgressIndicator(minHeight: 2),
                        ),
                        error: (_, __) => const SizedBox(),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Progress Bar in subtitle area or bottom of tile header?
            // ExpansionTile doesn't easily support custom layout below title without hacking.
            // Let's put the progress bar in the children or try to use subtitle for it?
            // User requested: "For the class cards you should add a progress bar with the average percentage of presence"
            // Let's add it as a child of the card content (ExpansionTile children).
            childrenPadding: const EdgeInsets.all(16),
            children: [
              // Attendance Progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.attendanceRate,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getAttendanceStatusText(attendancePercentage, l10n),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(
                          value: attendancePercentage,
                          strokeWidth: 5,
                          backgroundColor: isDark
                              ? Colors.grey[800]
                              : Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation(
                            _getColorForPercentage(attendancePercentage),
                          ),
                        ),
                      ),
                      Text(
                        '${(attendancePercentage * 100).toInt()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Managers Management
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.classManagers,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClassManagerAssignmentScreen(
                            classId: classId,
                            className: classData['name'],
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: Text(
                      l10n.manage,
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.goldPrimary,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              managersAsync.when(
                data: (managers) {
                  if (managers.isEmpty) {
                    return Text(
                      l10n.noManagersAssigned,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    );
                  }
                  // Show preview of managers (limit 3)
                  final displayManagers = managers.take(3).toList();
                  return Column(
                    children: [
                      ...displayManagers.map((manager) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.goldPrimary.withValues(
                              alpha: 0.2,
                            ),
                            child: Text(
                              manager['name'].substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.goldPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            manager['name'],
                            style: const TextStyle(fontSize: 13),
                          ),
                          dense: true,
                          visualDensity: VisualDensity.compact,
                        );
                      }),
                      if (managers.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '+ ${managers.length - 3} more',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text(l10n.errorGeneric(e.toString())),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorForPercentage(double percentage) {
    if (percentage >= 0.8) return Colors.green;
    if (percentage >= 0.5) return Colors.orange;
    return AppColors.redPrimary;
  }

  String _getAttendanceStatusText(double percentage, AppLocalizations l10n) {
    if (percentage >= 0.8) return l10n.good;
    if (percentage >= 0.5) return l10n.average;
    return l10n.poor;
  }

  // Removed unused _showAddManagerDialog

  // Removed unused _confirmRemoveManager
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
              // Filter out admins, existing managers, non-activated, and denied users
              final eligibleUsers = allUsers
                  .where(
                    (u) =>
                        !managerIds.contains(u['id']) &&
                        u['role'] != 'ADMIN' &&
                        u['isActive'] == true &&
                        u['activationDenied'] != true &&
                        u['isDeleted'] == false,
                  )
                  .toList();

              if (eligibleUsers.isEmpty) {
                return Text(l10n.allUsersAreManagers);
              }

              return DropdownButtonFormField<String>(
                initialValue: _selectedUserId,
                hint: Text(l10n.selectClassToManage), // "Select..."
                isExpanded: true,
                items: eligibleUsers.map((user) {
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
            loading: () => const SizedBox(
              height: 50,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text(l10n.errorGeneric(e.toString())),
          );
        },
        loading: () => const SizedBox(
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
          onPressed: _selectedUserId == null
              ? null
              : () async {
                  final success = await ref
                      .read(adminControllerProvider.notifier)
                      .assignClassManager(widget.classId, _selectedUserId!);
                  if (context.mounted) {
                    Navigator.pop(context);
                    AppSnackBar.show(
                      context,
                      message: success
                          ? l10n.managerAdded('') // Placeholder
                          : l10n.managerAddFailed,
                      type: success
                          ? AppSnackBarType.success
                          : AppSnackBarType.error,
                    );
                  }
                },
          child: Text(l10n.add),
        ),
      ],
    );
  }
}
