import 'package:flutter/material.dart';

import '../models/inspection_point.dart';

class NextInspectionCard extends StatelessWidget {
  const NextInspectionCard({
    super.key,
    required this.nextInspection,
    required this.onOpen,
  });

  final InspectionPoint? nextInspection;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (nextInspection == null) {
      return Card(
        child: ListTile(
          leading: Icon(
            Icons.event_available_outlined,
            color: colorScheme.onSurfaceVariant,
          ),
          title: const Text('Proxima inspeccion'),
          subtitle: const Text('Sin proxima inspeccion programada'),
        ),
      );
    }

    final inspection = nextInspection!;

    return GestureDetector(
      onTap: onOpen,
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ListTile(
              contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              leading: CircleAvatar(
                backgroundColor: colorScheme.secondaryContainer,
                foregroundColor: colorScheme.onSecondaryContainer,
                child: const Icon(Icons.next_plan_outlined),
              ),
              title: const Text(
                'Proxima inspeccion',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    inspection.businessName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    inspection.address,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    inspection.inspectionType,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
