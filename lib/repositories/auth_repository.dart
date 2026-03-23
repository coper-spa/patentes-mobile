import '../models/auth_tokens.dart';
import '../models/inspector_profile.dart';

abstract class AuthRepository {
  Future<void> loginWithPkce();
  Future<void> logout();
  Future<bool> restoreSession();
  Future<String?> getValidAccessToken();
  Future<String?> refreshSession();
  Future<InspectorProfile> getProfile();
  Future<AuthTokens?> getStoredTokens();
}
