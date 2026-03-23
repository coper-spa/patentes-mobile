import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/route_day_summary.dart';
import 'app_providers.dart';

final dashboardProvider = FutureProvider<RouteDaySummary>((ref) async {
  final repository = ref.watch(inspectorRepositoryProvider);
  return repository.getDashboardSummary();
});
