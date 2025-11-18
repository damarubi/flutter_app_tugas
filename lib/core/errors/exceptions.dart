// Custom Exceptions
class ServerException implements Exception {
  final String message;
  ServerException([this.message = 'Server error occurred']);
}

class CacheException implements Exception {
  final String message;
  CacheException([this.message = 'Cache error occurred']);
}

class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'Network error occurred']);
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}

class LocationException implements Exception {
  final String message;
  LocationException(this.message);
}

class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
}
