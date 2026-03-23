class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.tokenType,
    required this.scope,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final String tokenType;
  final String scope;

  bool get isExpired {
    final threshold = expiresAt.subtract(const Duration(seconds: 30));
    return DateTime.now().isAfter(threshold);
  }

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      tokenType: json['token_type'] as String,
      scope: (json['scope'] ?? '') as String,
    );
  }

  factory AuthTokens.fromTokenResponse(Map<String, dynamic> json) {
    final expiresIn = (json['expires_in'] as num?)?.toInt() ?? 3600;
    final expiresAt = DateTime.now().add(Duration(seconds: expiresIn));

    return AuthTokens(
      accessToken: (json['access_token'] ?? '') as String,
      refreshToken: (json['refresh_token'] ?? '') as String,
      expiresAt: expiresAt,
      tokenType: (json['token_type'] ?? 'Bearer') as String,
      scope: (json['scope'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_at': expiresAt.toIso8601String(),
      'token_type': tokenType,
      'scope': scope,
    };
  }
}
