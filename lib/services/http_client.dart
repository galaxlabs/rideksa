import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

/// Uses Dio on web which relies on `fetch` (not XMLHttpRequest), so the
/// `Expect: 100-continue` header is never sent and HTTP/2 works fine.
http.Client createFrappeHttpClient() {
  return _DioHttpClient(Dio(
    BaseOptions(
      followRedirects: true,
      validateStatus: (s) => s != null && s >= 100 && s < 600,
    ),
  ));
}

class _DioHttpClient extends http.BaseClient {
  final Dio _dio;
  _DioHttpClient(this._dio);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final headers = Map<String, String>.from(request.headers);
    final bodyBytes = await request.finalize().toBytes();
    final uri = request.url;

    try {
      final response = await _dio.request<dynamic>(
        uri.toString(),
        options: Options(
          method: request.method,
          headers: headers,
          responseType: ResponseType.plain,
        ),
        data: bodyBytes.isEmpty ? null : bodyBytes,
      );

      final responseHeaders = <String, String>{};
      response.headers.forEach((k, v) {
        responseHeaders[k] = v.toString();
      });

      final data = response.data;
      final bodyStr = data == null ? '' : data.toString();
      final bytes = Uint8List.fromList(utf8.encode(bodyStr));
      return http.StreamedResponse(
        Stream.value(bytes),
        response.statusCode ?? 500,
        headers: responseHeaders,
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 500;
      final bodyStr = e.response?.data?.toString() ?? '';
      final bytes = Uint8List.fromList(utf8.encode(bodyStr));
      return http.StreamedResponse(Stream.value(bytes), status, headers: {});
    }
  }
}
