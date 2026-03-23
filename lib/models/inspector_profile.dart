class InspectorProfile {
  const InspectorProfile({
    required this.id,
    required this.fullName,
    required this.email,
  });

  final String id;
  final String fullName;
  final String email;

  factory InspectorProfile.fromJson(Map<String, dynamic> json) {
    return InspectorProfile(
      id: json['id'].toString(),
      fullName: (json['name'] ?? json['full_name'] ?? '') as String,
      email: (json['email'] ?? '') as String,
    );
  }
}
