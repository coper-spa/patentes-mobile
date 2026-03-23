import 'package:flutter/material.dart';

import '../../models/inspection_point.dart';

class RouteCard extends StatelessWidget {
  const RouteCard({
    super.key,
    required this.point,
    required this.onTap,
    this.isSelected = false,
  });

  final InspectionPoint point;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = point.status.toLowerCase();

    Color chipColor = const Color(0xFFE6F4EA);
    Color chipTextColor = const Color(0xFF1E8E3E);

    if (status.contains('proceso')) {
      chipColor = const Color(0xFFFFF4E5);
      chipTextColor = const Color(0xFFB06A00);
    } else if (status.contains('rechaz')) {
      chipColor = const Color(0xFFFDECEA);
      chipTextColor = const Color(0xFFB3261E);
    } else if (status.contains('pend')) {
      chipColor = const Color(0xFFE8F1FB);
      chipTextColor = scheme.primary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isSelected ? scheme.primaryContainer : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(
                radius: 14,
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                child: Text(
                  '${point.sequence}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      point.businessName.trim().isEmpty ? '-' : point.businessName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      point.address.trim().isEmpty ? '-' : point.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                    ),
                    if (point.visitReasonLabel.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        point.visitReasonLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      point.inspectionType.trim().isEmpty ? '-' : point.inspectionType,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: chipColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        point.status,
                        style: TextStyle(
                          color: chipTextColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
