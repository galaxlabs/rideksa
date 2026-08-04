class AppException implements Exception {
  final String message;
  final int? statusCode;
  const AppException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection']);
}

class AuthException extends AppException {
  const AuthException(super.message, {super.statusCode});
}

class ApiException extends AppException {
  const ApiException(super.message, {super.statusCode});
}

class WalletException extends AppException {
  const WalletException(super.message);
}
