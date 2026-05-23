import 'package:test/test.dart';

import 'package:dart_backend_tech_test/src/database/database.dart';
import 'package:dart_backend_tech_test/src/exceptions/api_exception.dart';
import 'package:dart_backend_tech_test/src/repositories/notes_repository.dart';
import 'package:dart_backend_tech_test/src/services/notes_service.dart';

void main() {
  group('Notes Service Unit Tests', () {
    late NotesService service;

    setUp(() {
      final database = AppDatabase(
        isTest: true,
      );

      database.clearNotes();

      final repository = NotesRepository(
        database: database,
      );

      service = NotesService(
        repository: repository,
      );
    });

    test(
      'Create note should succeed',
      () async {
        final note = await service.create(
          title: 'Test Note',
          content: 'Test Content',
        );

        expect(
          note.id,
          isNotEmpty,
        );

        expect(
          note.title,
          'Test Note',
        );

        expect(
          note.content,
          'Test Content',
        );
      },
    );

    test(
      'Create note should fail for empty title',
      () async {
        expect(
          () => service.create(
            title: '',
            content: 'Content',
          ),
          throwsA(
            isA<BadRequestException>(),
          ),
        );
      },
    );

    test(
      'Create note should fail for long title',
      () async {
        expect(
          () => service.create(
            title: 'A' * 121,
            content: 'Content',
          ),
          throwsA(
            isA<BadRequestException>(),
          ),
        );
      },
    );

    test(
      'Create note should fail for long content',
      () async {
        expect(
          () => service.create(
            title: 'Valid',
            content: 'A' * 10001,
          ),
          throwsA(
            isA<BadRequestException>(),
          ),
        );
      },
    );

    test(
      'Get note by id should succeed',
      () async {
        final created = await service.create(
          title: 'Fetch Test',
          content: 'Fetch Content',
        );

        final fetched = await service.getById(
          created.id,
        );

        expect(
          fetched.id,
          created.id,
        );

        expect(
          fetched.title,
          'Fetch Test',
        );
      },
    );

    test(
      'Get unknown note should throw NotFoundException',
      () async {
        expect(
          () => service.getById(
            'unknown-id',
          ),
          throwsA(
            isA<NotFoundException>(),
          ),
        );
      },
    );

    test(
      'Update note should succeed',
      () async {
        final created = await service.create(
          title: 'Old',
          content: 'Old Content',
        );

        final updated = await service.update(
          id: created.id,
          title: 'Updated',
          content: 'Updated Content',
        );

        expect(
          updated.title,
          'Updated',
        );

        expect(
          updated.content,
          'Updated Content',
        );
      },
    );

    test(
      'Update unknown note should throw NotFoundException',
      () async {
        expect(
          () => service.update(
            id: 'unknown-id',
            title: 'Updated',
            content: 'Updated',
          ),
          throwsA(
            isA<NotFoundException>(),
          ),
        );
      },
    );

    test(
      'Delete note should succeed',
      () async {
        final created = await service.create(
          title: 'Delete Test',
          content: 'Delete Content',
        );

        await service.delete(
          created.id,
        );

        expect(
          () => service.getById(
            created.id,
          ),
          throwsA(
            isA<NotFoundException>(),
          ),
        );
      },
    );

    test(
      'Delete unknown note should throw NotFoundException',
      () async {
        expect(
          () => service.delete(
            'unknown-id',
          ),
          throwsA(
            isA<NotFoundException>(),
          ),
        );
      },
    );

    test(
      'Get all notes should return paginated response',
      () async {
        await service.create(
          title: 'Note 1',
          content: 'Content 1',
        );

        await service.create(
          title: 'Note 2',
          content: 'Content 2',
        );

        final result = await service.getAll(
          page: 1,
          limit: 10,
        );

        expect(
          result['page'],
          1,
        );

        expect(
          result['limit'],
          10,
        );

        expect(
          result['items'],
          isList,
        );

        expect(
          result['total'],
          greaterThanOrEqualTo(2),
        );
      },
    );
  });
}
