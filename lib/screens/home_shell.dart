import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import 'route_map_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  String? _selectedGroupId;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final groupState = ref.watch(inspectorGroupSessionProvider);

    if (groupState.isInspector && !groupState.initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (groupState.hasConfigurationError) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.warning_amber_rounded, size: 52),
                  const SizedBox(height: 12),
                  const Text(
                    'Configuracion de inspector incompleta',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    groupState.errorMessage ??
                        'No hay grupos inspectores disponibles para tu usuario.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () async {
                      await ref.read(authProvider.notifier).logout();
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Cerrar sesion'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (groupState.requiresSelection) {
      _selectedGroupId ??= groupState.availableGroups.first.id;
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const Text(
                          'Selecciona tu grupo inspector activo',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Debes elegir un grupo para continuar con tus asignaciones y gestiones.',
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedGroupId,
                          items: groupState.availableGroups
                              .map(
                                (group) => DropdownMenuItem<String>(
                                  value: group.id,
                                  child: Text(group.name),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            setState(() {
                              _selectedGroupId = value;
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Grupo inspector activo',
                            prefixIcon: Icon(Icons.groups_2_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: (_selectedGroupId == null ||
                                  _selectedGroupId!.trim().isEmpty)
                              ? null
                              : () async {
                                  await ref
                                      .read(
                                        inspectorGroupSessionProvider.notifier,
                                      )
                                      .setActiveGroupId(_selectedGroupId!);
                                },
                          child: const Text('Continuar'),
                        ),
                        if (authState.profile?.email != null) ...<Widget>[
                          const SizedBox(height: 8),
                          Text(
                            authState.profile!.email,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return const RouteMapScreen(day: null, showWelcomeBanner: true);
  }
}
