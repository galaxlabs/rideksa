import 'token_storage_secure.dart'
    if (dart.library.html) 'token_storage_web.dart';

abstract class TokenStorage {
  Future<String?> read({required String key});
  Future<void> write({required String key, required String value});
  Future<void> delete({required String key});
}

TokenStorage createTokenStorage() => createPlatformTokenStorage();
