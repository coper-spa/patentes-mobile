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
            markers: points
                .map(
                  (point) => Marker(
                    point: LatLng(point.latitude, point.longitude),
                    width: 40,
                    height: 48,
                    child: GestureDetector(
                      onTap: () => onPointTap(point),
                      child: _MapPin(
                        label: '${point.sequence}',
                        isCompleted: _isCompleted(point.status),
                        isSelected: selectedPointId == point.id,
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
    final selectedColor = isCompleted ? Colors.green.shade800 : scheme.secondary;
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
