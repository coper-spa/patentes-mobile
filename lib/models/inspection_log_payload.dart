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
    this.lat,
    this.long,
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
  final double? lat;
  final double? long;

  InspectionLogPayload copyWith({
    String? patentArrearId,
    String? visitableType,
    String? visitableId,
    String? arrearVisitAssignmentId,
    String? arrearManagementTypeId,
    String? managementStatus,
    String? visitStateId,
    DateTime? managedAt,
    String? observation,
    bool? hasEvidence,
    double? lat,
    double? long,
    bool clearVisitStateId = false,
  }) {
    return InspectionLogPayload(
      patentArrearId: patentArrearId ?? this.patentArrearId,
      visitableType: visitableType ?? this.visitableType,
      visitableId: visitableId ?? this.visitableId,
      arrearVisitAssignmentId:
          arrearVisitAssignmentId ?? this.arrearVisitAssignmentId,
      arrearManagementTypeId:
          arrearManagementTypeId ?? this.arrearManagementTypeId,
      managementStatus: managementStatus ?? this.managementStatus,
      visitStateId: clearVisitStateId ? null : (visitStateId ?? this.visitStateId),
      managedAt: managedAt ?? this.managedAt,
      observation: observation ?? this.observation,
      hasEvidence: hasEvidence ?? this.hasEvidence,
      lat: lat ?? this.lat,
      long: long ?? this.long,
    );
  }

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

    if (lat != null && lat! >= -90 && lat! <= 90) {
      payload['lat'] = lat;
    }

    if (long != null && long! >= -180 && long! <= 180) {
      payload['long'] = long;
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
