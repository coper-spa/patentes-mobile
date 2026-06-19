class InspectorGroup {
  const InspectorGroup({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory InspectorGroup.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['value'] ?? json['inspector_group_id'] ?? '')
        .toString()
        .trim();
    final name = (json['name'] ?? json['label'] ?? json['description'] ?? '')
        .toString()
        .trim();

    return InspectorGroup(id: id, name: name);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
    };
  }
}
