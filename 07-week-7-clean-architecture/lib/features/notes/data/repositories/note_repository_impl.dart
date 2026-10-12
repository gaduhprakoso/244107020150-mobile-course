import 'package:sqflite/sqflite.dart';

import '../../../../core/failures.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../models/note_model.dart';

class NoteRepositoryImpl implements NoteRepository {
  NoteRepositoryImpl({required this._openDb});

  final Future<Database> Function() _openDb;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    try {
      final db = await _openDb();
      final rows = await db.query('notes', orderBy: 'updated_at DESC');
      final notes = rows.map((r) => NoteModel.fromMap(r).toEntity()).toList();
      return (notes: notes, failure: null);
    } catch (_) {
      return (
        notes: const <Note>[],
        failure: const LocalFailure('Gagal membaca catatan. Silakan coba lagi.'),
      );
    }
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    try {
      final db = await _openDb();
      final now = DateTime.now();
      final id = await db.insert(
        'notes',
        NoteModel(
          title: title,
          body: body,
          updatedAt: now,
          dirty: true,
        ).toMap(),
      );
      return (
        note: Note(
          id: id,
          title: title,
          body: body,
          updatedAt: now,
          dirty: true,
        ),
        failure: null,
      );
    } catch (_) {
      return (
        note: null,
        failure: const LocalFailure(
          'Gagal menyimpan catatan. Silakan coba lagi.',
        ),
      );
    }
  }
}
