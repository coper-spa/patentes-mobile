import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../providers/calendar_provider.dart';
import '../widgets/app_hamburger_drawer.dart';
import '../widgets/error_state.dart';
import '../widgets/loading_state.dart';
import 'route_map_screen.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calendarProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      drawer: const AppHamburgerDrawer(current: AppSection.calendar),
      appBar: AppBar(
        title: const Text('Calendario'),
        leading: Builder(
          builder: (ctx) {
            return IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            );
          },
        ),
      ),
      body: Column(
        children: <Widget>[
          Card(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TableCalendar<dynamic>(
              locale: 'es',
              startingDayOfWeek: StartingDayOfWeek.monday,
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2100, 12, 31),
              focusedDay: state.focusedDay,
              selectedDayPredicate: (day) =>
                  isSameDay(state.selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                HapticFeedback.selectionClick();
                ref.read(calendarProvider.notifier).loadForDay(selectedDay);
              },
              onPageChanged: (focusedDay) {
                ref.read(calendarProvider.notifier).loadForDay(focusedDay);
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
                selectedDecoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left_rounded,
                  color: colorScheme.primary,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.primary,
                ),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
                weekendStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: state.routeResult.when(
              data: (route) {
                if (!route.hasRoute) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.event_busy_outlined,
                          size: 48,
                          color: colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Sin ruta asignada para este dia',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, (1 - value) * 10),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.route_rounded,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'Ruta asignada',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: colorScheme.onPrimaryContainer,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${route.totalPoints} puntos de inspeccion',
                                      style: TextStyle(
                                        color: colorScheme.onPrimaryContainer,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    RouteMapScreen(day: state.selectedDay),
                              ),
                            );
                          },
                          icon: const Icon(Icons.map_rounded, size: 20),
                          label: const Text('Ver ruta en mapa'),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const LoadingState(),
              error: (error, stack) => ErrorState(
                message: error.toString(),
                onRetry: () => ref
                    .read(calendarProvider.notifier)
                    .loadForDay(state.selectedDay),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
