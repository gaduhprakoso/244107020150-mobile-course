import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/note.dart';
import '../widgets/note_editor_dialog.dart';
import 'notes_page.dart';

final noteDetailProvider = FutureProvider.family<Note?, int>((ref, id) {
  return ref.watch(noteRepositoryProvider).fetchNoteById(id);
});

class NoteDetailPage extends ConsumerWidget {
  const NoteDetailPage({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteAsync = ref.watch(noteDetailProvider(id));
    final note = noteAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Catatan'),
        actions: [
          if (note != null)
            IconButton(
              tooltip: 'Edit catatan',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final draft = await NoteEditorDialog.show(
                  context,
                  dialogTitle: 'Edit catatan',
                  initialTitle: note.title,
                  initialBody: note.body,
                );
                if (draft == null || !context.mounted) return;

                try {
                  await ref.read(noteRepositoryProvider).updateNote(
                        id,
                        title: draft.title,
                        body: draft.body,
                      );
                  ref.invalidate(noteDetailProvider(id));
                  ref.invalidate(notesProvider);
                  ref.invalidate(dirtyCountProvider);
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal memperbarui catatan: $error'),
                      ),
                    );
                  }
                }
              },
            ),
        ],
      ),
      body: noteAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (note) {
          if (note == null) {
            return const Center(child: Text('Catatan tidak ditemukan'));
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(note.title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('Diperbarui: ${note.updatedAt.toLocal()}'),
                const SizedBox(height: 8),
                if (note.dirty) const Chip(label: Text('belum tersinkron')),
                const Divider(height: 32),
                Text(note.body.isEmpty ? '(tanpa isi)' : note.body),
              ],
            ),
          );
        },
      ),
    );
  }
}