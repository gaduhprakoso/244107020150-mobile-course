import 'package:sqflite/sqflite.dart';

Future<Database> openNotesDb() async {
  final databasesPath = await getDatabasesPath();

  return openDatabase(
    '$databasesPath/notes.db',
    version: 1,
    onCreate: (database, version) async {
      await database.execute('''
        CREATE TABLE notes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          body TEXT NOT NULL DEFAULT '',
          updated_at TEXT NOT NULL,
          dirty INTEGER NOT NULL DEFAULT 0
        )
      ''');
    },
  );
}
