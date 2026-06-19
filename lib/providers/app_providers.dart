import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../core/storage/inspector_group_storage.dart';
import '../core/storage/secure_token_storage.dart';
import 'inspector_group_session_state.dart';
import '../repositories/auth_repository.dart';
import '../repositories/impl/auth_repository_impl.dart';
import '../repositories/impl/inspection_log_repository_impl.dart';
import '../repositories/impl/inspector_repository_impl.dart';
import '../repositories/inspection_log_repository.dart';
import '../repositories/inspector_repository.dart';
import '../services/app_update_service.dart';
import '../services/auth_oauth_service.dart';
import '../services/device_location_service.dart';
import '../services/external_navigation_service.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  final config = AppConfig.fromEnvironment();
  config.validate();
  return config;
});

final httpClientProvider = Provider<http.Client>((ref) {
  return http.Client();
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final secureTokenStorageProvider = Provider<SecureTokenStorage>((ref) {
  return SecureTokenStorage(ref.watch(secureStorageProvider));
});

final inspectorGroupStorageProvider = Provider<InspectorGroupStorage>((ref) {
  return SecureInspectorGroupStorage(ref.watch(secureStorageProvider));
});

final inspectorGroupSessionProvider =
    StateNotifierProvider<InspectorGroupSessionNotifier,
        InspectorGroupSessionState>((ref) {
      return InspectorGroupSessionNotifier(
        ref.watch(inspectorGroupStorageProvider),
      );
    });

final authOAuthServiceProvider = Provider<AuthOAuthService>((ref) {
  return AuthOAuthService(
    config: ref.watch(appConfigProvider),
    httpClient: ref.watch(httpClientProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    config: ref.watch(appConfigProvider),
    httpClient: ref.watch(httpClientProvider),
    storage: ref.watch(secureTokenStorageProvider),
    oauthService: ref.watch(authOAuthServiceProvider),
  );
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return ApiClient(
    httpClient: ref.watch(httpClientProvider),
    getAccessToken: authRepository.getValidAccessToken,
    refreshAccessToken: authRepository.refreshSession,
    isInspectorSession: () => ref.read(inspectorGroupSessionProvider).isInspector,
    getActiveInspectorGroupId: () =>
        ref.read(inspectorGroupSessionProvider).activeGroupId,
  );
});

final inspectorRepositoryProvider = Provider<InspectorRepository>((ref) {
  return InspectorRepositoryImpl(
    config: ref.watch(appConfigProvider),
    apiClient: ref.watch(apiClientProvider),
  );
});

final inspectionLogRepositoryProvider = Provider<InspectionLogRepository>((
  ref,
) {
  return InspectionLogRepositoryImpl(
    config: ref.watch(appConfigProvider),
    apiClient: ref.watch(apiClientProvider),
  );
});

final externalNavigationServiceProvider = Provider<ExternalNavigationService>((
  ref,
) {
  return ExternalNavigationService();
});

final deviceLocationServiceProvider = Provider<DeviceLocationService>((ref) {
  return GeolocatorDeviceLocationService();
});

final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  return AppUpdateService(
    config: ref.watch(appConfigProvider),
    httpClient: ref.watch(httpClientProvider),
  );
});
