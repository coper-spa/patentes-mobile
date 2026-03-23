import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../core/errors/app_exception.dart';
import '../../core/storage/secure_token_storage.dart';
import '../../models/auth_tokens.dart';
import '../../models/inspector_profile.dart';
import '../../services/auth_oauth_service.dart';
import '../auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this.config,
    required this.httpClient,
    required this.storage,
    required this.oauthService,
  });

  final AppConfig config;
  final http.Client httpClient;
  final SecureTokenStorage storage;
  final AuthOAuthService oauthService;

  AuthTokens? _currentTokens;
  static const Duration _requestTimeout = Duration(seconds: 10);

  @override
  Future<void> loginWithPkce() async {
    final tokens = await oauthService.authenticateWithPkce();
    await storage.save(tokens);
    _currentTokens = tokens;
  }

  @override
  Future<void> logout() async {
    final token = (await getStoredTokens())?.accessToken;

    if (token != null && token.isNotEmpty) {
      try {
        await oauthService.revokeToken(token);
      } catch (_) {
        // Si falla el revoke remoto, aun limpiamos sesion local por seguridad.
      }
    }

    await storage.clear();
    _currentTokens = null;
  }

  @override
  Future<bool> restoreSession() async {
    final stored = await storage.read();
    if (stored == null) {
      return false;
    }

    _currentTokens = stored;

    if (_currentTokens!.isExpired) {
      final refreshed = await refreshSession();
      return refreshed != null;
    }

    return true;
  }

  @override
  Future<String?> getValidAccessToken() async {
    final tokens = _currentTokens ?? await storage.read();
    if (tokens == null) {
      return null;
    }

    _currentTokens = tokens;

    if (!tokens.isExpired) {
      return tokens.accessToken;
    }

    return refreshSession();
  }

  @override
  Future<String?> refreshSession() async {
    final tokens = _currentTokens ?? await storage.read();
    if (tokens == null || tokens.refreshToken.isEmpty) {
      await storage.clear();
      _currentTokens = null;
      return null;
    }

    try {
      final refreshed = await oauthService.refreshToken(tokens.refreshToken);
      await storage.save(refreshed);
      _currentTokens = refreshed;
      return refreshed.accessToken;
    } catch (_) {
      await storage.clear();
      _currentTokens = null;
      return null;
    }
  }

  @override
  Future<InspectorProfile> getProfile() async {
    final token = await getValidAccessToken();
    if (token == null) {
      throw const AppException('No hay sesion activa.');
    }

    final response = await httpClient
        .get(
          config.apiUri(config.meEndpoint),
          headers: <String, String>{
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(_requestTimeout, onTimeout: () {
          throw const AppException(
            'Timeout al consultar el perfil del inspector.',
          );
        });

    if (response.statusCode < 200 || response.statusCode > 299) {
      throw AppException(
        'No fue posible obtener perfil de inspector: ${response.body}',
        statusCode: response.statusCode,
      );
    }

    return InspectorProfile.fromJson(_decodeMap(response.body));
  }

  @override
  Future<AuthTokens?> getStoredTokens() async {
    _currentTokens ??= await storage.read();
    return _currentTokens;
  }

  Map<String, dynamic> _decodeMap(String body) {
    final dynamic decoded =
        body.isEmpty ? <String, dynamic>{} : jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw const AppException('Respuesta de perfil invalida.');
  }
}
