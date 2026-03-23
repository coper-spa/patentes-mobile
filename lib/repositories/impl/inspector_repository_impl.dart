import 'dart:convert';
import 'dart:developer' as developer;

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../models/route_day_summary.dart';
import '../inspector_repository.dart';

class InspectorRepositoryImpl implements InspectorRepository {
  InspectorRepositoryImpl({required this.config, required this.apiClient});

  final AppConfig config;
  final ApiClient apiClient;

  @override
  Future<RouteDaySummary> getDashboardSummary() async {
    final json = await apiClient.getJson(
      config.apiUri(config.dashboardEndpoint),
    );
    _logApiPayload('dashboard', json);

    final summary = RouteDaySummary.fromJson(json);
    _logSummary('dashboard', summary);

    return summary;
  }

  @override
  Future<RouteDaySummary> getRouteByDate(DateTime date) async {
    final path = config.routeByDatePath(date);
    final json = await apiClient.getJson(config.apiUri(path));
    _logApiPayload('routeByDate:$path', json);

    final summary = RouteDaySummary.fromJson(json);
    _logSummary('routeByDate:$path', summary);

    return summary;
  }

  void _logApiPayload(String source, Map<String, dynamic> payload) {
    developer.log(
      jsonEncode(payload),
      name: 'InspectorRepository.$source.apiPayload',
    );
  }

  void _logSummary(String source, RouteDaySummary summary) {
    developer.log(
      'date=${summary.date.toIso8601String()} hasRoute=${summary.hasRoute} '
      'totalPoints=${summary.totalPoints} completedPoints=${summary.completedPoints} '
      'nextInspectionId=${summary.nextInspection?.id ?? 'none'}',
      name: 'InspectorRepository.$source.summary',
    );
  }
}
