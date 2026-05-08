import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

import '../core/utils/date_time_formatter.dart';
import '../providers/app_providers.dart';
import '../providers/inspection_detail_provider.dart';
import '../widgets/error_state.dart';
import '../widgets/loading_state.dart';
import 'inspection_log_screen.dart';

class InspectionDetailScreen extends ConsumerWidget {
  const InspectionDetailScreen({super.key, required this.inspectionId});

  final String inspectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(inspectionDetailProvider(inspectionId));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de inspeccion')),
      body: detailState.when(
        data: (inspection) {
          debugPrint(
            '[InspectionDetailScreen] === INSPECTION DETAIL DATA ===\n'
            'ID: ${inspection.id}\n'
            'Business: ${inspection.businessName}\n'
            'Address: ${inspection.address}\n'
            'Type: ${inspection.inspectionType}\n'
            'Reason: ${inspection.visitReasonLabel}\n'
            'Status: ${inspection.status}\n'
            'Sequence: ${inspection.sequence}\n'
            'Contribuyente ID: ${inspection.contribuyenteId}\n'
            'Patent ID: ${inspection.patentId}\n'
            'Patent Arrear ID: ${inspection.patentArrearId}\n'
            'Visitable Type: ${inspection.visitableType}\n'
            'Visitable ID: ${inspection.visitableId}\n'
            'Coordinates: (${inspection.latitude}, ${inspection.longitude})\n'
            'Visit History Count: ${inspection.visitHistory.length}\n'
            'Visit History:\n${inspection.visitHistory.asMap().entries.map((e) => '  [${e.key}] ${e.value.visitedAt} - ${e.value.managementType} - ${e.value.status} - ${e.value.comment}').join('\n')}\n'
            '================================',
          );

          final locationLogsState = ref.watch(
            locationManagementLogsProvider(
              (
                contribuyenteId: inspection.contribuyenteId,
                patentId:
                    inspection.patentId.trim().isEmpty ? null : inspection.patentId,
              ),
            ),
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: <Widget>[
              Card(
                color: colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          CircleAvatar(
                            backgroundColor: colorScheme.surface,
                            foregroundColor: colorScheme.primary,
                            child: const Icon(Icons.storefront_outlined, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              inspection.inspectionType,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colorScheme.onPrimaryContainer,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        inspection.businessName,
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        label: inspection.address,
                        textColor: colorScheme.onPrimaryContainer,
                        iconColor: colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(height: 12),
                      _StatusChip(status: inspection.status),
                      if (inspection.visitStateName.trim().isNotEmpty ||
                          inspection.visitResultCode.trim().isNotEmpty) ...<Widget>[
                        const SizedBox(height: 8),
                        _InfoRow(
                          icon: Icons.flag_circle_outlined,
                          label: inspection.visitStateName.trim().isNotEmpty
                              ? inspection.visitStateName
                              : inspection.visitResultCode,
                          textColor: colorScheme.onPrimaryContainer,
                          iconColor: colorScheme.onPrimaryContainer,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Icon(
                    Icons.history_toggle_off_rounded,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Gestiones ultimos 6 meses',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              locationLogsState.when(
                data: (logs) {
                  if (inspection.contribuyenteId.trim().isEmpty) {
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          Icons.info_outline_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        title: const Text('Gestiones previas'),
                        subtitle: Text(
                          'No hay contribuyente asociado para consultar historial. '
                          'visitableType=${inspection.visitableType} visitableId=${inspection.visitableId}',
                        ),
                      ),
                    );
                  }

                  if (logs.isEmpty) {
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          Icons.info_outline_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        title: const Text('Gestiones previas'),
                        subtitle: const Text(
                          'No hay gestiones registradas en este periodo.',
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: logs.map((log) {
                      final normalizedObservation =
                        log.observation.trim().toLowerCase();
                      final normalizedTypeName =
                        log.managementTypeName.trim().toLowerCase();
                      final normalizedTypeCode =
                        log.managementTypeCode.trim().toLowerCase();
                      final shouldShowObservation =
                        normalizedObservation.isNotEmpty &&
                        normalizedObservation != normalizedTypeName &&
                        normalizedObservation != normalizedTypeCode;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.secondaryContainer,
                            foregroundColor: colorScheme.onSecondaryContainer,
                            child: const Icon(
                              Icons.fact_check_outlined,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            log.managementTypeName.trim().isEmpty
                                ? 'Gestion'
                                : log.managementTypeName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const SizedBox(height: 2),
                              Text(
                                DateTimeFormatter.formatDateTime(log.managedAt),
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                              if (shouldShowObservation) ...<Widget>[
                                const SizedBox(height: 4),
                                Text(
                                  log.observation,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: <Widget>[
                                  _StatusChip(
                                    status: log.managementStatus,
                                    small: true,
                                  ),
                                  if (log.hasEvidence)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.teal.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Con evidencia',
                                        style: TextStyle(
                                          color: Colors.teal.shade700,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(growable: false),
                  );
                },
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: LinearProgressIndicator(),
                  ),
                ),
                error: (error, stack) => Card(
                  child: ListTile(
                    leading: Icon(Icons.error_outline, color: colorScheme.error),
                    title: const Text('Gestiones previas'),
                    subtitle: Text(
                      'No se pudo cargar el historial: $error',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await ref
                            .read(externalNavigationServiceProvider)
                            .openWaze(inspection.latitude, inspection.longitude);
                      },
                      icon: const Icon(Icons.navigation_rounded, size: 18),
                      label: const Text('Navegar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                InspectionLogScreen(inspection: inspection),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_note_rounded, size: 18),
                      label: const Text('Gestionar'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Icon(
                    Icons.history_rounded,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Historial de visitas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (inspection.visitHistory.isEmpty)
                Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.info_outline_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    title: const Text('Historial'),
                    subtitle: const Text('Sin visitas previas'),
                  ),
                )
              else
                ...inspection.visitHistory.asMap().entries.map(
                  (entry) {
                    final visit = entry.value;
                    final isLast = entry.key == inspection.visitHistory.length - 1;
                    return TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: Duration(
                        milliseconds: math.min(240 + (entry.key * 70), 880),
                      ),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset((1 - value) * 20, 0),
                            child: child,
                          ),
                        );
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Column(
                            children: <Widget>[
                              Container(
                                width: 11,
                                height: 11,
                                decoration: BoxDecoration(
                                  color: colorScheme.secondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              if (!isLast)
                                Container(
                                  width: 2,
                                  height: 86,
                                  color: colorScheme.secondary
                                      .withValues(alpha: 0.35),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: Text(
                                            visit.managementType,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        _StatusChip(status: visit.status, small: true),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      DateTimeFormatter.formatDateTime(
                                          visit.visitedAt),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    if (visit.comment.isNotEmpty) ...<Widget>[
                                      const SizedBox(height: 8),
                                      Text(
                                        visit.comment,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          );
        },
        loading: () => const LoadingState(),
        error: (error, stack) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(inspectionDetailProvider(inspectionId)),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    this.textColor,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final Color? textColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(
          icon,
          size: 18,
          color: iconColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: textColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.status,
    this.small = false,
  });

  final String status;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final lower = status.toLowerCase();
    final Color bg;
    final Color fg;

    if (lower.contains('complet') || lower == 'done' || lower == 'visited') {
      bg = Colors.green.shade50;
      fg = Colors.green.shade700;
    } else if (lower.contains('proceso') || lower == 'in_progress') {
      bg = Colors.amber.shade50;
      fg = Colors.amber.shade800;
    } else if (lower.contains('rechaz')) {
      bg = Colors.red.shade50;
      fg = Colors.red.shade700;
    } else {
      bg = Colors.blue.shade50;
      fg = Colors.blue.shade700;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 12,
        vertical: small ? 3 : 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: fg,
          fontSize: small ? 11 : 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
