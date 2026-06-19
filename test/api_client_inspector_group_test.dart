import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:inspectores_municipales_app/core/network/api_client.dart';

class _RecordingHttpClient extends http.BaseClient {
  _RecordingHttpClient(this._handler);

  final Future<http.Response> Function(http.BaseRequest request) _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _handler(request);
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(response.body)),
      response.statusCode,
      headers: response.headers,
      reasonPhrase: response.reasonPhrase,
      request: request,
    );
  }
}

void main() {
  group('ApiClient inspector_group_id propagation', () {
    test('injects inspector_group_id as query param for visit assignments', () async {
      Uri? requestedUri;
      final client = _RecordingHttpClient((request) async {
        requestedUri = request.url;
        return http.Response('{}', 200);
      });

      final apiClient = ApiClient(
        httpClient: client,
        getAccessToken: () async => 'token',
        refreshAccessToken: () async => null,
        isInspectorSession: () => true,
        getActiveInspectorGroupId: () => '77',
      );

      await apiClient.getJson(Uri.parse('https://example.test/api/v1/visit-assignments'));

      expect(requestedUri, isNotNull);
      expect(requestedUri!.queryParameters['inspector_group_id'], '77');
    });

    test('injects inspector_group_id into management log payload body', () async {
      String? body;
      final client = _RecordingHttpClient((request) async {
        body = (request as http.Request).body;
        return http.Response('{}', 200);
      });

      final apiClient = ApiClient(
        httpClient: client,
        getAccessToken: () async => 'token',
        refreshAccessToken: () async => null,
        isInspectorSession: () => true,
        getActiveInspectorGroupId: () => '99',
      );

      await apiClient.postJson(
        Uri.parse('https://example.test/api/v1/management-logs'),
        <String, dynamic>{'observation': 'ok'},
      );

      final decoded = jsonDecode(body!) as Map<String, dynamic>;
      expect(decoded['inspector_group_id'], '99');
      expect(decoded['observation'], 'ok');
    });
  });
}
