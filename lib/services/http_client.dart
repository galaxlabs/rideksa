import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class _WebSafeClient extends http.BaseClient {
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.remove('Expect');
    request.headers['X-Requested-With'] = 'RideKSA';
    return _inner.send(request);
  }
}

http.Client createFrappeHttpClient() {
  if (kIsWeb) return _WebSafeClient();
  return http.Client();
}
