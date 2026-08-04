import 'package:shared_preferences/shared_preferences.dart';
import 'token_storage.dart';

TokenStorage createPlatformTokenStorage() => const SecureTokenStorage();

class SecureTokenStorage implements TokenStorage {
  const SecureTokenStorage();

  @override
  Future<String?> read({required String key}) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(key);
  }

  @override
  Future<void> write({required String key, required String value}) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(key, value);
  }

  @override
  Future<void> delete({required String key}) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(key);
  }
}
