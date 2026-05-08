import 'package:flutter/material.dart';

import '../../models/inspection_point.dart';
import 'app_button.dart';
import 'app_card.dart';

class BottomActionSheet extends StatelessWidget {
  const BottomActionSheet({
    super.key,
    required this.point,
    required this.onGoogleMaps,
    required this.onWaze,
    required this.onRegister,
  });

  final InspectionPoint point;
  final VoidCallback onGoogleMaps;
  final VoidCallback onWaze;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final notes = point.visitHistory.isNotEmpty &&
            point.visitHistory.last.comment.trim().isNotEmpty
        ? point.visitHistory.last.comment.trim()
        : 'Sin notas registradas.';

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              point.businessName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              point.address,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: <Widget>[
                  _MetaRow(
                    icon: Icons.assignment_outlined,
                    label: 'Tipo de gestion',
                    value: point.inspectionType,
                  ),
                  const SizedBox(height: 10),
                  _MetaRow(
                    icon: Icons.badge_outlined,
                    label: 'Rut contribuyente',
                    value: point.contribuyenteRut.trim().isEmpty
                        ? 'Sin rut registrado'
                        : point.contribuyenteRut,
                  ),
                  if (point.patentRol.trim().isNotEmpty) ...<Widget>[
                    const SizedBox(height: 10),
                    _MetaRow(
                      icon: Icons.business_center_outlined,
                      label: 'Rol patente',
                      value: point.patentRol,
                    ),
                  ],
                  const SizedBox(height: 10),
                  _MetaRow(
                    icon: Icons.info_outline_rounded,
                    label: 'Estado',
                    value: point.status,
                  ),
                  const SizedBox(height: 10),
                  _MetaRow(
                    icon: Icons.sticky_note_2_outlined,
                    label: 'Notas',
                    value: notes,
                    multiline: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            AppButton(
              label: 'Ir con Google Maps',
              icon: Icons.map_outlined,
              onPressed: onGoogleMaps,
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'Ir con Waze',
              icon: Icons.navigation_rounded,
              type: AppButtonType.secondary,
              onPressed: onWaze,
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'Registrar gestion',
              icon: Icons.edit_note_rounded,
              type: AppButtonType.secondary,
              onPressed: onRegister,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
    this.multiline = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment:
          multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: <Widget>[
        Icon(icon, size: 18, color: scheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
