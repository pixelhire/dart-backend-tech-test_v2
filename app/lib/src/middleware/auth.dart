import 'dart:convert';

import 'package:shelf/shelf.dart';

// Reads X-API-Key header and validates against env API_KEYS (colon-separated).
Middleware authMiddleware({
  Set<String>? allowedKeys,
  String? apiKeys,
}) {
  final raw = apiKeys ?? '';
  final envKeys = raw
      .split(':')
      .where(
        (e) => e.trim().isNotEmpty,
      )
      .toSet();

  final resolvedKeys = allowedKeys ?? envKeys;

  return (Handler inner) {
    return (Request req) async {
      // Allow health without auth
      final path = req.url.path;

      if (path == 'health' ||
          path.startsWith('swagger') ||
          path == 'openapi.json') return inner(req);

      final key = req.headers['X-API-Key'];

      if (resolvedKeys.isEmpty) {
        // Allow if not configured (for local dev); candidates can change if desired.
        return Response(
          500,
          body: jsonEncode({
            'error': 'API_KEYS environment variable is not configured',
          }),
          headers: {
            'content-type': 'application/json',
          },
        );
      }
      if (key == null || !resolvedKeys.contains(key)) {
        // return Response(401, body: 'Unauthorized: missing or invalid API key');
        return Response(
          401,
          body: jsonEncode({
            'error': 'Unauthorized: missing or invalid API key',
          }),
          headers: {
            'content-type': 'application/json',
          },
        );
      }
      // Attach key to context
      final ctx = {'apiKey': key};
      return inner(req.change(context: ctx));
    };
  };
}
