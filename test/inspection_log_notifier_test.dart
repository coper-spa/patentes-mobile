import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspectores_municipales_app/core/storage/inspector_group_storage.dart';
import 'package:inspectores_municipales_app/models/inspection_log_payload.dart';
import 'package:inspectores_municipales_app/models/inspector_group.dart';
import 'package:inspectores_municipales_app/models/inspector_profile.dart';
import 'package:inspectores_municipales_app/models/inspection_point.dart';
import 'package:inspectores_municipales_app/models/location_management_log.dart';
import 'package:inspectores_municipales_app/models/lookup_option.dart';
import 'package:inspectores_municipales_app/providers/app_providers.dart';
import 'package:inspectores_municipales_app/providers/inspection_detail_provider.dart';
import 'package:inspectores_municipales_app/repositories/inspection_log_repository.dart';
import 'package:inspectores_municipales_app/services/device_location_service.dart';

class _FakeInspectionLogRepository implements InspectionLogRepository {
  InspectionLogPayload? submittedPayload;

  @override
  Future<InspectionPoint> getInspectionDetail(String inspectionId) {
    throw UnimplementedError();
  }

  @override
  Future<List<LocationManagementLog>> getLocationManagementLogs({
    required String contribuyenteId,
    String? patentId,
    required DateTime dateFrom,
    required DateTime dateTo,
    int perPage = 20,
  }) async {
    return const <LocationManagementLog>[];
  }

  @override
  Future<List<LookupOption>> getManagementStatuses() async {
    return const <LookupOption>[];
  }

  @override
  Future<List<LookupOption>> getManagementTypes() async {
    return const <LookupOption>[];
  }

  @override
  Future<List<LookupOption>> getVisitStates() async {
    return const <LookupOption>[];
  }

  @override
  Future<void> submitLog(InspectionLogPayload payload) async {
    submittedPayload = payload;
  }

  @override
  Future<void> uploadVisitEvidence({
    required String visitAssignmentId,
    required String filePath,
    String? notes,
    DateTime? capturedAt,
  }) async {}
}

class _FakeDeviceLocationService implements DeviceLocationService {
  _FakeDeviceLocationService(this.result);

  final DeviceLocationResult result;

  @override
  Future<DeviceLocationResult> getManagementCoordinates() async {
    return result;
  }
}

class _InMemoryInspectorGroupStorage implements InspectorGroupStorage {
  String? _activeGroupId;

  @override
  Future<void> clearActiveGroupId() async {
    _activeGroupId = null;
  }

  @override
  Future<String?> readActiveGroupId() async {
    return _activeGroupId;
  }

  @override
  Future<void> saveActiveGroupId(String groupId) async {
    _activeGroupId = groupId;
  }
}

void main() {
  group('InspectionLogNotifier', () {
    test('submits management log with lat/long when location is available', () async {
      final repo = _FakeInspectionLogRepository();
      final container = ProviderContainer(
        overrides: <Override>[
          inspectionLogRepositoryProvider.overrideWithValue(repo),
          deviceLocationServiceProvider.overrideWithValue(
            _FakeDeviceLocationService(
              const DeviceLocationResult(latitude: -33.45, longitude: -70.66),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final payload = InspectionLogPayload(
        arrearVisitAssignmentId: '100',
        arrearManagementTypeId: '2',
        managementStatus: 'en_gestion',
        managedAt: DateTime(2026, 6, 19),
        observation: 'ok',
      );

      await container.read(inspectionLogProvider.notifier).submit(payload);

      expect(repo.submittedPayload, isNotNull);
      expect(repo.submittedPayload!.lat, -33.45);
      expect(repo.submittedPayload!.long, -70.66);
      expect(container.read(inspectionLogProvider).success, isTrue);
    });

    test('continues submit without location and emits warning', () async {
      final repo = _FakeInspectionLogRepository();
      final container = ProviderContainer(
        overrides: <Override>[
          inspectionLogRepositoryProvider.overrideWithValue(repo),
          deviceLocationServiceProvider.overrideWithValue(
            _FakeDeviceLocationService(
              const DeviceLocationResult(
                warningMessage: 'No location available',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final payload = InspectionLogPayload(
        arrearVisitAssignmentId: '100',
        arrearManagementTypeId: '2',
        managementStatus: 'en_gestion',
        managedAt: DateTime(2026, 6, 19),
        observation: 'ok',
      );

      await container.read(inspectionLogProvider.notifier).submit(payload);

      expect(repo.submittedPayload, isNotNull);
      expect(repo.submittedPayload!.lat, isNull);
      expect(repo.submittedPayload!.long, isNull);
      expect(container.read(inspectionLogProvider).success, isTrue);
      expect(container.read(inspectionLogProvider).warningMessage, 'No location available');
    });

    test('fails early when inspector has no active group', () async {
      final repo = _FakeInspectionLogRepository();
      final container = ProviderContainer(
        overrides: <Override>[
          inspectionLogRepositoryProvider.overrideWithValue(repo),
          deviceLocationServiceProvider.overrideWithValue(
            _FakeDeviceLocationService(
              const DeviceLocationResult(latitude: 1, longitude: 1),
            ),
          ),
          inspectorGroupStorageProvider.overrideWithValue(
            _InMemoryInspectorGroupStorage(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(inspectorGroupSessionProvider.notifier).syncWithProfile(
            const InspectorProfile(
              id: '1',
              fullName: 'Inspector',
              email: 'inspector@test.dev',
              userGroup: 'inspector',
              inspectorGroups: <InspectorGroup>[
                InspectorGroup(id: '10', name: 'Zona Norte'),
                InspectorGroup(id: '20', name: 'Zona Centro'),
              ],
            ),
          );

      final payload = InspectionLogPayload(
        arrearVisitAssignmentId: '100',
        arrearManagementTypeId: '2',
        managementStatus: 'en_gestion',
        managedAt: DateTime(2026, 6, 19),
        observation: 'ok',
      );

      await container.read(inspectionLogProvider.notifier).submit(payload);

      expect(repo.submittedPayload, isNull);
      expect(
        container.read(inspectionLogProvider).errorMessage,
        contains('grupo inspector activo'),
      );
    });
  });
}
