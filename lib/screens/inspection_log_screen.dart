import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../models/inspection_log_payload.dart';
import '../models/inspection_point.dart';
import '../providers/dashboard_provider.dart';
import '../providers/inspection_detail_provider.dart';
import '../providers/route_map_provider.dart';
import '../ui/widgets/app_button.dart';
import '../ui/widgets/app_card.dart';

class InspectionLogScreen extends ConsumerStatefulWidget {
  const InspectionLogScreen({super.key, required this.inspection});

  final InspectionPoint inspection;

  @override
  ConsumerState<InspectionLogScreen> createState() =>
      _InspectionLogScreenState();
}

class _InspectionLogScreenState extends ConsumerState<InspectionLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _observationController = TextEditingController();
  final _imagePicker = ImagePicker();

  String? _status;
  String? _managementTypeId;
  bool _isPickingEvidence = false;
  final List<XFile> _evidences = <XFile>[];
  ProviderSubscription<InspectionLogState>? _subscription;

  @override
  void initState() {
    super.initState();

    _subscription = ref.listenManual<InspectionLogState>(
      inspectionLogProvider,
      (previous, next) {
        if (next.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                next.feedbackMessage ?? 'Gestion registrada correctamente.',
              ),
              backgroundColor: Colors.green.shade600,
            ),
          );
          ref.invalidate(inspectionDetailProvider(widget.inspection.id));
          ref.invalidate(routeMapProvider);
          ref.invalidate(dashboardProvider);
          Navigator.of(context).pop();
        }

        if (next.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _subscription?.close();
    _observationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_managementTypeId == null || _status == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona tipo de gestion y estado.'),
        ),
      );
      return;
    }

    final hasPatentArrear = widget.inspection.patentArrearId.trim().isNotEmpty;
    final hasVisitable =
        widget.inspection.visitableType.trim().isNotEmpty &&
        widget.inspection.visitableId.trim().isNotEmpty;

    if (!hasPatentArrear && !hasVisitable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se encontraron identificadores para registrar la gestion.',
          ),
        ),
      );
      return;
    }

    final payload = InspectionLogPayload(
      patentArrearId:
          hasPatentArrear ? widget.inspection.patentArrearId : null,
      visitableType: hasVisitable ? widget.inspection.visitableType : null,
      visitableId: hasVisitable ? widget.inspection.visitableId : null,
      arrearVisitAssignmentId: widget.inspection.id,
      arrearManagementTypeId: _managementTypeId!,
      managementStatus: _status!,
      managedAt: DateTime.now(),
      observation: _observationController.text.trim(),
      hasEvidence: _evidences.isNotEmpty,
    );

    await ref.read(inspectionLogProvider.notifier).submit(
      payload,
      evidencePaths: _evidences.map((e) => e.path).toList(growable: false),
    );
  }

  Future<void> _addEvidenceFromCamera() async {
    if (_isPickingEvidence) {
      return;
    }

    setState(() => _isPickingEvidence = true);
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 2048,
      );

      if (!mounted) {
        return;
      }

      if (image != null) {
        setState(() {
          _evidences.add(image);
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir la camara para capturar evidencia.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingEvidence = false);
      }
    }
  }

  Future<void> _addEvidenceFromGallery() async {
    if (_isPickingEvidence) {
      return;
    }

    setState(() => _isPickingEvidence = true);
    try {
      final images = await _imagePicker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 2048,
      );

      if (!mounted) {
        return;
      }

      if (images.isNotEmpty) {
        final existingPaths = _evidences.map((e) => e.path).toSet();
        final newItems = images
            .where((image) => !existingPaths.contains(image.path))
            .toList(growable: false);

        setState(() {
          _evidences.addAll(newItems);
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir la galeria para adjuntar evidencias.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingEvidence = false);
      }
    }
  }

  void _removeEvidenceAt(int index) {
    if (index < 0 || index >= _evidences.length) {
      return;
    }

    setState(() {
      _evidences.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final logState = ref.watch(inspectionLogProvider);
    final managementTypesAsync = ref.watch(managementTypesProvider);
    final statusesAsync = ref.watch(managementStatusesProvider);
    final scheme = Theme.of(context).colorScheme;

    final managementTypeOptions = managementTypesAsync.maybeWhen(
      data: (options) => options,
      orElse: () => const [],
    );

    final statusOptions = statusesAsync.maybeWhen(
      data: (options) => options,
      orElse: () => const [],
    );

    if (_managementTypeId == null && managementTypeOptions.isNotEmpty) {
      _managementTypeId = managementTypeOptions.first.value;
    }

    if (_status == null && statusOptions.isNotEmpty) {
      _status = statusOptions.first.value;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar gestion')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 26),
          children: <Widget>[
            AppCard(
              color: scheme.primaryContainer,
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    child: const Icon(Icons.fact_check_outlined, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Registro rapido de gestion',
                      style: TextStyle(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Tipo de gestion',
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  managementTypesAsync.when(
                    data: (options) {
                      if (options.isEmpty) {
                        return const Text(
                          'No hay tipos de gestion disponibles.',
                        );
                      }

                      return DropdownButtonFormField<String>(
                        initialValue: _managementTypeId,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de gestion',
                          prefixIcon: Icon(Icons.assignment_outlined),
                        ),
                        items: options
                            .map(
                              (option) => DropdownMenuItem<String>(
                                value: option.value,
                                child: Text(option.label),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          setState(() {
                            _managementTypeId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Selecciona un tipo de gestion.';
                          }
                          return null;
                        },
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (error, stack) => Text(
                      'No se pudieron cargar los tipos: $error',
                      style: TextStyle(color: scheme.error),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _observationController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Observacion',
                      hintText: 'Observaciones del inspector',
                      alignLabelWithHint: true,
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 58),
                        child: Icon(Icons.sticky_note_2_outlined),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa una observacion.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: AppButton(
                          label: 'Camara',
                          icon: Icons.camera_alt_rounded,
                          type: AppButtonType.secondary,
                          isLoading: _isPickingEvidence,
                          onPressed: _addEvidenceFromCamera,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppButton(
                          label: 'Galeria',
                          icon: Icons.photo_library_outlined,
                          type: AppButtonType.secondary,
                          isLoading: _isPickingEvidence,
                          onPressed: _addEvidenceFromGallery,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _evidences.isEmpty
                        ? 'Sin evidencias adjuntas'
                        : '${_evidences.length} evidencia(s) seleccionada(s)',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  if (_evidences.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 86,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _evidences.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final evidence = _evidences[index];
                          return Stack(
                            children: <Widget>[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  File(evidence.path),
                                  width: 86,
                                  height: 86,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                right: 4,
                                top: 4,
                                child: InkWell(
                                  onTap: () => _removeEvidenceAt(index),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Estado del punto',
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  statusesAsync.when(
                    data: (options) {
                      if (options.isEmpty) {
                        return const Text('No hay estados disponibles.');
                      }

                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: options.map((option) {
                          final isSelected = _status == option.value;
                          return ChoiceChip(
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() => _status = option.value);
                            },
                            label: Text(option.label),
                          );
                        }).toList(growable: false),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (error, stack) => Text(
                      'No se pudieron cargar los estados: $error',
                      style: TextStyle(color: scheme.error),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Guardar gestion',
              icon: Icons.task_alt_rounded,
              isLoading: logState.isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
