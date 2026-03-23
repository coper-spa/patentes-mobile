import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/route_day_summary.dart';
import 'app_providers.dart';

final routeMapProvider = FutureProvider.family<RouteDaySummary, DateTime>((
  ref,
  day,
) async {
  final repository = ref.watch(inspectorRepositoryProvider);
  return repository.getRouteByDate(day);
});
