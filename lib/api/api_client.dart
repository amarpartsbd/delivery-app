import 'package:dio/dio.dart';
import '../config.dart';

/// Thin wrapper over Dio. Injects the bearer token and normalises errors
/// into a readable [ApiException].
class ApiClient {
  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
      validateStatus: (s) => s != null && s < 500,
    ));
  }

  late final Dio _dio;
  String? _token;

  void setToken(String? token) => _token = token;

  Options get _auth => Options(headers: _token != null ? {'Authorization': 'Bearer $_token'} : null);

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    return _unwrap(await _dio.get(path, queryParameters: query, options: _auth));
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    return _unwrap(await _dio.post(path, data: body, options: _auth));
  }

  /// Multipart POST with an optional file (for proof-of-delivery photo).
  Future<dynamic> postForm(String path, {Map<String, dynamic>? fields, String? filePath, String fileField = 'proof'}) async {
    final form = FormData.fromMap({
      ...?fields,
      if (filePath != null) fileField: await MultipartFile.fromFile(filePath, filename: 'proof.jpg'),
    });
    return _unwrap(await _dio.post(path, data: form, options: _auth));
  }

  dynamic _unwrap(Response res) {
    final code = res.statusCode ?? 0;
    if (code >= 200 && code < 300) return res.data;

    final data = res.data;
    String message = 'Something went wrong.';
    Map<String, dynamic> errors = {};
    if (data is Map) {
      message = (data['message'] ?? message).toString();
      if (data['errors'] is Map) {
        errors = Map<String, dynamic>.from(data['errors']);
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) message = first.first.toString();
      }
    }
    throw ApiException(message, statusCode: code, errors: errors);
  }
}

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode = 0, this.errors = const {}});
  final String message;
  final int statusCode;
  final Map<String, dynamic> errors;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}
