import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'package:dart_backend_tech_test/src/middleware/auth.dart';

void main() {
  group('Auth Middleware Unit Tests', () {
    late Handler handler;

    setUp(() {
      handler = const Pipeline()
          .addMiddleware(
        authMiddleware(
          allowedKeys: {
            'sandbox_key',
            'enterprise_key',
          },
        ),
      )
          .addHandler(
        (Request request) {
          final apiKey = request.context['apiKey'];

          return Response.ok(
            jsonEncode({
              'success': true,
              'apiKey': apiKey,
            }),
            headers: {
              'content-type': 'application/json',
            },
          );
        },
      );
    });

    test(
      'Should allow health endpoint without auth',
      () async {
        final request = Request(
          'GET',
          Uri.parse(
            'http://localhost/health',
          ),
        );

        final response = await handler(request);

        expect(
          response.statusCode,
          200,
        );
      },
    );

    test(
      'Should allow swagger endpoint without auth',
      () async {
        final request = Request(
          'GET',
          Uri.parse(
            'http://localhost/swagger',
          ),
        );

        final response = await handler(request);

        expect(
          response.statusCode,
          200,
        );
      },
    );

    test(
      'Should allow openapi endpoint without auth',
      () async {
        final request = Request(
          'GET',
          Uri.parse(
            'http://localhost/openapi.json',
          ),
        );

        final response = await handler(request);

        expect(
          response.statusCode,
          200,
        );
      },
    );

    test(
      'Should attach apiKey to request context',
      () async {
        final middleware = authMiddleware(
          allowedKeys: {
            'sandbox_key',
          },
        );

        final innerHandler = middleware(
          (Request request) {
            final apiKey = request.context['apiKey'];

            return Response.ok(
              jsonEncode({
                'apiKey': apiKey,
              }),
            );
          },
        );

        final request = Request(
          'GET',
          Uri.parse(
            'http://localhost/v1/notes',
          ),
          headers: {
            'X-API-Key': 'sandbox_key',
          },
        );

        final response = await innerHandler(request);

        final body = await response.readAsString();

        final data = jsonDecode(body) as Map<String, dynamic>;

        expect(
          data['apiKey'],
          'sandbox_key',
        );
      },
    );

    test(
      'Unauthorized response should return JSON',
      () async {
        final request = Request(
          'GET',
          Uri.parse(
            'http://localhost/v1/notes',
          ),
        );

        final response = await handler(request);

        expect(
          response.headers['content-type'],
          contains(
            'application/json',
          ),
        );
      },
    );
  });
}
