import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../models/inspection_log_payload.dart';
import '../models/lookup_option.dart';
import '../models/location_management_log.dart';
import '../models/inspection_point.dart';
import 'app_providers.dart';

final inspectionDetailProvider = FutureProvider.family<InspectionPoint, String>(
  (ref, inspectionId) async {
    final repository = ref.watch(inspectionLogRepositoryProvider);
    return repository.getInspectionDetail(inspectionId);
  },
);

final managementTypesProvider = FutureProvider<List<LookupOption>>((ref) async {
  final repository = ref.watch(inspectionLogRepositoryProvider);
  return repository.getManagementTypes();
});

final managementStatusesProvider =
    FutureProvider<List<LookupOption>>((ref) async {
      final repository = ref.watch(inspectionLogRepositoryProvider);
      return repository.getManagementStatuses();
    });

typedef LocationManagementLogsParams = ({
  String contribuyenteId,
  String? patentId,
});

final locationManagementLogsProvider =
    FutureProvider.family<List<LocationManagementLog>,
        LocationManagementLogsParams>((ref, params) async {
      if (params.contribuyenteId.trim().isEmpty) {
        return const <LocationManagementLog>[];
      }

      final repository = ref.watch(inspectionLogRepositoryProvider);
      final now = DateTime.now();
      final dateTo = DateTime(now.year, now.month, now.day);
      final dateFrom = DateTime(dateTo.year, dateTo.month - 6, dateTo.day);

      return repository.getLocationManagementLogs(
        contribuyenteId: params.contribuyenteId,
        patentId: params.patentId,
        dateFrom: dateFrom,
        dateTo: dateTo,
        perPage: 20,
      );
    });

class InspectionLogState {
  const InspectionLogState({
    this.isSubmitting = false,
    this.success = false,
    this.errorMessage,
    this.feedbackMessage,
  });

  final bool isSubmitting;
  final bool success;
  final String? errorMessage;
  final String? feedbackMessage;

  InspectionLogState copyWith({
    bool? isSubmitting,
    bool? success,
    String? errorMessage,
    String? feedbackMessage,
  }) {
    return InspectionLogState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      success: success ?? this.success,
      errorMessage: errorMessage,
      feedbackMessage: feedbackMessage,
    );
  }
}

class InspectionLogNotifier extends StateNotifier<InspectionLogState> {
  InspectionLogNotifier(this.ref) : super(const InspectionLogState());

  final Ref ref;

  Future<void> submit(
    InspectionLogPayload payload, {
    List<String> evidencePaths = const <String>[],
  }) async {
    state = const InspectionLogState(isSubmitting: true, success: false);

    final repository = ref.read(inspectionLogRepositoryProvider);

    try {
      await repository.submitLog(payload);

      var uploadedCount = 0;
      var failedCount = 0;

      for (final path in evidencePaths) {
        try {
          await repository.uploadVisitEvidence(
            visitAssignmentId: payload.arrearVisitAssignmentId,
            filePath: path,
            capturedAt: DateTime.now(),
            notes:
                'Evidencia de visita ${payload.arrearVisitAssignmentId}',
          );
          uploadedCount++;
        } catch (e) {
          failedCount++;
          debugPrint(
            '[InspectionLogNotifier] fallo subiendo evidencia path=$path error=$e',
          );
        }
      }

      final feedback = evidencePaths.isEmpty
          ? 'Gestion registrada correctamente.'
          : failedCount == 0
              ? 'Gestion registrada y $uploadedCount evidencia(s) adjuntada(s).'
              : 'Gestion registrada. $uploadedCount evidencia(s) adjuntada(s), $failedCount fallo/fallaron.';

      state = InspectionLogState(
        isSubmitting: false,
        success: true,
        feedbackMessage: feedback,
      );
    } catch (e) {
      state = InspectionLogState(
        isSubmitting: false,
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() {
    state = const InspectionLogState();
  }
}

final inspectionLogProvider =
    StateNotifierProvider.autoDispose<InspectionLogNotifier, InspectionLogState>(
      (ref) {
        return InspectionLogNotifier(ref);
      },
    );
