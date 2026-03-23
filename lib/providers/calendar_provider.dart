import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/route_day_summary.dart';
import 'app_providers.dart';

class CalendarState {
  const CalendarState({
    required this.selectedDay,
    required this.focusedDay,
    required this.routeResult,
  });

  final DateTime selectedDay;
  final DateTime focusedDay;
  final AsyncValue<RouteDaySummary> routeResult;

  CalendarState copyWith({
    DateTime? selectedDay,
    DateTime? focusedDay,
    AsyncValue<RouteDaySummary>? routeResult,
  }) {
    return CalendarState(
      selectedDay: selectedDay ?? this.selectedDay,
      focusedDay: focusedDay ?? this.focusedDay,
      routeResult: routeResult ?? this.routeResult,
    );
  }
}

class CalendarNotifier extends StateNotifier<CalendarState> {
  CalendarNotifier(this.ref)
      : super(
          CalendarState(
            selectedDay: DateUtils.dateOnly(DateTime.now()),
            focusedDay: DateUtils.dateOnly(DateTime.now()),
            routeResult: const AsyncLoading(),
          ),
        ) {
    loadForDay(DateUtils.dateOnly(DateTime.now()));
  }

  final Ref ref;

  Future<void> loadForDay(DateTime day) async {
    final normalizedDay = DateUtils.dateOnly(day);

    state = state.copyWith(
      selectedDay: normalizedDay,
      focusedDay: normalizedDay,
      routeResult: const AsyncLoading(),
    );

    final repository = ref.read(inspectorRepositoryProvider);

    state = await AsyncValue.guard(() async {
      return repository.getRouteByDate(normalizedDay);
    }).then((result) {
      return state.copyWith(routeResult: result);
    });
  }
}

final calendarProvider = StateNotifierProvider<CalendarNotifier, CalendarState>(
  (ref) {
    return CalendarNotifier(ref);
  },
);
