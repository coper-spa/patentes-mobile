import 'dart:convert';

import 'package:http/http.dart' as http;

import '../errors/app_exception.dart';

typedef RefreshTokenCallback = Future<String?> Function();
typedef AccessTokenProvider = Future<String?> Function();

class ApiClient {
  ApiClient({
    required this.httpClient,
    required this.getAccessToken,
    required this.refreshAccessToken,
  });

  final http.Client httpClient;
  final AccessTokenProvider getAccessToken;
  final RefreshTokenCallback refreshAccessToken;

  Future<Map<String, dynamic>> getJson(Uri uri) async {
    final response = await _sendAuthorized(
      (headers) => httpClient.get(uri, headers: headers),
    );
    return _decodeJsonObject(response.body);
  }

  Future<List<dynamic>> getJsonList(Uri uri) async {
    final response = await _sendAuthorized(
      (headers) => httpClient.get(uri, headers: headers),
    );
    return _decodeJsonList(response.body);
  }

  Future<Map<String, dynamic>> postJson(
    Uri uri,
    Map<String, dynamic> payload,
  ) async {
    final response = await _sendAuthorized(
      (headers) =>
          httpClient.post(uri, headers: headers, body: jsonEncode(payload)),
    );
    return _decodeJsonObject(response.body);
  }

  Future<Map<String, dynamic>> postMultipartFile(
    Uri uri, {
    required String fileField,
    required String filePath,
    Map<String, String>? fields,
  }) async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) {
      throw const AppException('No hay sesion activa.');
    }

    var response = await _sendMultipart(
      uri,
      token: token,
      fileField: fileField,
      filePath: filePath,
      fields: fields,
    );

    if (response.statusCode == 401) {
      final newToken = await refreshAccessToken();
      if (newToken == null || newToken.isEmpty) {
        throw const AppException(
          'Sesion expirada. Inicia sesion nuevamente.',
          statusCode: 401,
        );
      }

      response = await _sendMultipart(
        uri,
        token: newToken,
        fileField: fileField,
        filePath: filePath,
        fields: fields,
      );
    }

    final body = await response.stream.bytesToString();

    if (response.statusCode < 200 || response.statusCode > 299) {
      throw AppException(
        'Error de API: $body',
        statusCode: response.statusCode,
      );
    }

    if (body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    return _decodeJsonObject(body);
  }

  Future<http.StreamedResponse> _sendMultipart(
    Uri uri, {
    required String token,
    required String fileField,
    required String filePath,
    Map<String, String>? fields,
  }) async {
    final request = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = 'Bearer $token';

    if (fields != null && fields.isNotEmpty) {
      request.fields.addAll(fields);
    }

    request.files.add(await http.MultipartFile.fromPath(fileField, filePath));

    return request.send();
  }

  Future<http.Response> _sendAuthorized(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) {
      throw const AppException('No hay sesion activa.');
    }

    var response = await request(_headers(token));

    if (response.statusCode == 401) {
      final newToken = await refreshAccessToken();
      if (newToken == null || newToken.isEmpty) {
        throw const AppException(
          'Sesion expirada. Inicia sesion nuevamente.',
          statusCode: 401,
        );
      }

      response = await request(_headers(newToken));
    }

    if (response.statusCode < 200 || response.statusCode > 299) {
      throw AppException(
        'Error de API: ${response.body}',
        statusCode: response.statusCode,
      );
    }

    return response;
  }

  Map<String, String> _headers(String token) {
    return <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decodeJsonObject(String source) {
    if (source.isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const AppException('Respuesta invalida del servidor.');
    }

    return decoded;
  }

  List<dynamic> _decodeJsonList(String source) {
    if (source.isEmpty) {
      return <dynamic>[];
    }

    final decoded = jsonDecode(source);
    if (decoded is! List<dynamic>) {
      throw const AppException('Respuesta invalida del servidor.');
    }

    return decoded;
  }
}
