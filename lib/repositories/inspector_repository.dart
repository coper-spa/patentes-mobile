import '../models/route_day_summary.dart';

abstract class InspectorRepository {
  Future<RouteDaySummary> getDashboardSummary();
  Future<RouteDaySummary> getRouteByDate(DateTime date);
}
