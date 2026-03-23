import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/route_day_summary.dart';

class DashboardSummaryCard extends StatelessWidget {
  const DashboardSummaryCard({super.key, required this.summary});

  final RouteDaySummary summary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateLabel = DateFormat('EEEE d MMM, yyyy', 'es').format(summary.date);
    final progress = summary.totalPoints > 0
        ? summary.completedPoints / summary.totalPoints
        : 0.0;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            leading: CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              child: const Icon(Icons.route_rounded),
            ),
            title: const Text(
              'Proxima ruta',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(dateLabel),
            trailing: Chip(
              label: Text(summary.hasRoute ? 'Asignada' : 'Sin ruta'),
              backgroundColor:
                  summary.hasRoute ? colorScheme.secondaryContainer : colorScheme.errorContainer,
              labelStyle: TextStyle(
                color: summary.hasRoute ? colorScheme.onSecondaryContainer : colorScheme.onErrorContainer,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: <Widget>[
                _StatItem(value: '${summary.totalPoints}', label: 'Total', color: colorScheme.primary),
                const SizedBox(width: 20),
                _StatItem(
                  value: '${summary.completedPoints}',
                  label: 'Completadas',
                  color: colorScheme.secondary,
                ),
                const SizedBox(width: 20),
                _StatItem(
                  value: '${summary.totalPoints - summary.completedPoints}',
                  label: 'Pendientes',
                  color: colorScheme.tertiary,
                ),
              ],
            ),
          ),
          if (summary.totalPoints > 0) ...<Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                borderRadius: BorderRadius.circular(8),
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
