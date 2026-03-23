import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config/app_config.dart';
import '../core/errors/app_exception.dart';
import '../core/security/pkce_util.dart';
import '../models/auth_tokens.dart';

class AuthOAuthService {
  AuthOAuthService({required this.config, required this.httpClient});

  final AppConfig config;
  final http.Client httpClient;

  Future<AuthTokens> authenticateWithPkce() async {
    final pkce = PkceUtil.generate();
    final state = PkceUtil.randomState();
    final authUri = _buildAuthorizationUri(pkce.codeChallenge, state);

    final authorizationCode = await _launchAndWaitForAuthorizationCode(
      authUri,
      state,
    );
    return exchangeCodeForToken(authorizationCode, pkce.codeVerifier);
  }

  Future<AuthTokens> exchangeCodeForToken(
    String code,
    String codeVerifier,
  ) async {
    final baseBody = <String, String>{
      'grant_type': 'authorization_code',
      'client_id': config.clientId,
      'redirect_uri': config.redirectUri,
      'code_verifier': codeVerifier,
      'code': code,
    };

    return _requestTokens(baseBody, action: 'intercambiar authorization code');
  }

  Future<AuthTokens> refreshToken(String refreshToken) async {
    final baseBody = <String, String>{
      'grant_type': 'refresh_token',
      'client_id': config.clientId,
      'refresh_token': refreshToken,
    };

    return _requestTokens(baseBody, action: 'refrescar sesion');
  }

  Future<AuthTokens> _requestTokens(
    Map<String, String> baseBody, {
    required String action,
  }) async {
    var response = await _postTokenRequest(baseBody, includeClientSecret: true);

    // Algunos backends con PKCE usan clientes publicos y rechazan client_secret.
    if (_isInvalidClientResponse(response) && config.clientSecret.isNotEmpty) {
      response = await _postTokenRequest(baseBody, includeClientSecret: false);
    }

    if (response.statusCode < 200 || response.statusCode > 299) {
      throw AppException(
        'No fue posible $action: ${response.body}',
        statusCode: response.statusCode,
      );
    }

    return AuthTokens.fromTokenResponse(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<http.Response> _postTokenRequest(
    Map<String, String> baseBody, {
    required bool includeClientSecret,
  }) {
    final body = <String, String>{...baseBody};
    if (includeClientSecret && config.clientSecret.isNotEmpty) {
      body['client_secret'] = config.clientSecret;
    }

    return httpClient.post(
      Uri.parse(config.tokenEndpoint),
      headers: <String, String>{'Accept': 'application/json'},
      body: body,
    );
  }

  bool _isInvalidClientResponse(http.Response response) {
    if (response.statusCode != 400 && response.statusCode != 401) {
      return false;
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error']?.toString().toLowerCase();
        return error == 'invalid_client';
      }
    } catch (_) {
      return false;
    }

    return false;
  }

  Future<void> revokeToken(String accessToken) async {
    final response = await httpClient.post(
      Uri.parse(config.revokeEndpoint),
      headers: <String, String>{
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: <String, String>{'token': accessToken},
    );

    if (response.statusCode < 200 || response.statusCode > 299) {
      throw AppException(
        'No fue posible cerrar sesion de forma remota: ${response.body}',
        statusCode: response.statusCode,
      );
    }
  }

  Uri _buildAuthorizationUri(String codeChallenge, String state) {
    final uri = Uri.parse(config.authorizeEndpoint);
    final params = <String, String>{
      ...uri.queryParameters,
      'response_type': 'code',
      'client_id': config.clientId,
      'redirect_uri': config.redirectUri,
      'scope': config.scopes,
      'state': state,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
    };

    return uri.replace(queryParameters: params);
  }

  Future<String> _launchAndWaitForAuthorizationCode(
    Uri authUri,
    String expectedState,
  ) async {
    final initialUri = await getInitialUri();
    if (_isCallbackUri(initialUri)) {
      return _extractCodeOrThrow(initialUri!, expectedState);
    }

    final completer = Completer<String>();
    late final StreamSubscription<Uri?> sub;
    sub = uriLinkStream.listen(
      (uri) {
        if (uri == null || !_isCallbackUri(uri)) {
          return;
        }

        if (!completer.isCompleted) {
          completer.complete(_extractCodeOrThrow(uri, expectedState));
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(
            AppException('Error capturando callback OAuth: $error'),
          );
        }
      },
    );

    final launched = await launchUrl(
      authUri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      await sub.cancel();
      throw const AppException(
        'No se pudo abrir el navegador para autenticar.',
      );
    }

    try {
      return await completer.future.timeout(const Duration(minutes: 3));
    } on TimeoutException {
      throw const AppException(
        'Tiempo de espera agotado en autenticacion OAuth.',
      );
    } finally {
      await sub.cancel();
    }
  }

  bool _isCallbackUri(Uri? uri) {
    if (uri == null) {
      return false;
    }

    final redirect = Uri.parse(config.redirectUri);
    return uri.scheme == redirect.scheme && uri.host == redirect.host;
  }

  String _extractCodeOrThrow(Uri uri, String expectedState) {
    if (uri.queryParameters.containsKey('error')) {
      throw AppException(
        'Autenticacion cancelada: ${uri.queryParameters['error_description'] ?? uri.queryParameters['error']}',
      );
    }

    final state = uri.queryParameters['state'];
    if (state == null || state != expectedState) {
      throw const AppException('State OAuth invalido.');
    }

    final code = uri.queryParameters['code'];
    if (code == null || code.isEmpty) {
      throw const AppException('No se recibio authorization code.');
    }

    return code;
  }
}
