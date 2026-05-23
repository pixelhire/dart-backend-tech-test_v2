import 'package:test/test.dart';

import 'package:dart_backend_tech_test/src/exceptions/api_exception.dart';
import 'package:dart_backend_tech_test/src/utils/validators.dart';

void main() {
  group('Validators Unit Tests', () {
    test(
      'Should allow valid note',
      () {
        expect(
          () => Validators.validateNote(
            title: 'Valid Title',
            content: 'Valid Content',
          ),
          returnsNormally,
        );
      },
    );

    test(
      'Should throw for empty title',
      () {
        expect(
          () => Validators.validateNote(
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
      'Should throw for whitespace title',
      () {
        expect(
          () => Validators.validateNote(
            title: '   ',
            content: 'Content',
          ),
          throwsA(
            isA<BadRequestException>(),
          ),
        );
      },
    );

    test(
      'Should throw for title longer than 120 chars',
      () {
        expect(
          () => Validators.validateNote(
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
      'Should allow title with exactly 120 chars',
      () {
        expect(
          () => Validators.validateNote(
            title: 'A' * 120,
            content: 'Content',
          ),
          returnsNormally,
        );
      },
    );

    test(
      'Should throw for content longer than 10000 chars',
      () {
        expect(
          () => Validators.validateNote(
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
      'Should allow content with exactly 10000 chars',
      () {
        expect(
          () => Validators.validateNote(
            title: 'Valid',
            content: 'A' * 10000,
          ),
          returnsNormally,
        );
      },
    );

    test(
      'Should allow empty content',
      () {
        expect(
          () => Validators.validateNote(
            title: 'Valid',
            content: '',
          ),
          returnsNormally,
        );
      },
    );

    test(
      'Should allow special characters in title',
      () {
        expect(
          () => Validators.validateNote(
            title: 'Hello @#%^&*()',
            content: 'Content',
          ),
          returnsNormally,
        );
      },
    );

    test(
      'Should throw BadRequestException for invalid title',
      () {
        try {
          Validators.validateNote(
            title: '',
            content: 'Content',
          );
        } catch (e) {
          expect(
            e,
            isA<BadRequestException>(),
          );

          expect(
            (e as BadRequestException).statusCode,
            400,
          );
        }
      },
    );
  });
}
