import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../exceptions/api_exception.dart';

Middleware errorMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      try {
        return await innerHandler(request);
      } on ApiException catch (e) {
        return Response(
          e.statusCode,
          body: jsonEncode({
            'error': e.message,
          }),
          headers: {
            'content-type': 'application/json',
          },
        );
      } catch (e, stackTrace) {
        print(
          jsonEncode({
            'error': e.toString(),
            'stackTrace': stackTrace.toString(),
          }),
        );

        return Response.internalServerError(
          body: jsonEncode({
            'error': 'Internal Server Error',
          }),
          headers: {
            'content-type': 'application/json',
          },
        );
      }
    };
  };
}
