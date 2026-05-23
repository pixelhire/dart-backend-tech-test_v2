import 'dart:convert';
import 'package:shelf/shelf.dart';

enum Tier { sandbox, standard, enhanced, enterprise }

Tier _tierForKey(String? apiKey) {
  // naive mapping by suffix; candidates can implement env mapping
  if (apiKey == null) return Tier.sandbox;
  if (apiKey.contains('enterprise')) return Tier.enterprise;
  if (apiKey.contains('enhanced')) return Tier.enhanced;
  if (apiKey.contains('standard')) return Tier.standard;
  return Tier.sandbox;
}

class FeatureFlagsService {
  static Future<Response> handleGet(Request req) async {
    final apiKey = req.context['apiKey'] as String?;
    final tier = _tierForKey(apiKey);

    final flags = switch (tier) {
      Tier.sandbox => {
          'tier': 'Sandbox',
          'features': {
            'notesCrud': true,
            'oauth': false,
            'advancedReports': false,
          }
        },
      Tier.standard => {
          'tier': 'Standard',
          'features': {
            'notesCrud': true,
            'oauth': true,
            'advancedReports': false,
          }
        },
      Tier.enhanced => {
          'tier': 'Enhanced',
          'features': {
            'notesCrud': true,
            'oauth': true,
            'advancedReports': true,
          }
        },
      Tier.enterprise => {
          'tier': 'Enterprise',
          'features': {
            'notesCrud': true,
            'oauth': true,
            'advancedReports': true,
            'ssoSaml': true,
          }
        },
    };

    return Response.ok(jsonEncode(flags),
        headers: {'content-type': 'application/json'});
  }
}
