class InspectionVisit {
  const InspectionVisit({
    required this.visitedAt,
    required this.managementType,
    required this.status,
    required this.comment,
  });

  final DateTime visitedAt;
  final String managementType;
  final String status;
  final String comment;

  factory InspectionVisit.fromJson(Map<String, dynamic> json) {
    final managementType = json['management_type'];
    final managementTypeMap = managementType is Map<String, dynamic>
        ? managementType
        : <String, dynamic>{};
    final arrearManagementType =
        json['arrear_management_type'] is Map<String, dynamic>
            ? json['arrear_management_type'] as Map<String, dynamic>
            : <String, dynamic>{};

    final typeLabel = _firstNonEmpty(<Object?>[
      managementTypeMap['label'],
      managementTypeMap['name'],
      arrearManagementType['label'],
      arrearManagementType['name'],
      json['management_type_label'],
      json['management_type_name'],
    ]);
    final typeCode = _firstNonEmpty(<Object?>[
      managementTypeMap['descriptor'],
      managementType,
      json['management_type_code'],
    ]);

    return InspectionVisit(
      visitedAt: DateTime.tryParse(
            (json['visited_at'] ??
                    json['managed_at'] ??
                    json['created_at'] ??
                    '')
                .toString(),
          ) ??
          DateTime.now(),
      managementType: _toDisplayType(typeLabel, typeCode),
      status: (json['status'] ?? json['management_status'] ?? '').toString(),
      comment: (json['comment'] ?? json['observation'] ?? '').toString(),
    );
  }

  static String _firstNonEmpty(List<Object?> candidates) {
    for (final value in candidates) {
      final asText = (value ?? '').toString().trim();
      if (asText.isNotEmpty) {
        return asText;
      }
    }
    return '';
  }

  static String _toDisplayType(String labelCandidate, String codeCandidate) {
    final label = labelCandidate.trim();
    if (label.isNotEmpty) {
      return label;
    }

    final code = codeCandidate.trim();
    if (code.isEmpty) {
      return '';
    }

    final normalized = code
        .replaceAll(RegExp(r'^[a-z]+[\\._-]'), '')
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .trim();

    if (normalized.isEmpty) {
      return code;
    }

    return normalized
        .split(RegExp(r'\s+'))
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }
}
