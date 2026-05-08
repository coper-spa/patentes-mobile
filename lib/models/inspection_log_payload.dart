class InspectionLogPayload {
  const InspectionLogPayload({
    this.patentArrearId,
    this.visitableType,
    this.visitableId,
    required this.arrearVisitAssignmentId,
    required this.arrearManagementTypeId,
    required this.managementStatus,
    this.visitStateId,
    required this.managedAt,
    required this.observation,
    this.hasEvidence,
  });

  final String? patentArrearId;
  final String? visitableType;
  final String? visitableId;
  final String arrearVisitAssignmentId;
  final String arrearManagementTypeId;
  final String managementStatus;
  final String? visitStateId;
  final DateTime managedAt;
  final String observation;
  final bool? hasEvidence;

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{
      'arrear_visit_assignment_id': arrearVisitAssignmentId,
      'arrear_management_type_id': arrearManagementTypeId,
      'management_status': managementStatus,
      'managed_at': _formatDate(managedAt),
      'observation': observation,
    };

    if (visitStateId != null && visitStateId!.trim().isNotEmpty) {
      payload['visit_state_id'] = visitStateId!.trim();
    }

    if (patentArrearId != null && patentArrearId!.trim().isNotEmpty) {
      payload['patent_arrear_id'] = patentArrearId!.trim();
    }

    final normalizedVisitableType = visitableType?.trim();
    final normalizedVisitableId = visitableId?.trim();
    if ((normalizedVisitableType?.isNotEmpty ?? false) &&
        (normalizedVisitableId?.isNotEmpty ?? false)) {
      payload['visitable_type'] = normalizedVisitableType;
      payload['visitable_id'] = normalizedVisitableId;
    }

    if (hasEvidence != null) {
      payload['has_evidence'] = hasEvidence;
    }

    return payload;
  }

  static String _formatDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
