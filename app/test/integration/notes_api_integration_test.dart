import 'dart:convert';
import 'dart:io';

import 'package:dart_backend_tech_test/src/database/database.dart';
import 'package:dart_backend_tech_test/src/repositories/notes_repository.dart';
import 'package:dart_backend_tech_test/src/services/notes_service.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:test/test.dart';

import 'package:dart_backend_tech_test/src/controllers/notes_controller.dart';
import 'package:dart_backend_tech_test/src/middleware/auth.dart';
import 'package:dart_backend_tech_test/src/middleware/error_middleware.dart';
import 'package:dart_backend_tech_test/src/middleware/rate_limit.dart';
import 'package:dart_backend_tech_test/src/services/feature_flags.dart';

void main() {
  group('Notes API Integration Tests', () {
    late HttpServer server;
    late HttpClient client;
    late int port;

    late AppDatabase database;

    const apiKey = 'sandbox_key';

    setUp(() async {
      database = AppDatabase(
        isTest: true,
      );

      database.clearNotes();

      final repository = NotesRepository(
        database: database,
      );

      final service = NotesService(
        repository: repository,
      );

      final notesController = NotesController(
        service: service,
      );

      final router = Router()
        ..mount(
          '/v1/notes/',
          notesController.router.call,
        )
        ..get(
          '/v1/feature-flags',
          FeatureFlagsService.handleGet,
        )
        ..get(
          '/health',
          (Request request) {
            return Response.ok('OK');
          },
        );

      final handler = Pipeline()
          .addMiddleware(
            errorMiddleware(),
          )
          .addMiddleware(
            authMiddleware(
              allowedKeys: {
                'sandbox_key',
                'enterprise_key',
              },
            ),
          )
          .addMiddleware(
            rateLimitMiddleware(),
          )
          .addHandler(
            router.call,
          );

      server = await io.serve(
        handler,
        'localhost',
        0,
      );

      port = server.port;

      client = HttpClient();
    });

    tearDown(() async {
      client.close();

      await server.close(
        force: true,
      );
    });

    Future<HttpClientResponse> authorizedGet(
      String path,
    ) async {
      final request = await client.get(
        'localhost',
        port,
        path,
      );

      request.headers.add(
        'X-API-Key',
        apiKey,
      );

      return request.close();
    }

    test(
      'Health endpoint should return 200',
      () async {
        final request = await client.get(
          'localhost',
          port,
          '/health',
        );

        final response = await request.close();

        expect(
          response.statusCode,
          200,
        );
      },
    );

    test(
      'Create note should return 201',
      () async {
        final request = await client.post(
          'localhost',
          port,
          '/v1/notes/',
        );

        request.headers.add(
          'X-API-Key',
          apiKey,
        );

        request.headers.contentType = ContentType.json;

        request.write(
          jsonEncode({
            'title': 'Integration Test',
            'content': 'Testing',
          }),
        );

        final response = await request.close();

        expect(
          response.statusCode,
          201,
        );

        final body = await utf8.decodeStream(
          response,
        );

        final data = jsonDecode(body) as Map<String, dynamic>;

        expect(
          data['title'],
          'Integration Test',
        );
      },
    );

    test(
      'Create note with invalid title should return 400',
      () async {
        final request = await client.post(
          'localhost',
          port,
          '/v1/notes/',
        );

        request.headers.add(
          'X-API-Key',
          apiKey,
        );

        request.headers.contentType = ContentType.json;

        request.write(
          jsonEncode({
            'title': '',
            'content': 'Invalid',
          }),
        );

        final response = await request.close();

        expect(
          response.statusCode,
          400,
        );
      },
    );

    test(
      'List notes should return paginated data',
      () async {
        final response = await authorizedGet(
          '/v1/notes/?page=1&limit=10',
        );

        expect(
          response.statusCode,
          200,
        );

        final body = await utf8.decodeStream(
          response,
        );

        final data = jsonDecode(body) as Map<String, dynamic>;

        expect(
          data['items'],
          isList,
        );

        expect(
          data['page'],
          1,
        );

        expect(
          data['limit'],
          10,
        );
      },
    );

    test(
      'Get note by id should return 200',
      () async {
        final createRequest = await client.post(
          'localhost',
          port,
          '/v1/notes/',
        );

        createRequest.headers.add(
          'X-API-Key',
          apiKey,
        );

        createRequest.headers.contentType = ContentType.json;

        createRequest.write(
          jsonEncode({
            'title': 'Fetch Test',
            'content': 'Fetch Content',
          }),
        );

        final createResponse = await createRequest.close();

        expect(
          createResponse.statusCode,
          201,
        );

        final createBody = await utf8.decodeStream(
          createResponse,
        );

        final createdNote = jsonDecode(createBody) as Map<String, dynamic>;

        final noteId = createdNote['id'];

        final fetchResponse = await authorizedGet(
          '/v1/notes/$noteId',
        );

        expect(
          fetchResponse.statusCode,
          200,
        );
      },
    );

    test(
      'Unknown note should return 404',
      () async {
        final response = await authorizedGet(
          '/v1/notes/unknown-id',
        );

        expect(
          response.statusCode,
          404,
        );
      },
    );

    test(
      'Update note should return updated data',
      () async {
        final createRequest = await client.post(
          'localhost',
          port,
          '/v1/notes/',
        );

        createRequest.headers.add(
          'X-API-Key',
          apiKey,
        );

        createRequest.headers.contentType = ContentType.json;

        createRequest.write(
          jsonEncode({
            'title': 'Old',
            'content': 'Old Content',
          }),
        );

        final createResponse = await createRequest.close();

        final createBody = await utf8.decodeStream(
          createResponse,
        );

        final createdNote = jsonDecode(createBody) as Map<String, dynamic>;

        final noteId = createdNote['id'];

        final updateRequest = await client.put(
          'localhost',
          port,
          '/v1/notes/$noteId',
        );

        updateRequest.headers.add(
          'X-API-Key',
          apiKey,
        );

        updateRequest.headers.contentType = ContentType.json;

        updateRequest.write(
          jsonEncode({
            'title': 'Updated',
            'content': 'Updated Content',
          }),
        );

        final updateResponse = await updateRequest.close();

        expect(
          updateResponse.statusCode,
          200,
        );

        final updateBody = await utf8.decodeStream(
          updateResponse,
        );

        final updatedData = jsonDecode(updateBody) as Map<String, dynamic>;

        expect(
          updatedData['title'],
          'Updated',
        );
      },
    );

    test(
      'Delete note should return 204',
      () async {
        final createRequest = await client.post(
          'localhost',
          port,
          '/v1/notes/',
        );

        createRequest.headers.add(
          'X-API-Key',
          apiKey,
        );

        createRequest.headers.contentType = ContentType.json;

        createRequest.write(
          jsonEncode({
            'title': 'Delete',
            'content': 'Delete Me',
          }),
        );

        final createResponse = await createRequest.close();

        final createBody = await utf8.decodeStream(
          createResponse,
        );

        final createdNote = jsonDecode(createBody) as Map<String, dynamic>;

        final noteId = createdNote['id'];

        final deleteRequest = await client.delete(
          'localhost',
          port,
          '/v1/notes/$noteId',
        );

        deleteRequest.headers.add(
          'X-API-Key',
          apiKey,
        );

        final deleteResponse = await deleteRequest.close();

        expect(
          deleteResponse.statusCode,
          204,
        );
      },
    );

    test(
      'Feature flags endpoint should return features',
      () async {
        final response = await authorizedGet(
          '/v1/feature-flags',
        );

        expect(
          response.statusCode,
          200,
        );

        final body = await utf8.decodeStream(
          response,
        );

        final data = jsonDecode(body) as Map<String, dynamic>;

        expect(
          data['tier'],
          isNotNull,
        );

        expect(
          data['features'],
          isNotNull,
        );
      },
    );

    test(
      'Rate limiter should return 429',
      () async {
        HttpClientResponse? lastResponse;

        for (int i = 0; i < 65; i++) {
          final request = await client.get(
            'localhost',
            port,
            '/v1/notes/',
          );

          request.headers.add(
            'X-API-Key',
            apiKey,
          );

          lastResponse = await request.close();
        }

        expect(
          lastResponse?.statusCode,
          429,
        );
      },
    );
  });
}
