import '../models/route_day_summary.dart';

abstract class InspectorRepository {
  Future<RouteDaySummary> getDashboardSummary({
    String? visitStateId,
    String? visitResultCode,
    DateTime? weekStartDate,
  });
  Future<RouteDaySummary> getRouteByDate(
    DateTime date, {
    String? visitStateId,
    String? visitResultCode,
    DateTime? weekStartDate,
  });
}
