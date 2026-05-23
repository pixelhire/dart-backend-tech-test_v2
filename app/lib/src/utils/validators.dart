import '../exceptions/api_exception.dart';

class Validators {
  static void validateNote({
    required String title,
    required String content,
  }) {
    if (title.trim().isEmpty || title.length > 120) {
      throw BadRequestException(
        'Title must be between 1 and 120 characters',
      );
    }

    if (content.length > 10000) {
      throw BadRequestException(
        'Content exceeds 10000 characters',
      );
    }
  }
}
