import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../core/config/app_config.dart';
import '../models/app_update_info.dart';

class AppUpdateService {
  AppUpdateService({required this.config, required this.httpClient});

  final AppConfig config;
  final http.Client httpClient;

  Future<AppUpdateInfo> checkForUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final platform = _resolvePlatform();
    final currentVersion = packageInfo.version.trim();
    final buildNumber = packageInfo.buildNumber.trim();

    if (platform == null) {
      _logCheck(
        platform: 'unsupported',
        currentVersion: currentVersion,
        updateType: AppUpdateType.none,
      );
      return AppUpdateInfo.none(
        platform: 'unsupported',
        currentVersion: currentVersion,
        buildNumber: buildNumber,
      );
    }

    try {
      final endpoint = config.apiUri(config.versionCheckEndpoint);
      final uri = endpoint.replace(
        queryParameters: <String, String>{
          ...endpoint.queryParameters,
          'platform': platform,
          'app_version': currentVersion,
          'build_number': buildNumber,
        },
      );

      final response = await httpClient.get(
        uri,
        headers: const <String, String>{'Accept': 'application/json'},
      );

      if (response.statusCode < 200 || response.statusCode > 299) {
        _logCheck(
          platform: platform,
          currentVersion: currentVersion,
          updateType: AppUpdateType.none,
          details: 'http_status=${response.statusCode}',
        );
        return AppUpdateInfo.none(
          platform: platform,
          currentVersion: currentVersion,
          buildNumber: buildNumber,
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        _logCheck(
          platform: platform,
          currentVersion: currentVersion,
          updateType: AppUpdateType.none,
          details: 'invalid_json_shape',
        );
        return AppUpdateInfo.none(
          platform: platform,
          currentVersion: currentVersion,
          buildNumber: buildNumber,
        );
      }

      final payload = _platformPayload(decoded, platform);
      final updateType = _parseUpdateType(payload['update_type']);

      final info = AppUpdateInfo(
        updateType: updateType,
        platform: platform,
        currentVersion: currentVersion,
        buildNumber: buildNumber,
        installUrl: _toText(payload['install_url']),
        downloadUrl: _toText(payload['download_url']),
        title: _toText(payload['title']),
        message: _toText(payload['message']),
      );

      _logCheck(
        platform: platform,
        currentVersion: currentVersion,
        updateType: info.updateType,
      );

      return info;
    } catch (e) {
      _logCheck(
        platform: platform,
        currentVersion: currentVersion,
        updateType: AppUpdateType.none,
        details: 'exception=$e',
      );
      return AppUpdateInfo.none(
        platform: platform,
        currentVersion: currentVersion,
        buildNumber: buildNumber,
      );
    }
  }

  Map<String, dynamic> _platformPayload(
    Map<String, dynamic> root,
    String platform,
  ) {
    final direct = root[platform];
    if (direct is Map<String, dynamic>) {
      return direct;
    }

    final data = root['data'];
    if (data is Map<String, dynamic>) {
      final nestedByPlatform = data[platform];
      if (nestedByPlatform is Map<String, dynamic>) {
        return nestedByPlatform;
      }

      if (data['update_type'] != null) {
        return data;
      }
    }

    if (root['update_type'] != null) {
      return root;
    }

    return <String, dynamic>{};
  }

  AppUpdateType _parseUpdateType(Object? value) {
    final raw = (value ?? '').toString().trim().toLowerCase();
    switch (raw) {
      case 'required':
        return AppUpdateType.required;
      case 'optional':
        return AppUpdateType.optional;
      default:
        return AppUpdateType.none;
    }
  }

  String? _resolvePlatform() {
    if (Platform.isAndroid) {
      return 'android';
    }

    if (Platform.isIOS) {
      return 'ios';
    }

    return null;
  }

  String? _toText(Object? value) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? null : text;
  }

  void _logCheck({
    required String platform,
    required String currentVersion,
    required AppUpdateType updateType,
    String? details,
  }) {
    final suffix = details == null || details.trim().isEmpty
        ? ''
        : ' $details';

    developer.log(
      'platform=$platform current_version=$currentVersion update_type=${updateType.name}$suffix',
      name: 'AppUpdateService.versionCheck',
    );
  }
}
