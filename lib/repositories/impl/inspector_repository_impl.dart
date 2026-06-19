import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../models/route_day_summary.dart';
import '../inspector_repository.dart';

class InspectorRepositoryImpl implements InspectorRepository {
  InspectorRepositoryImpl({required this.config, required this.apiClient});

  final AppConfig config;
  final ApiClient apiClient;

  @override
  Future<RouteDaySummary> getDashboardSummary({
    String? visitStateId,
    String? visitResultCode,
    DateTime? weekStartDate,
  }) async {
    final endpointUri = config.apiUri(config.dashboardEndpoint);
    final uri = _withVisitAssignmentFilters(
      endpointUri,
      visitStateId: visitStateId,
      visitResultCode: visitResultCode,
      weekStartDate: weekStartDate,
    );

    final json = await apiClient.getJson(uri);
    return RouteDaySummary.fromJson(json);
  }

  @override
  Future<RouteDaySummary> getRouteByDate(
    DateTime date, {
    String? visitStateId,
    String? visitResultCode,
    DateTime? weekStartDate,
  }) async {
    final path = config.routeByDatePath(date);
    final endpointUri = config.apiUri(path);
    final uri = _withVisitAssignmentFilters(
      endpointUri,
      visitStateId: visitStateId,
      visitResultCode: visitResultCode,
      weekStartDate: weekStartDate ?? _startOfWeekMonday(date),
    );

    final json = await apiClient.getJson(uri);
    return RouteDaySummary.fromJson(json);
  }

  Uri _withVisitAssignmentFilters(
    Uri uri, {
    String? visitStateId,
    String? visitResultCode,
    DateTime? weekStartDate,
  }) {
    final query = Map<String, String>.from(uri.queryParameters);

    if (visitStateId != null && visitStateId.trim().isNotEmpty) {
      query['visit_state_id'] = visitStateId.trim();
    }

    if (visitResultCode != null && visitResultCode.trim().isNotEmpty) {
      query['visit_result_code'] = visitResultCode.trim();
    }

    if (weekStartDate != null) {
      query['week_start_date'] = _formatDate(weekStartDate);
    }

    return uri.replace(queryParameters: query);
  }

  DateTime _startOfWeekMonday(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final shift = normalized.weekday - DateTime.monday;
    return normalized.subtract(Duration(days: shift));
  }

  String _formatDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
