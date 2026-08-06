import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

class _NoExpectBrowserClient extends http.BaseClient {
  final BrowserClient _inner = BrowserClient()..withCredentials = true;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.remove('Expect');
    return _inner.send(request);
  }
}

http.Client createFrappeHttpClient() => _NoExpectBrowserClient();
