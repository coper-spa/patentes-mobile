import 'inspection_point.dart';

class RouteDaySummary {
  const RouteDaySummary({
    required this.date,
    required this.hasRoute,
    required this.totalPoints,
    required this.completedPoints,
    required this.nextInspection,
    required this.points,
  });

  final DateTime date;
  final bool hasRoute;
  final int totalPoints;
  final int completedPoints;
  final InspectionPoint? nextInspection;
  final List<InspectionPoint> points;

  factory RouteDaySummary.fromJson(Map<String, dynamic> json) {
    final assignments = _extractAssignments(json);
    if (assignments != null) {
      return _fromVisitAssignments(assignments, json);
    }

    final points = (json['points'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(InspectionPoint.fromJson)
        .toList();

    InspectionPoint? next;
    if (json['next_inspection'] is Map<String, dynamic>) {
      next = InspectionPoint.fromJson(
        json['next_inspection'] as Map<String, dynamic>,
      );
    }

    return RouteDaySummary(
      date: DateTime.parse(
        (json['date'] ?? DateTime.now().toIso8601String()) as String,
      ),
      hasRoute: (json['has_route'] as bool?) ?? points.isNotEmpty,
      totalPoints: _toInt(json['total_points']) ?? points.length,
      completedPoints: _toInt(json['completed_points']) ?? 0,
      nextInspection: next,
      points: points,
    );
  }

  static RouteDaySummary _fromVisitAssignments(
    List<Map<String, dynamic>> assignments,
    Map<String, dynamic> source,
  ) {

    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);

    final assignmentDates = assignments
        .map(
          (assignment) =>
              _parseDate(assignment['assigned_for_date'] ?? assignment['date']),
        )
        .whereType<DateTime>()
        .toList()
      ..sort();

    final nextDate = assignmentDates.firstWhere(
      (date) => !date.isBefore(startOfToday),
      orElse: () =>
          assignmentDates.isNotEmpty ? assignmentDates.first : startOfToday,
    );

    final points = assignments
        .where((assignment) {
          final assignedDate =
              _parseDate(assignment['assigned_for_date'] ?? assignment['date']);

          if (assignedDate == null) {
            return true;
          }

          return _isSameDate(assignedDate, nextDate);
        })
        .map(InspectionPoint.fromJson)
        .toList()
      ..sort((a, b) => a.sequence.compareTo(b.sequence));

    final completedPoints = assignments.where((assignment) {
      final assignedDate =
          _parseDate(assignment['assigned_for_date'] ?? assignment['date']);
      if (assignedDate == null || !_isSameDate(assignedDate, nextDate)) {
        if (assignedDate != null) {
          return false;
        }
      }

      final status =
          (assignment['assignment_status'] ?? '').toString().toLowerCase();
      final visitedAt = assignment['visited_at'] ?? assignment['managed_at'];

      return visitedAt != null ||
          status == 'completed' ||
          status == 'visited' ||
          status == 'done' ||
          status.contains('complet');
    }).length;

    final nextInspection = points.cast<InspectionPoint?>().firstWhere(
      (point) {
        final status = point?.status.toLowerCase() ?? '';
        return status != 'completed' && status != 'visited' && status != 'done';
      },
      orElse: () => points.isNotEmpty ? points.first : null,
    );

    return RouteDaySummary(
      date: _parseDate(source['date']) ?? nextDate,
      hasRoute: points.isNotEmpty,
      totalPoints: points.length,
      completedPoints: completedPoints,
      nextInspection: nextInspection,
      points: points,
    );
  }

  static List<Map<String, dynamic>>? _extractAssignments(
    Map<String, dynamic> json,
  ) {
    final data = json['data'];
    if (data is List<dynamic>) {
      return data.whereType<Map<String, dynamic>>().toList(growable: false);
    }

    if (data is Map<String, dynamic>) {
      final nestedData = data['data'];
      if (nestedData is List<dynamic>) {
        return nestedData
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
      }

      final items = data['items'];
      if (items is List<dynamic>) {
        return items
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
      }

      final rows = data['rows'];
      if (rows is List<dynamic>) {
        return rows.whereType<Map<String, dynamic>>().toList(growable: false);
      }
    }

    final items = json['items'];
    if (items is List<dynamic>) {
      return items.whereType<Map<String, dynamic>>().toList(growable: false);
    }

    final rows = json['rows'];
    if (rows is List<dynamic>) {
      return rows.whereType<Map<String, dynamic>>().toList(growable: false);
    }

    final results = json['results'];
    if (results is List<dynamic>) {
      return results
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
    }

    if (json['id'] != null) {
      return <Map<String, dynamic>>[json];
    }

    return null;
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) {
      return null;
    }

    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) {
      return null;
    }

    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  static bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static int? _toInt(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }
}
