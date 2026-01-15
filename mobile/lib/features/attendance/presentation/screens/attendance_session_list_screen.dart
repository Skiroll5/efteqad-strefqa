import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/premium_card.dart';
import '../../data/attendance_controller.dart';
import '../../../students/data/students_controller.dart';
import '../../../classes/data/classes_controller.dart';
import '../../../auth/data/auth_controller.dart';

class AttendanceSessionListScreen extends ConsumerWidget {
  const AttendanceSessionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(attendanceSessionsProvider);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final selectedClassId = ref.watch(selectedClassIdProvider);
    final user = ref.watch(authControllerProvider).asData?.value;

    return Scaffold(
      appBar: AppBar(
        title: user?.role == 'ADMIN'
            ? Consumer(
                builder: (context, ref, _) {
                  final classesAsync = ref.watch(classesStreamProvider);
                  final selectedInfo = ref.watch(selectedClassIdProvider);
                  return classesAsync.when(
                    data: (classes) {
                      if (classes.isEmpty) return const Text('Attendance');
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedInfo,
                            hint: const Text(
                              'Select Class',
                              style: TextStyle(color: Colors.white),
                            ),
                            dropdownColor: AppColors.bluePrimary,
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.white,
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            items: classes
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                ref
                                        .read(selectedClassIdProvider.notifier)
                                        .state =
                                    val;
                              }
                            },
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox(),
                    error: (_, __) => const Text('Error'),
                  );
                },
              )
            : Text(l10n?.attendance ?? 'Attendance'),
        centerTitle: true,
      ),
      body: sessionsAsync.when(
        data: (sessions) {
          if (selectedClassId == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.class_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Please select a class',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_note_outlined,
                    size: 80,
                    color: Colors.grey.withOpacity(0.5),
                  ).animate().scale(
                    duration: 500.ms,
                    curve: Curves.easeOutBack,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No attendance sessions yet',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.grey,
                    ),
                  ).animate().fade(delay: 200.ms),
                  const SizedBox(height: 8),
                  Text(
                    'Tap below to take attendance',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                  ).animate().fade(delay: 400.ms),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return PremiumCard(
                delay: index * 0.05,
                margin: const EdgeInsets.only(bottom: 12),
                onTap: () => context.push('/attendance/${session.id}'),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.bluePrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            DateFormat.d().format(session.date),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.bluePrimary,
                            ),
                          ),
                          Text(
                            DateFormat.MMM().format(session.date).toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.bluePrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat.EEEE().format(session.date),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (session.note != null && session.note!.isNotEmpty)
                            Text(
                              session.note!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat.jm().format(session.date),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton.extended(
          onPressed: selectedClassId == null
              ? null
              : () => context.push('/attendance/new'),
          backgroundColor: selectedClassId == null
              ? Colors.grey
              : AppColors.goldPrimary,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Take Attendance',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
