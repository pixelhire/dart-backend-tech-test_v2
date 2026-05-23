import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:dart_backend_tech_test/src/middleware/auth.dart';
import 'package:dart_backend_tech_test/src/middleware/rate_limit.dart';
import 'package:dart_backend_tech_test/src/middleware/logging.dart';
import 'package:dart_backend_tech_test/src/controllers/notes_controller.dart';
import 'package:dart_backend_tech_test/src/services/feature_flags.dart';
import 'package:shelf_swagger_ui/shelf_swagger_ui.dart';
import 'package:dotenv/dotenv.dart' as dotenv;

void main(List<String> args) async {
  final env = dotenv.DotEnv(includePlatformEnvironment: true)..load();
  final apiKeys = env['API_KEYS'];

  final port = int.tryParse(
        env['PORT'] ?? '8080',
      ) ??
      8080;

  final router = Router();
  final openApiSpec = File('openapi.json').readAsStringSync();

  // print("API_KEYS  $API_KEYS");

  // Healthcheck
  router.get('/health', (Request req) async {
    return Response.ok('ok', headers: {'content-type': 'text/plain'});
  });

  // Feature flags
  router.get('/v1/feature-flags', FeatureFlagsService.handleGet);

  router.mount(
    '/swagger/',
    SwaggerUI(openApiSpec).call,
  );
  // Notes CRUD
  final notes = NotesController();
  router.mount('/v1/notes', notes.router.call);

  // Pipeline
  final handler = const Pipeline()
      .addMiddleware(logRequestsCustom())
      .addMiddleware(authMiddleware(
        apiKeys: apiKeys,
      ))
      .addMiddleware(rateLimitMiddleware())
      .addHandler(router.call);

  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  print('🚀 Server listening on port ${server.port}');
}
