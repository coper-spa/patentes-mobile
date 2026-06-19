import 'inspector_group.dart';

class InspectorProfile {
  const InspectorProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.userGroup,
    required this.inspectorGroups,
  });

  final String id;
  final String fullName;
  final String email;
  final String userGroup;
  final List<InspectorGroup> inspectorGroups;

  bool get isInspector => userGroup.toLowerCase().trim() == 'inspector';

  factory InspectorProfile.fromJson(Map<String, dynamic> json) {
    final inspectorGroupsRaw = json['inspector_groups'];
    final inspectorGroups = inspectorGroupsRaw is List<dynamic>
        ? inspectorGroupsRaw
            .whereType<Map<String, dynamic>>()
            .map(InspectorGroup.fromJson)
            .where((group) => group.id.trim().isNotEmpty)
            .toList(growable: false)
        : const <InspectorGroup>[];

    return InspectorProfile(
      id: json['id'].toString(),
      fullName: (json['name'] ?? json['full_name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      userGroup: (json['user_group'] ?? json['group'] ?? '').toString(),
      inspectorGroups: inspectorGroups,
    );
  }
}
