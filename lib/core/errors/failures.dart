// Base Failure class
abstract class Failure {
  final String message;
  const Failure(this.message);
}

// Concrete Failures
class ServerFailure extends Failure {
  const ServerFailure([String message = 'Server error occurred'])
    : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure([String message = 'Cache error occurred'])
    : super(message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Network error occurred'])
    : super(message);
}

class AuthFailure extends Failure {
  const AuthFailure(String message) : super(message);
}

class LocationFailure extends Failure {
  const LocationFailure(String message) : super(message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);
}
