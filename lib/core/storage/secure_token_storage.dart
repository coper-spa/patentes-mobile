import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../models/auth_tokens.dart';

class SecureTokenStorage {
  SecureTokenStorage(this._storage);

  static const _tokenKey = 'oauth_tokens';
  final FlutterSecureStorage _storage;

  Future<void> save(AuthTokens tokens) async {
    await _storage.write(key: _tokenKey, value: jsonEncode(tokens.toJson()));
  }

  Future<AuthTokens?> read() async {
    final value = await _storage.read(key: _tokenKey);
    if (value == null || value.isEmpty) {
      return null;
    }

    return AuthTokens.fromJson(jsonDecode(value) as Map<String, dynamic>);
  }

  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
  }
}
