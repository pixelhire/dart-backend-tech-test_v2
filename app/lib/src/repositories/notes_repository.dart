import 'package:sqlite3/sqlite3.dart';

import '../database/database.dart';
import '../models/note.dart';

class NotesRepository {
  final Database _db;

  NotesRepository({
    AppDatabase? database,
  }) : _db = (database ?? AppDatabase()).db;

  Future<void> create(Note note) async {
    _db.execute(
      '''
      INSERT INTO notes (
        id,
        title,
        content,
        created_at,
        updated_at
      )
      VALUES (?, ?, ?, ?, ?)
      ''',
      [
        note.id,
        note.title,
        note.content,
        note.createdAt.toIso8601String(),
        note.updatedAt.toIso8601String(),
      ],
    );
  }

  Future<List<Note>> getAll({
    required int page,
    required int limit,
  }) async {
    final offset = (page - 1) * limit;

    final result = _db.select(
      '''
      SELECT * FROM notes
      ORDER BY created_at DESC
      LIMIT ? OFFSET ?
      ''',
      [limit, offset],
    );

    return result.map(_mapNote).toList();
  }

  Future<int> count() async {
    final result = _db.select(
      'SELECT COUNT(*) AS count FROM notes',
    );

    return result.first['count'] as int;
  }

  Future<Note?> getById(String id) async {
    final result = _db.select(
      'SELECT * FROM notes WHERE id = ?',
      [id],
    );

    if (result.isEmpty) {
      return null;
    }

    return _mapNote(result.first);
  }

  Future<void> update(Note note) async {
    _db.execute(
      '''
      UPDATE notes
      SET title = ?,
          content = ?,
          updated_at = ?
      WHERE id = ?
      ''',
      [
        note.title,
        note.content,
        note.updatedAt.toIso8601String(),
        note.id,
      ],
    );
  }

  Future<void> delete(String id) async {
    _db.execute(
      'DELETE FROM notes WHERE id = ?',
      [id],
    );
  }

  Note _mapNote(Row row) {
    return Note(
      id: row['id'] as String,
      title: row['title'] as String,
      content: row['content'] as String,
      createdAt: DateTime.parse(
        row['created_at'] as String,
      ),
      updatedAt: DateTime.parse(
        row['updated_at'] as String,
      ),
    );
  }
}
