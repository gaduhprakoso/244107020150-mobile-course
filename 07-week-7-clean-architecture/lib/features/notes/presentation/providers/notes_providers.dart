import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/failures.dart';
import '../../data/datasources/notes_database.dart';
import '../../data/repositories/note_repository_impl.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/usecases/add_note.dart';
import '../../domain/usecases/get_notes.dart';

// Data layer: database opener disuntikkan (mudah diganti fake saat test)
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepositoryImpl(openDb: openNotesDb);
});

// Domain layer: use case menerima abstraksi, bukan implementasi
final getNotesProvider = Provider<GetNotes>((ref) {
  return GetNotes(ref.watch(noteRepositoryProvider));
});

final addNoteProvider = Provider<AddNote>((ref) {
  return AddNote(ref.watch(noteRepositoryProvider));
});

// Presentation layer: state untuk UI
final notesProvider = FutureProvider<List<Note>>((ref) async {
  try {
    final result = await ref.watch(getNotesProvider).call();
    if (result.failure != null) throw result.failure!;
    return result.notes;
  } on Failure {
    rethrow;
  } catch (_) {
    throw const LocalFailure('Gagal memuat catatan. Silakan coba lagi.');
  }
});
