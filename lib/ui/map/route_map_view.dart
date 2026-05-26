import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../../models/inspection_point.dart';

class RouteMapView extends StatelessWidget {
  const RouteMapView({
    super.key,
    required this.points,
    required this.initialCenter,
    required this.mapController,
    required this.onPointTap,
    this.selectedPointId,
  });

  final List<InspectionPoint> points;
  final LatLng initialCenter;
  final MapController mapController;
  final ValueChanged<InspectionPoint> onPointTap;
  final String? selectedPointId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final markerPositions = _buildMarkerPositions(points);

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 15,
      ),
      children: <Widget>[
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
          retinaMode: RetinaMode.isHighDensity(context),
          subdomains: const <String>['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.example.inspectores_municipales_app',
        ),
        if (points.isNotEmpty)
          PolylineLayer(
            polylines: <Polyline>[
              Polyline(
                points: points
                    .map((p) => LatLng(p.latitude, p.longitude))
                    .toList(growable: false),
                strokeWidth: 4,
                color: scheme.secondary.withValues(alpha: 0.8),
              ),
            ],
          ),
        if (points.isNotEmpty)
          MarkerLayer(
            markers: markerPositions
                .map(
                  (entry) => Marker(
                    point: entry.displayPoint,
                    width: 40,
                    height: 48,
                    child: GestureDetector(
                      onTap: () => onPointTap(entry.point),
                      child: _MapPin(
                        label: '${entry.point.sequence}',
                        isCompleted: _isCompleted(entry.point.status),
                        isSelected: selectedPointId == entry.point.id,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
      ],
    );
  }

  static bool _isCompleted(String status) {
    final lower = status.toLowerCase();
    return lower == 'completed' ||
        lower == 'visited' ||
        lower == 'done' ||
        lower == 'visitada' ||
        lower == 'pagada' ||
        lower == 'multada' ||
        lower.contains('complet') ||
        lower.contains('visitad');
  }

  static List<_MarkerPosition> _buildMarkerPositions(
    List<InspectionPoint> points,
  ) {
    if (points.length < 2) {
      return points
          .map(
            (point) => _MarkerPosition(
              point: point,
              displayPoint: LatLng(point.latitude, point.longitude),
            ),
          )
          .toList(growable: false);
    }

    final grouped = <String, List<InspectionPoint>>{};
    for (final point in points) {
      final key = _gridKey(point.latitude, point.longitude);
      grouped.putIfAbsent(key, () => <InspectionPoint>[]).add(point);
    }

    final result = <_MarkerPosition>[];
    for (final group in grouped.values) {
      if (group.length == 1) {
        final point = group.first;
        result.add(
          _MarkerPosition(
            point: point,
            displayPoint: LatLng(point.latitude, point.longitude),
          ),
        );
        continue;
      }

      final orderedGroup = [...group]
        ..sort((a, b) => a.sequence.compareTo(b.sequence));
      final anchor = orderedGroup.first;
      for (var i = 0; i < orderedGroup.length; i++) {
        final ringIndex = i ~/ 8;
        final ringRadiusMeters = _spreadRadiusMeters(orderedGroup.length) +
            (ringIndex * _ringGapMeters);
        final angleInRing = i % 8;
        final shifted = _offsetLatLng(
          latitude: anchor.latitude,
          longitude: anchor.longitude,
          distanceMeters: ringRadiusMeters,
          angleRadians: (2 * math.pi * angleInRing) / 8,
        );
        result.add(
          _MarkerPosition(point: orderedGroup[i], displayPoint: shifted),
        );
      }
    }

    return result;
  }

  static String _gridKey(double lat, double lng) {
    const precision = 4;
    return '${lat.toStringAsFixed(precision)}_${lng.toStringAsFixed(precision)}';
  }

  static double _spreadRadiusMeters(int count) {
    if (count <= 3) return 70;
    if (count <= 6) return 95;
    if (count <= 10) return 115;
    return 140;
  }

  static const double _ringGapMeters = 35;

  static LatLng _offsetLatLng({
    required double latitude,
    required double longitude,
    required double distanceMeters,
    required double angleRadians,
  }) {
    const metersPerDegreeLat = 111320.0;
    final latDelta =
        (distanceMeters * math.cos(angleRadians)) / metersPerDegreeLat;
    final cosLat = math.cos(latitude * math.pi / 180).abs().clamp(0.0001, 1.0);
    final lngDelta = (distanceMeters * math.sin(angleRadians)) /
        (metersPerDegreeLat * cosLat);
    return LatLng(latitude + latDelta, longitude + lngDelta);
  }
}

class _MarkerPosition {
  const _MarkerPosition({required this.point, required this.displayPoint});

  final InspectionPoint point;
  final LatLng displayPoint;
}

class _MapPin extends StatelessWidget {
  const _MapPin({
    required this.label,
    required this.isSelected,
    required this.isCompleted,
  });

  final String label;
  final bool isSelected;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final baseColor = isCompleted ? Colors.green.shade600 : scheme.primary;
    final selectedColor =
        isCompleted ? Colors.green.shade800 : scheme.secondary;
    final pinColor = isSelected ? selectedColor : baseColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isSelected ? 32 : 28,
          height: isSelected ? 32 : 28,
          decoration: BoxDecoration(
            color: pinColor,
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ),
        CustomPaint(
          size: const Size(10, 8),
          painter: _TrianglePainter(pinColor),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  _TrianglePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
