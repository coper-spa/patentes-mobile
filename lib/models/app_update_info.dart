enum AppUpdateType { required, optional, none }

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.updateType,
    required this.platform,
    required this.currentVersion,
    required this.buildNumber,
    this.installUrl,
    this.downloadUrl,
    this.title,
    this.message,
  });

  final AppUpdateType updateType;
  final String platform;
  final String currentVersion;
  final String buildNumber;
  final String? installUrl;
  final String? downloadUrl;
  final String? title;
  final String? message;

  String? get targetUrl {
    final primary = installUrl?.trim();
    if (primary != null && primary.isNotEmpty) {
      return primary;
    }

    final fallback = downloadUrl?.trim();
    if (fallback != null && fallback.isNotEmpty) {
      return fallback;
    }

    return null;
  }

  factory AppUpdateInfo.none({
    required String platform,
    required String currentVersion,
    required String buildNumber,
  }) {
    return AppUpdateInfo(
      updateType: AppUpdateType.none,
      platform: platform,
      currentVersion: currentVersion,
      buildNumber: buildNumber,
    );
  }
}
