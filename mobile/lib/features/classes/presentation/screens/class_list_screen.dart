import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/classes_controller.dart';

class ClassListScreen extends ConsumerWidget {
  const ClassListScreen({super.key});

  void _showAddClassDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final gradeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Class'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Class Name'),
            ),
            TextField(
              controller: gradeController,
              decoration: const InputDecoration(labelText: 'Grade (Optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(classesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Classes')),
      body: classesAsync.when(
        data: (classes) {
          if (classes.isEmpty) {
            return const Center(child: Text('No classes found. Add one!'));
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
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddClassDialog(context, ref),
        backgroundColor: AppColors.goldPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
