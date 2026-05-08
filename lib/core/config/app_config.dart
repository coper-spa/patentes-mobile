import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  const AppConfig({
    required this.appTitle,
    required this.appLogoAsset,
    required this.baseApiUrl,
    required this.clientId,
    required this.clientSecret,
    required this.redirectUri,
    required this.scopes,
    required this.authorizeEndpoint,
    required this.tokenEndpoint,
    required this.revokeEndpoint,
    required this.meEndpoint,
    required this.dashboardEndpoint,
    required this.routeByDateEndpoint,
    required this.versionCheckEndpoint,
    required this.inspectionDetailEndpoint,
    required this.inspectionLogEndpoint,
    required this.managementTypesEndpoint,
    required this.managementStatusesEndpoint,
    required this.visitStatesEndpoint,
    required this.contribuyenteManagementLogsEndpoint,
  });

  final String appTitle;
  final String appLogoAsset;
  final String baseApiUrl;
  final String clientId;
  final String clientSecret;
  final String redirectUri;
  final String scopes;

  final String authorizeEndpoint;
  final String tokenEndpoint;
  final String revokeEndpoint;

  final String meEndpoint;
  final String dashboardEndpoint;
  final String versionCheckEndpoint;

  // Usa placeholders: {date} y {inspectionId}
  final String routeByDateEndpoint;
  final String inspectionDetailEndpoint;
  final String inspectionLogEndpoint;
  final String managementTypesEndpoint;
  final String managementStatusesEndpoint;
  final String visitStatesEndpoint;
  final String contribuyenteManagementLogsEndpoint;

  factory AppConfig.fromEnvironment() {
    return AppConfig(
      appTitle: _readValue('APP_TITLE'),
      appLogoAsset: _readValue('APP_LOGO_ASSET'),
      baseApiUrl: _readValue('API_BASE_URL'),
      clientId: _readValue('OAUTH_CLIENT_ID'),
      clientSecret: _readValue('OAUTH_CLIENT_SECRET', defaultValue: ''),
      redirectUri: _readValue('OAUTH_REDIRECT_URI'),
      scopes: _readValue('OAUTH_SCOPES', defaultValue: ''),
      authorizeEndpoint: _readValue('OAUTH_AUTHORIZE_ENDPOINT'),
      tokenEndpoint: _readValue('OAUTH_TOKEN_ENDPOINT'),
      revokeEndpoint: _readValue('OAUTH_REVOKE_ENDPOINT'),
      meEndpoint: _readValue('API_ME_ENDPOINT'),
      dashboardEndpoint: _readValue('API_DASHBOARD_ENDPOINT'),
      versionCheckEndpoint: _readValue(
        'API_VERSION_CHECK_ENDPOINT',
        defaultValue: '/api/v1/app/version-check',
      ),
      routeByDateEndpoint: _readValue('API_ROUTE_BY_DATE_ENDPOINT'),
      inspectionDetailEndpoint: _readValue('API_INSPECTION_DETAIL_ENDPOINT'),
      inspectionLogEndpoint: _readValue('API_INSPECTION_LOG_ENDPOINT'),
      managementTypesEndpoint: _readValue(
        'API_MANAGEMENT_TYPES_ENDPOINT',
        defaultValue: '/api/v1/management-types?per_page=100',
      ),
      managementStatusesEndpoint: _readValue(
        'API_MANAGEMENT_STATUSES_ENDPOINT',
        defaultValue: '/api/v1/management-logs/statuses',
      ),
      visitStatesEndpoint: _readValue(
        'API_VISIT_STATES_ENDPOINT',
        defaultValue: '/api/v1/visit-states',
      ),
      contribuyenteManagementLogsEndpoint: _readValue(
        'API_CONTRIBUYENTE_MANAGEMENT_LOGS_ENDPOINT',
        defaultValue: '/api/v1/contribuyentes/{contribuyenteId}/management-logs',
      ),
    );
  }

  static String _readValue(String key, {String defaultValue = ''}) {
    final dotenvValue = dotenv.env[key];
    if (dotenvValue != null && dotenvValue.trim().isNotEmpty) {
      return dotenvValue.trim();
    }

    return String.fromEnvironment(key, defaultValue: defaultValue).trim();
  }

  Uri apiUri(String path) {
    return Uri.parse('$baseApiUrl$path');
  }

  String routeByDatePath(DateTime date) {
    final formatted =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return routeByDateEndpoint.replaceAll('{date}', formatted);
  }

  String inspectionDetailPath(String inspectionId) {
    return inspectionDetailEndpoint.replaceAll('{inspectionId}', inspectionId);
  }

  String contribuyenteManagementLogsPath(String contribuyenteId) {
    return contribuyenteManagementLogsEndpoint.replaceAll(
      '{contribuyenteId}',
      contribuyenteId,
    );
  }

  void validate() {
    final requiredValues = <String, String>{
      'APP_TITLE': appTitle,
      'APP_LOGO_ASSET': appLogoAsset,
      'API_BASE_URL': baseApiUrl,
      'OAUTH_CLIENT_ID': clientId,
      'OAUTH_REDIRECT_URI': redirectUri,
      'OAUTH_AUTHORIZE_ENDPOINT': authorizeEndpoint,
      'OAUTH_TOKEN_ENDPOINT': tokenEndpoint,
      'OAUTH_REVOKE_ENDPOINT': revokeEndpoint,
      'API_ME_ENDPOINT': meEndpoint,
      'API_DASHBOARD_ENDPOINT': dashboardEndpoint,
      'API_VERSION_CHECK_ENDPOINT': versionCheckEndpoint,
      'API_ROUTE_BY_DATE_ENDPOINT': routeByDateEndpoint,
      'API_INSPECTION_DETAIL_ENDPOINT': inspectionDetailEndpoint,
      'API_INSPECTION_LOG_ENDPOINT': inspectionLogEndpoint,
      'API_MANAGEMENT_TYPES_ENDPOINT': managementTypesEndpoint,
      'API_MANAGEMENT_STATUSES_ENDPOINT': managementStatusesEndpoint,
      'API_VISIT_STATES_ENDPOINT': visitStatesEndpoint,
      'API_CONTRIBUYENTE_MANAGEMENT_LOGS_ENDPOINT':
          contribuyenteManagementLogsEndpoint,
    };

    final missing = requiredValues.entries
        .where((entry) => entry.value.trim().isEmpty)
        .map((entry) => entry.key)
        .toList();

    if (missing.isNotEmpty) {
      throw StateError(
        'Faltan variables de configuracion (${missing.join(', ')}). '
        'Define las llaves en .env o usando --dart-define.',
      );
    }
  }
}
