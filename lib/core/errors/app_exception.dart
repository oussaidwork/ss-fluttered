/// Custom application exception types.
sealed class AppException implements Exception {
  final String message;
  final String? code;

  AppException(this.message, {this.code});

  @override
  String toString() => '$runtimeType: $message${code != null ? ' ($code)' : ''}';
}

/// Authentication-related exceptions.
class AuthException extends AppException {
  AuthException(super.message, {super.code});
}

/// Permission-related exceptions.
class PermissionException extends AppException {
  PermissionException(super.message, {super.code});
}

/// Validation-related exceptions.
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;
  ValidationException(super.message, {this.fieldErrors, super.code});
}

/// Business logic violations.
class BusinessException extends AppException {
  BusinessException(super.message, {super.code});
}

/// Data not found.
class NotFoundException extends AppException {
  NotFoundException(super.message, {super.code});
}