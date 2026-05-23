import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../services/notes_service.dart';

class NotesController {
  late final NotesService _service;

  NotesController({
    NotesService? service,
  }) {
    _service = service ?? NotesService();
  }

  Router get router {
    final r = Router();

    r.get('/', _list);
    r.post('/', _create);
    r.get('/<id>', _get);
    r.put('/<id>', _update);
    r.delete('/<id>', _delete);

    return r;
  }

  Future<Response> _list(
    Request request,
  ) async {
    final query = request.requestedUri.queryParameters;
    final page = int.tryParse(query['page'] ?? '1') ?? 1;
    final limit = int.tryParse(query['limit'] ?? '20') ?? 20;

    final result = await _service.getAll(
      page: page,
      limit: limit,
    );

    return Response.ok(
      jsonEncode(result),
      headers: {
        'content-type': 'application/json',
      },
    );
  }

  Future<Response> _create(
    Request request,
  ) async {
    final body = jsonDecode(
      await request.readAsString(),
    ) as Map<String, dynamic>;

    final note = await _service.create(
      title: (body['title'] ?? '').toString(),
      content: (body['content'] ?? '').toString(),
    );

    return Response(
      201,
      body: jsonEncode(
        note.toJson(),
      ),
      headers: {
        'content-type': 'application/json',
      },
    );
  }

  Future<Response> _get(
    Request request,
    String id,
  ) async {
    final note = await _service.getById(id);

    return Response.ok(
      jsonEncode(
        note.toJson(),
      ),
      headers: {
        'content-type': 'application/json',
      },
    );
  }

  Future<Response> _update(
    Request request,
    String id,
  ) async {
    final body = jsonDecode(
      await request.readAsString(),
    ) as Map<String, dynamic>;

    final note = await _service.update(
      id: id,
      title: (body['title'] ?? '').toString(),
      content: (body['content'] ?? '').toString(),
    );

    return Response.ok(
      jsonEncode(
        note.toJson(),
      ),
      headers: {
        'content-type': 'application/json',
      },
    );
  }

  Future<Response> _delete(
    Request request,
    String id,
  ) async {
    await _service.delete(id);

    return Response(204);
  }
}
