import 'package:sqlite3/sqlite3.dart';

class AppDatabase {
  static AppDatabase? _instance;
  final bool isTest;

  factory AppDatabase({
    bool isTest = false,
  }) {
    _instance ??= AppDatabase._internal(
      isTest: isTest,
    );

    return _instance!;
  }

  late final Database db;

  AppDatabase._internal({
    this.isTest = false,
  }) {
    final dbPath = isTest ? ':memory:' : 'notes.db';

    db = sqlite3.open(dbPath);

    _createTables();
  }

  void _createTables() {
    db.execute('''
      CREATE TABLE IF NOT EXISTS notes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');
  }

  void clearNotes() {
    if (isTest) {
      db.execute(
        'DELETE FROM notes',
      );
    }
  }
}
