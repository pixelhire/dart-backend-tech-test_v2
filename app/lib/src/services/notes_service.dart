import 'package:uuid/uuid.dart';

import '../exceptions/api_exception.dart';
import '../models/note.dart';
import '../repositories/notes_repository.dart';
import '../utils/validators.dart';

class NotesService {
  final _uuid = const Uuid();

  final NotesRepository repository;

  NotesService({
    NotesRepository? repository,
  }) : repository = repository ?? NotesRepository();

  Future<Note> create({
    required String title,
    required String content,
  }) async {
    Validators.validateNote(
      title: title,
      content: content,
    );

    final now = DateTime.now();

    final note = Note(
      id: _uuid.v4(),
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
    );

    await repository.create(note);

    return note;
  }

  Future<Map<String, dynamic>> getAll({
    required int page,
    required int limit,
  }) async {
    final notes = await repository.getAll(
      page: page,
      limit: limit,
    );

    final total = await repository.count();

    return {
      'page': page,
      'limit': limit,
      'total': total,
      'items': notes.map((e) => e.toJson()).toList(),
    };
  }

  Future<Note> getById(String id) async {
    final note = await repository.getById(id);

    if (note == null) {
      throw NotFoundException('Note not found');
    }

    return note;
  }

  Future<Note> update({
    required String id,
    required String title,
    required String content,
  }) async {
    Validators.validateNote(
      title: title,
      content: content,
    );

    final note = await getById(id);

    note.title = title;
    note.content = content;
    note.updatedAt = DateTime.now();

    await repository.update(note);

    return note;
  }

  Future<void> delete(String id) async {
    await getById(id);

    await repository.delete(id);
  }
}
