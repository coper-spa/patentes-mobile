import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../models/inspection_log_payload.dart';
import '../../models/inspection_point.dart';
import '../../models/location_management_log.dart';
import '../../models/lookup_option.dart';
import '../inspection_log_repository.dart';
import 'package:flutter/foundation.dart';

class InspectionLogRepositoryImpl implements InspectionLogRepository {
  InspectionLogRepositoryImpl({required this.config, required this.apiClient});

  final AppConfig config;
  final ApiClient apiClient;

  @override
  Future<InspectionPoint> getInspectionDetail(String inspectionId) async {
    final path = config.inspectionDetailPath(inspectionId);
    final json = await apiClient.getJson(config.apiUri(path));
    return InspectionPoint.fromJson(_unwrapDataObject(json));
  }

  @override
  Future<List<LookupOption>> getManagementTypes() async {
    final json = await apiClient.getJson(
      config.apiUri(config.managementTypesEndpoint),
    );

    final rows = _extractRows(json);
    return rows
        .map(
          (row) => LookupOption(
            value: (row['id'] ?? row['value'] ?? '').toString(),
            label: (row['name'] ?? row['label'] ?? row['description'] ?? '')
                .toString(),
          ),
        )
        .where((option) => option.value.isNotEmpty && option.label.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<List<LookupOption>> getManagementStatuses() async {
    final json = await apiClient.getJson(
      config.apiUri(config.managementStatusesEndpoint),
    );

    final rows = _extractRows(json);
    return rows
        .map(
          (row) => LookupOption(
            value: (row['value'] ?? row['id'] ?? '').toString(),
            label: (row['label'] ?? row['name'] ?? '').toString(),
          ),
        )
        .where((option) => option.value.isNotEmpty && option.label.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<void> submitLog(InspectionLogPayload payload) async {
    await apiClient.postJson(
      config.apiUri(config.inspectionLogEndpoint),
      payload.toJson(),
    );
  }

  @override
  Future<void> uploadVisitEvidence({
    required String visitAssignmentId,
    required String filePath,
    String? notes,
    DateTime? capturedAt,
  }) async {
    final uri = config.apiUri('/api/v1/visit-assignments/$visitAssignmentId/evidences');
    final fields = <String, String>{
      if (capturedAt != null) 'captured_at': capturedAt.toUtc().toIso8601String(),
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    };

    await apiClient.postMultipartFile(
      uri,
      fileField: 'file',
      filePath: filePath,
      fields: fields,
    );
  }

  @override
  Future<List<LocationManagementLog>> getLocationManagementLogs({
    required String contribuyenteId,
    String? patentId,
    required DateTime dateFrom,
    required DateTime dateTo,
    int perPage = 20,
  }) async {
    if (contribuyenteId.trim().isEmpty) {
      debugPrint(
        '[InspectionLogRepository.locationManagementLogs] skip: contribuyenteId vacio para consulta de gestiones previas',
      );
      return const <LocationManagementLog>[];
    }

    final query = <String, String>{
      'date_from': _formatDate(dateFrom),
      'date_to': _formatDate(dateTo),
      'per_page': '$perPage',
    };

    if (patentId != null && patentId.trim().isNotEmpty) {
      query['patent_id'] = patentId.trim();
    }

    final path = config.contribuyenteManagementLogsPath(contribuyenteId.trim());
    final uri = config.apiUri(path).replace(queryParameters: query);

    debugPrint(
      '[InspectionLogRepository.locationManagementLogs] requestUri=$uri',
    );

    final json = await apiClient.getJson(uri);
    final rows = _extractRows(json);
    debugPrint(
      '[InspectionLogRepository.locationManagementLogs] responseRows=${rows.length}',
    );

    return rows
        .map(LocationManagementLog.fromJson)
        .toList(growable: false);
  }

  Map<String, dynamic> _unwrapDataObject(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    return json;
  }

  List<Map<String, dynamic>> _extractRows(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is List<dynamic>) {
      return data.whereType<Map<String, dynamic>>().toList(growable: false);
    }

    if (data is Map<String, dynamic>) {
      final nestedData = data['data'];
      if (nestedData is List<dynamic>) {
        return nestedData
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
      }

      final items = data['items'];
      if (items is List<dynamic>) {
        return items.whereType<Map<String, dynamic>>().toList(growable: false);
      }
    }

    return <Map<String, dynamic>>[];
  }

  String _formatDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
