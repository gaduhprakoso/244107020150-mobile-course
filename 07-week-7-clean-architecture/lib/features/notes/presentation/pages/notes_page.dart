import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/failures.dart';
import '../../../../core/format.dart';
import '../providers/notes_providers.dart';

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notesProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(failureMessage(error)),
            TextButton(
              onPressed: () => ref.invalidate(notesProvider),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
      data: (notes) => notes.isEmpty
          ? const Center(child: Text('Belum ada catatan.'))
          : ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return ListTile(
                  title: Text(note.title),
                  isThreeLine: note.body.isNotEmpty,
                  subtitle: Text(
                    note.body.isEmpty
                        ? formatDate(note.updatedAt)
                        : '${note.body}\n${formatDate(note.updatedAt)}',
                  ),
                );
              },
            ),
    );
  }
}
