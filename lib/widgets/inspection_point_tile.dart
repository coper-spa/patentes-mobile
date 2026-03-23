import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/inspection_point.dart';

class InspectionPointTile extends StatelessWidget {
  const InspectionPointTile({
    super.key,
    required this.point,
    required this.onTap,
    required this.onWaze,
  });

  final InspectionPoint point;
  final VoidCallback onTap;
  final VoidCallback onWaze;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCompleted = _isCompleted(point.status);
    final statusColor = isCompleted ? colorScheme.secondary : colorScheme.primary;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: statusColor.withValues(alpha: 0.15),
            foregroundColor: statusColor,
            child: isCompleted
                ? const Icon(Icons.check_rounded, size: 16)
                : Text(
                    '${point.sequence}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
          title: Text(
            point.businessName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Text(
            point.address,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton.filledTonal(
            onPressed: () {
              HapticFeedback.lightImpact();
              onWaze();
            },
            icon: const Icon(Icons.navigation_rounded, size: 18),
            tooltip: 'Navegar',
          ),
        ),
      ),
    );
  }

  static bool _isCompleted(String status) {
    final lower = status.toLowerCase();
    return lower == 'completed' ||
        lower == 'visited' ||
        lower == 'done' ||
        lower.contains('complet');
  }
}
