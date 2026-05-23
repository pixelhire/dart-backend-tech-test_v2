import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'package:dart_backend_tech_test/src/middleware/rate_limit.dart';

void main() {
  group('Rate Limit Middleware Unit Tests', () {
    late Handler handler;

    setUp(() {
      clearRateLimitBuckets();

      handler = const Pipeline()
          .addMiddleware(
        rateLimitMiddleware(
          max: 3,
          windowSec: 60,
        ),
      )
          .addHandler(
        (Request request) {
          return Response.ok(
            jsonEncode({
              'success': true,
            }),
            headers: {
              'content-type': 'application/json',
            },
          );
        },
      );
    });

    test(
      'Should allow requests within limit',
      () async {
        for (int i = 0; i < 3; i++) {
          final request = Request(
            'GET',
            Uri.parse(
              'http://localhost/v1/notes',
            ),
            context: {
              'apiKey': 'sandbox_key',
            },
          );

          final response = await handler(request);

          expect(
            response.statusCode,
            200,
          );
        }
      },
    );

    test(
      'Should return 429 when limit exceeded',
      () async {
        Response? lastResponse;

        for (int i = 0; i < 4; i++) {
          final request = Request(
            'GET',
            Uri.parse(
              'http://localhost/v1/notes',
            ),
            context: {
              'apiKey': 'sandbox_key',
            },
          );

          lastResponse = await handler(request);
        }

        expect(
          lastResponse?.statusCode,
          429,
        );
      },
    );

    test(
      'Should include Retry-After header',
      () async {
        Response? lastResponse;

        for (int i = 0; i < 4; i++) {
          final request = Request(
            'GET',
            Uri.parse(
              'http://localhost/v1/notes',
            ),
            context: {
              'apiKey': 'sandbox_key',
            },
          );

          lastResponse = await handler(request);
        }

        expect(
          lastResponse?.headers['Retry-After'],
          isNotNull,
        );
      },
    );

    test(
      'Different API keys should have separate limits',
      () async {
        for (int i = 0; i < 3; i++) {
          final request = Request(
            'GET',
            Uri.parse(
              'http://localhost/v1/notes',
            ),
            context: {
              'apiKey': 'sandbox_key',
            },
          );

          final response = await handler(request);

          expect(
            response.statusCode,
            200,
          );
        }

        final secondKeyRequest = Request(
          'GET',
          Uri.parse(
            'http://localhost/v1/notes',
          ),
          context: {
            'apiKey': 'enterprise_key',
          },
        );

        final secondKeyResponse = await handler(
          secondKeyRequest,
        );

        expect(
          secondKeyResponse.statusCode,
          200,
        );
      },
    );

    test(
      'Exceeded limit response should return plain text',
      () async {
        Response? lastResponse;

        for (int i = 0; i < 4; i++) {
          final request = Request(
            'GET',
            Uri.parse(
              'http://localhost/v1/notes',
            ),
            context: {
              'apiKey': 'sandbox_key',
            },
          );

          lastResponse = await handler(request);
        }

        final body = await lastResponse?.readAsString();

        expect(
          body,
          'Rate limit exceeded',
        );
      },
    );
  });
}
