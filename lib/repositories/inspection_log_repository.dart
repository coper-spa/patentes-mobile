import '../models/inspection_log_payload.dart';
import '../models/inspection_point.dart';
import '../models/location_management_log.dart';
import '../models/lookup_option.dart';

abstract class InspectionLogRepository {
  Future<InspectionPoint> getInspectionDetail(String inspectionId);
  Future<List<LookupOption>> getManagementTypes();
  Future<List<LookupOption>> getManagementStatuses();
  Future<List<LocationManagementLog>> getLocationManagementLogs({
    required String contribuyenteId,
    String? patentId,
    required DateTime dateFrom,
    required DateTime dateTo,
    int perPage,
  });
  Future<void> submitLog(InspectionLogPayload payload);
  Future<void> uploadVisitEvidence({
    required String visitAssignmentId,
    required String filePath,
    String? notes,
    DateTime? capturedAt,
  });
}
