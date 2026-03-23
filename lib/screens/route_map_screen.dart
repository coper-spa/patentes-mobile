import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer;

import '../models/inspection_point.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/route_map_provider.dart';
import '../ui/map/route_map_view.dart';
import '../ui/widgets/bottom_action_sheet.dart';
import '../ui/widgets/route_card.dart';
import 'calendar_screen.dart';
import '../widgets/app_hamburger_drawer.dart';
import '../widgets/error_state.dart';
import '../widgets/loading_state.dart';
import 'inspection_log_screen.dart';

class RouteMapScreen extends ConsumerStatefulWidget {
  const RouteMapScreen({
    super.key,
    required this.day,
    this.showWelcomeBanner = false,
  });

  final DateTime? day;
  final bool showWelcomeBanner;

  @override
  ConsumerState<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends ConsumerState<RouteMapScreen> {
  static const _fallbackCenter = LatLng(-33.4513, -70.6653);

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _mapController = MapController();
  final _sheetController = DraggableScrollableController();

  String? _selectedPointId;

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  void _expandSheetFromSummaryTap() {
    if (!_sheetController.isAttached) {
      return;
    }

    final size = _sheetController.size;
    if (size < 0.30) {
      _sheetController.animateTo(
        0.30,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    if (size < 0.70) {
      _sheetController.animateTo(
        0.74,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _openGoogleMaps(InspectionPoint point) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${point.latitude},${point.longitude}',
    );

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir Google Maps.')),
      );
    }
  }

  Future<void> _openPointSheet(InspectionPoint point) async {
    setState(() => _selectedPointId = point.id);
    _mapController.move(LatLng(point.latitude, point.longitude), 16);
    HapticFeedback.selectionClick();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return BottomActionSheet(
          point: point,
          onGoogleMaps: () async => _openGoogleMaps(point),
          onWaze: () async {
            await ref
                .read(externalNavigationServiceProvider)
                .openWaze(point.latitude, point.longitude);
          },
          onRegister: () {
            Navigator.of(context).pop();
            Navigator.of(this.context).push(
              MaterialPageRoute<void>(
                builder: (_) => InspectionLogScreen(inspection: point),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final targetDay = DateUtils.dateOnly(widget.day ?? DateTime.now());
    final routeState = ref.watch(routeMapProvider(targetDay));
    final authState = ref.watch(authProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppHamburgerDrawer(current: AppSection.route),
      body: routeState.when(
        data: (route) {
          final georeferencedPoints = route.points
              .where(
                (point) =>
                    point.latitude >= -90 &&
                    point.latitude <= 90 &&
                    point.longitude >= -180 &&
                    point.longitude <= 180 &&
                    !(point.latitude == 0 && point.longitude == 0),
              )
              .toList(growable: false);

          developer.log(
            'routePoints=${route.points.length} georeferencedPoints=${georeferencedPoints.length}',
            name: 'RouteMapScreen.points',
          );

          final hasRouteData = route.hasRoute && route.points.isNotEmpty;
          final hasMapPoints = georeferencedPoints.isNotEmpty;
          final initialCenter = hasMapPoints
              ? LatLng(
                  georeferencedPoints.first.latitude,
                  georeferencedPoints.first.longitude,
                )
              : _fallbackCenter;

            final rawDateLabel =
              DateFormat("EEEE d 'de' MMMM", 'es').format(targetDay);
            final dateLabel = _capitalizeWords(rawDateLabel);

          return Stack(
            children: <Widget>[
              Positioned.fill(
                child: RouteMapView(
                  points: georeferencedPoints,
                  initialCenter: initialCenter,
                  selectedPointId: _selectedPointId,
                  mapController: _mapController,
                  onPointTap: _openPointSheet,
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                top: MediaQuery.paddingOf(context).top + 10,
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Material(
                          color: scheme.surface,
                          elevation: 2,
                          borderRadius: BorderRadius.circular(14),
                          child: IconButton(
                            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                            icon: const Icon(Icons.menu_rounded),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Card(
                            margin: EdgeInsets.zero,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                HapticFeedback.selectionClick();
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const CalendarScreen(),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: <Widget>[
                                    Icon(Icons.route, color: scheme.primary, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        dateLabel,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    Icon(
                                      Icons.calendar_month_rounded,
                                      size: 18,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (widget.showWelcomeBanner) ...<Widget>[
                      const SizedBox(height: 10),
                      Card(
                        color: scheme.primaryContainer,
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: <Widget>[
                              Icon(Icons.waving_hand_rounded, color: scheme.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Bienvenido, ${authState.profile?.fullName ?? 'Inspector'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: scheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              DraggableScrollableSheet(
                controller: _sheetController,
                initialChildSize: 0.30,
                minChildSize: 0.18,
                maxChildSize: 0.74,
                snap: true,
                snapSizes: const <double>[0.18, 0.30, 0.74],
                builder: (context, scrollController) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxHeight < 180;

                      return Container(
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 18,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: <Widget>[
                            const SizedBox(height: 10),
                            Container(
                              width: 44,
                              height: 4,
                              decoration: BoxDecoration(
                                color: scheme.outlineVariant,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Card(
                                color: scheme.primaryContainer,
                                margin: EdgeInsets.zero,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: _expandSheetFromSummaryTap,
                                  child: Padding(
                                    padding: EdgeInsets.all(isCompact ? 10 : 14),
                                    child: Row(
                                      children: <Widget>[
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundColor: scheme.primary,
                                          foregroundColor: scheme.onPrimary,
                                          child: const Icon(Icons.map, size: 16),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Ruta del dia: ${route.completedPoints}/${route.totalPoints} completadas',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: scheme.onPrimaryContainer,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.unfold_more_rounded,
                                          size: 18,
                                          color: scheme.onPrimaryContainer,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (isCompact)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                                child: Text(
                                  'Desliza hacia arriba o toca "Ruta del dia" para abrir el listado',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              )
                            else ...<Widget>[
                              const SizedBox(height: 10),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  children: <Widget>[
                                    Text(
                                      'Direcciones asignadas',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${route.points.length}',
                                      style: TextStyle(
                                        color: scheme.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Expanded(
                                child: !hasRouteData
                                    ? ListView(
                                        controller: scrollController,
                                        padding: const EdgeInsets.fromLTRB(
                                            16, 4, 16, 24),
                                        children: <Widget>[
                                          Card(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(16),
                                              child: Column(
                                                children: <Widget>[
                                                  Icon(
                                                    Icons.event_busy_outlined,
                                                    size: 34,
                                                    color:
                                                        scheme.onSurfaceVariant,
                                                  ),
                                                  const SizedBox(height: 10),
                                                  const Text(
                                                    'Sin inspecciones hoy',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Tu mapa y menu siguen disponibles aunque no existan asignaciones para hoy.',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color: scheme
                                                          .onSurfaceVariant,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : ListView.builder(
                                        controller: scrollController,
                                        padding: const EdgeInsets.fromLTRB(
                                            16, 4, 16, 24),
                                        itemCount: route.points.length,
                                        itemBuilder: (context, index) {
                                          final point = route.points[index];
                                          return RouteCard(
                                            point: point,
                                            isSelected:
                                                _selectedPointId == point.id,
                                            onTap: () => _openPointSheet(point),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              if (!hasMapPoints)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.sizeOf(context).height * 0.34,
                  child: IgnorePointer(
                    child: Card(
                      color: scheme.surface.withValues(alpha: 0.95),
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              Icons.location_off_outlined,
                              color: scheme.onSurfaceVariant,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                hasRouteData
                                    ? 'Hay inspecciones asignadas, pero no tienen coordenadas validas.'
                                    : 'Sin puntos para mostrar en el mapa por ahora.',
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const LoadingState(),
        error: (error, stack) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(routeMapProvider(targetDay)),
        ),
      ),
    );
  }

  String _capitalizeWords(String value) {
    final words = value.split(' ');
    return words
        .map((word) =>
            word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}
