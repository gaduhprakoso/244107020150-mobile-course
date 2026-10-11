import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/data/local/post.dart';
import 'package:week5_offline_notes/data/repositories/note_repository.dart';
import 'package:week5_offline_notes/data/sync.dart';
import 'package:week5_offline_notes/main.dart';
import 'package:week5_offline_notes/pages/notes_page.dart';
import 'package:week5_offline_notes/pages/setting_page.dart';

class _TestNoteRepository extends NoteRepository {
  _TestNoteRepository() : super(openDb: () async => throw UnimplementedError());

  final List<Note> _notes = [
    Note(
      id: 1,
      title: 'Catatan uji',
      body: 'Isi catatan uji',
      updatedAt: DateTime(2026),
    ),
  ];

  @override
  Future<List<Note>> fetchNotes() async => List.unmodifiable(_notes);

  @override
  Future<Note?> fetchNoteById(int id) async {
    for (final note in _notes) {
      if (note.id == id) return note;
    }
    return null;
  }

  @override
  Future<int> countDirty() async => 0;

  @override
  Future<Note> addNote({required String title, String body = ''}) async {
    final note = Note(
      id: _notes.length + 1,
      title: title,
      body: body,
      updatedAt: DateTime.now(),
      dirty: true,
    );
    _notes.add(note);
    return note;
  }

  @override
  Future<void> updateNote(
    int id, {
    required String title,
    required String body,
  }) async {
    final index = _notes.indexWhere((note) => note.id == id);
    if (index == -1) return;
    _notes[index] = Note(
      id: id,
      title: title,
      body: body,
      updatedAt: DateTime.now(),
      dirty: true,
    );
  }

  @override
  Future<void> deleteNote(int id) async {
    _notes.removeWhere((note) => note.id == id);
  }
}

void main() {
  testWidgets('Settings page menampilkan toggle mode gelap', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SettingsPage())),
    );
    await tester.pumpAndSettle();
    expect(find.text('Mode gelap'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsOneWidget);
  });

  testWidgets('Aplikasi menavigasi tab dan detail dengan go_router', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          noteRepositoryProvider.overrideWithValue(_TestNoteRepository()),
          postsProvider.overrideWith((ref) async => <Post>[]),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Catatan Offline'), findsOneWidget);
    expect(find.text('Catatan uji'), findsOneWidget);

    await tester.tap(find.text('Posts'));
    await tester.pumpAndSettle();
    expect(find.text('Posts (cache-first)'), findsOneWidget);

    await tester.tap(find.text('Pengaturan'));
    await tester.pumpAndSettle();
    expect(find.text('Mode gelap'), findsOneWidget);

    await tester.tap(find.text('Catatan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Catatan uji'));
    await tester.pumpAndSettle();
    expect(find.text('Detail Catatan'), findsOneWidget);
    expect(find.text('Isi catatan uji'), findsOneWidget);

    await tester.tap(find.byTooltip('Edit catatan'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('note-title-field')),
      'Catatan diperbarui',
    );
    await tester.enterText(
      find.byKey(const ValueKey('note-body-field')),
      'Isi diperbarui',
    );
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Catatan diperbarui'), findsOneWidget);
    expect(find.text('Isi diperbarui'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('note-title-field')),
      'Catatan baru',
    );
    await tester.enterText(
      find.byKey(const ValueKey('note-body-field')),
      'Isi catatan baru',
    );
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Catatan baru'), findsOneWidget);

    await tester.tap(find.byTooltip('Hapus catatan').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    expect(find.text('Catatan baru'), findsNothing);
  });
}
