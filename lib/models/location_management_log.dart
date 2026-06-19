class LocationManagementLog {
  const LocationManagementLog({
    required this.id,
    required this.managementStatus,
    required this.managementTypeName,
    required this.managementTypeCode,
    required this.observation,
    required this.managedAt,
    required this.inspectorName,
    required this.hasEvidence,
    required this.managementLatitude,
    required this.managementLongitude,
  });

  final String id;
  final String managementStatus;
  final String managementTypeName;
  final String managementTypeCode;
  final String observation;
  final DateTime managedAt;
  final String inspectorName;
  final bool hasEvidence;
  final double? managementLatitude;
  final double? managementLongitude;

  factory LocationManagementLog.fromJson(Map<String, dynamic> json) {
    final managementType = json['management_type'] is Map<String, dynamic>
        ? json['management_type'] as Map<String, dynamic>
        : <String, dynamic>{};
    final arrearManagementType =
      json['arrear_management_type'] is Map<String, dynamic>
        ? json['arrear_management_type'] as Map<String, dynamic>
        : <String, dynamic>{};
    final user = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : <String, dynamic>{};

    final rawManagementType = json['management_type'];
    final fallbackStringType = rawManagementType is String
        ? rawManagementType
        : '';

    final managementTypeName = _firstNonEmpty(<Object?>[
      managementType['label'],
      managementType['name'],
      arrearManagementType['label'],
      arrearManagementType['name'],
      json['management_type_label'],
      json['management_type_name'],
      json['arrear_management_type_name'],
    ]);

    final managementTypeCode = _firstNonEmpty(<Object?>[
      managementType['descriptor'],
      json['management_type_code'],
      fallbackStringType,
    ]);

    return LocationManagementLog(
      id: (json['id'] ?? '').toString(),
      managementStatus: (json['management_status'] ?? json['status'] ?? '')
          .toString(),
        managementTypeName: _toDisplayType(managementTypeName, managementTypeCode),
      managementTypeCode: managementTypeCode,
      observation: (json['observation'] ?? json['comment'] ?? '').toString(),
      managedAt: DateTime.tryParse(
            (json['managed_at'] ?? json['visited_at'] ?? json['created_at'] ?? '')
                .toString(),
          ) ??
          DateTime.now(),
      inspectorName: (user['name'] ?? json['managed_by_name'] ?? '').toString(),
      hasEvidence: (json['has_evidence'] as bool?) ?? false,
      managementLatitude: _toDouble(
        json['management_latitude'] ?? json['lat'] ?? json['latitude'],
      ),
      managementLongitude: _toDouble(
        json['management_longitude'] ?? json['long'] ?? json['longitude'],
      ),
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

  static double? _toDouble(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    final asText = value.toString().trim().replaceAll(',', '.');
    if (asText.isEmpty) {
      return null;
    }

    return double.tryParse(asText);
  }
}
