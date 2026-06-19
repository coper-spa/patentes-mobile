import 'dart:convert';

import 'package:http/http.dart' as http;

import '../errors/app_exception.dart';

typedef RefreshTokenCallback = Future<String?> Function();
typedef AccessTokenProvider = Future<String?> Function();
typedef InspectorSessionProvider = bool Function();
typedef ActiveInspectorGroupProvider = String? Function();

class ApiClient {
  ApiClient({
    required this.httpClient,
    required this.getAccessToken,
    required this.refreshAccessToken,
    required this.isInspectorSession,
    required this.getActiveInspectorGroupId,
  });

  final http.Client httpClient;
  final AccessTokenProvider getAccessToken;
  final RefreshTokenCallback refreshAccessToken;
  final InspectorSessionProvider isInspectorSession;
  final ActiveInspectorGroupProvider getActiveInspectorGroupId;

  Future<Map<String, dynamic>> getJson(Uri uri) async {
    final resolvedUri = _withInspectorGroupQueryIfRequired(uri);
    final response = await _sendAuthorized(
      (headers) => httpClient.get(resolvedUri, headers: headers),
    );
    return _decodeJsonObject(response.body);
  }

  Future<List<dynamic>> getJsonList(Uri uri) async {
    final resolvedUri = _withInspectorGroupQueryIfRequired(uri);
    final response = await _sendAuthorized(
      (headers) => httpClient.get(resolvedUri, headers: headers),
    );
    return _decodeJsonList(response.body);
  }

  Future<Map<String, dynamic>> postJson(
    Uri uri,
    Map<String, dynamic> payload,
  ) async {
    final resolvedUri = _withInspectorGroupQueryIfRequired(uri);
    final resolvedPayload = _withInspectorGroupPayloadIfRequired(
      uri,
      payload,
    );
    final response = await _sendAuthorized(
      (headers) =>
          httpClient.post(
            resolvedUri,
            headers: headers,
            body: jsonEncode(resolvedPayload),
          ),
    );
    return _decodeJsonObject(response.body);
  }

  Future<Map<String, dynamic>> postMultipartFile(
    Uri uri, {
    required String fileField,
    required String filePath,
    Map<String, String>? fields,
  }) async {
    final resolvedUri = _withInspectorGroupQueryIfRequired(uri);
    final token = await getAccessToken();
    if (token == null || token.isEmpty) {
      throw const AppException('No hay sesion activa.');
    }

    var response = await _sendMultipart(
      resolvedUri,
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
        resolvedUri,
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

  Uri _withInspectorGroupQueryIfRequired(Uri uri) {
    if (!_needsInspectorGroupInQuery(uri)) {
      return uri;
    }

    final groupId = _requireActiveInspectorGroupId();
    final query = Map<String, String>.from(uri.queryParameters);
    query.putIfAbsent('inspector_group_id', () => groupId);
    return uri.replace(queryParameters: query);
  }

  Map<String, dynamic> _withInspectorGroupPayloadIfRequired(
    Uri uri,
    Map<String, dynamic> payload,
  ) {
    if (!_needsInspectorGroupInBody(uri)) {
      return payload;
    }

    final groupId = _requireActiveInspectorGroupId();
    final mapped = Map<String, dynamic>.from(payload);
    mapped.putIfAbsent('inspector_group_id', () => groupId);
    return mapped;
  }

  String _requireActiveInspectorGroupId() {
    if (!isInspectorSession()) {
      return '';
    }

    final groupId = getActiveInspectorGroupId()?.trim();
    if (groupId == null || groupId.isEmpty) {
      throw const AppException(
        'Debes seleccionar un grupo inspector activo para continuar.',
      );
    }

    return groupId;
  }

  bool _needsInspectorGroupInQuery(Uri uri) {
    if (!isInspectorSession()) {
      return false;
    }

    final path = _normalizedPath(uri.path);

    final isVisitAssignmentsList = path == '/api/v1/visit-assignments';
    final isVisitAssignmentsDetail = RegExp(
      r'^/api/v1/visit-assignments/[^/]+$',
    ).hasMatch(path);
    final isVisitAssignmentEvidences = RegExp(
      r'^/api/v1/visit-assignments/[^/]+/evidences$',
    ).hasMatch(path);
    final isManagementLogsList = path == '/api/v1/management-logs';
    final isManagementLogsDetail = RegExp(
      r'^/api/v1/management-logs/[^/]+$',
    ).hasMatch(path);
    final isContribuyenteManagementLogs = RegExp(
      r'^/api/v1/contribuyentes/[^/]+/management-logs$',
    ).hasMatch(path);

    return isVisitAssignmentsList ||
        isVisitAssignmentsDetail ||
        isVisitAssignmentEvidences ||
        isManagementLogsList ||
        isManagementLogsDetail ||
        isContribuyenteManagementLogs;
  }

  bool _needsInspectorGroupInBody(Uri uri) {
    if (!isInspectorSession()) {
      return false;
    }

    final path = _normalizedPath(uri.path);
    return path == '/api/v1/management-logs';
  }

  String _normalizedPath(String path) {
    if (path.length > 1 && path.endsWith('/')) {
      return path.substring(0, path.length - 1);
    }

    return path;
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
