import 'dart:html' as html;
import 'token_storage.dart';

TokenStorage createPlatformTokenStorage() => const WebTokenStorage();

class WebTokenStorage implements TokenStorage {
  const WebTokenStorage();

  static const _prefix = 'rideksa_';

  @override
  Future<String?> read({required String key}) async =>
      html.window.localStorage['$_prefix$key'];

  @override
  Future<void> write({required String key, required String value}) async {
    html.window.localStorage['$_prefix$key'] = value;
  }

  @override
  Future<void> delete({required String key}) async {
    html.window.localStorage.remove('$_prefix$key');
  }
}
