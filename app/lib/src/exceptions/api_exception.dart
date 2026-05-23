class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({
    required this.statusCode,
    required this.message,
  });
}

class BadRequestException extends ApiException {
  BadRequestException(String message)
      : super(
          statusCode: 400,
          message: message,
        );
}

class NotFoundException extends ApiException {
  NotFoundException(String message)
      : super(
          statusCode: 404,
          message: message,
        );
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(String message)
      : super(
          statusCode: 401,
          message: message,
        );
}

class RateLimitException extends ApiException {
  RateLimitException(String message)
      : super(
          statusCode: 429,
          message: message,
        );
}
