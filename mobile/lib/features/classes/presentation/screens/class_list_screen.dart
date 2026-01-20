import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/classes_controller.dart';
import '../../../../l10n/app_localizations.dart';

class ClassListScreen extends ConsumerWidget {
  const ClassListScreen({super.key});

  void _showAddClassDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final gradeController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.addNewClassTitle ?? 'Add New Class'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: l10n?.className ?? 'Class Name',
              ),
            ),
            TextField(
              controller: gradeController,
              decoration: InputDecoration(
                labelText: l10n?.gradeOptional ?? 'Grade (Optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await ref
                    .read(classesControllerProvider)
                    .addClass(
                      nameController.text,
                      gradeController.text.isEmpty
                          ? null
                          : gradeController.text,
                    );
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: Text(l10n?.add ?? 'Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(classesStreamProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n?.manageClasses ?? 'Manage Classes')),
      body: classesAsync.when(
        data: (classes) {
          if (classes.isEmpty) {
            return Center(
              child: Text(
                l10n?.noClassesFoundAdd ?? 'No classes found. Add one!',
              ),
            );
          }
          return ListView.builder(
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final klass = classes[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.goldPrimary,
                    child: Icon(Icons.class_, color: Colors.white),
                  ),
                  title: Text(
                    klass.name,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  subtitle: klass.grade != null ? Text(klass.grade!) : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigate to class details or edit
                    // context.push('/classes/${klass.id}');
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Text(l10n.errorGeneric(e.toString())),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddClassDialog(context, ref),
        backgroundColor: AppColors.goldPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
