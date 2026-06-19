import 'package:flutter_test/flutter_test.dart';
import 'package:inspectores_municipales_app/models/inspection_log_payload.dart';

void main() {
  test('inspection payload serializes lat/long in valid range', () {
    final payload = InspectionLogPayload(
      arrearVisitAssignmentId: '1',
      arrearManagementTypeId: '2',
      managementStatus: 'en_gestion',
      managedAt: DateTime(2026, 6, 19),
      observation: 'obs',
      lat: -33.45,
      long: -70.66,
    );

    final json = payload.toJson();

    expect(json['lat'], -33.45);
    expect(json['long'], -70.66);
  });
}
