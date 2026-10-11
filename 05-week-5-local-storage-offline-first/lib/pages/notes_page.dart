import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/local/note.dart';
import '../data/repositories/note_repository.dart';
import '../widgets/note_tile.dart';
import '../widgets/note_editor_dialog.dart';

final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => NoteRepository(),
);

final notesProvider = FutureProvider<List<Note>>(
  (ref) {
    return ref.watch(noteRepositoryProvider).fetchNotes();
  },
  // Riverpod 3: nonaktifkan retry otomatis agar error langsung final
  // dan mudah diuji tanpa menunggu retry.
  retry: (retryCount, error) => null,
);

final dirtyCountProvider = FutureProvider<int>((ref) {
  return ref.watch(noteRepositoryProvider).countDirty();
});

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  Future<void> _addNote(BuildContext context, WidgetRef ref) async {
    final draft = await NoteEditorDialog.show(
      context,
      dialogTitle: 'Catatan baru',
    );
    if (draft == null || !context.mounted) return;

    try {
      await ref
          .read(noteRepositoryProvider)
          .addNote(title: draft.title, body: draft.body);
      ref.invalidate(notesProvider);
      ref.invalidate(dirtyCountProvider);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan catatan: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider);
    final dirtyCount = ref.watch(dirtyCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan'),
        actions: [
          dirtyCount.maybeWhen(
            data: (count) => count > 0
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Badge(
                      label: Text('$count'),
                      child: const Icon(Icons.sync_problem),
                    ),
                  )
                : const Icon(Icons.cloud_done),
            orElse: () => const SizedBox(width: 40, height: 40),
          ),
        ],
      ),
      body: notes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) => items.isEmpty
            ? const Center(child: Text('Belum ada catatan'))
            : ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final note = items[i];
                  return NoteTile(
                    note: note,
                    onTap: note.id != null
                        ? () => context.push('/note/${note.id}')
                        : null,
                    onDelete: () async {
                      if (note.id == null) return;
                      final shouldDelete = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Hapus catatan?'),
                          content: Text('Catatan "${note.title}" akan dihapus.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Batal'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Hapus'),
                            ),
                          ],
                        ),
                      );
                      if (shouldDelete != true || !context.mounted) return;
                      try {
                        await ref
                            .read(noteRepositoryProvider)
                            .deleteNote(note.id!);
                        ref.invalidate(notesProvider);
                        ref.invalidate(dirtyCountProvider);
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Gagal menghapus catatan: $error'),
                            ),
                          );
                        }
                      }
                    },
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addNote(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}
