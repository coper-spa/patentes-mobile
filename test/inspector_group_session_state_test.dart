import 'package:flutter_test/flutter_test.dart';
import 'package:inspectores_municipales_app/core/storage/inspector_group_storage.dart';
import 'package:inspectores_municipales_app/models/inspector_group.dart';
import 'package:inspectores_municipales_app/models/inspector_profile.dart';
import 'package:inspectores_municipales_app/providers/inspector_group_session_state.dart';

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
  group('InspectorGroupSessionNotifier', () {
    test('requires mandatory selection when inspector has many groups', () async {
      final notifier = InspectorGroupSessionNotifier(
        _InMemoryInspectorGroupStorage(),
      );

      await notifier.syncWithProfile(
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

      expect(notifier.state.isInspector, isTrue);
      expect(notifier.state.requiresSelection, isTrue);
      expect(notifier.state.activeGroupId, isNull);
    });

    test('autoselects the only inspector group', () async {
      final notifier = InspectorGroupSessionNotifier(
        _InMemoryInspectorGroupStorage(),
      );

      await notifier.syncWithProfile(
        const InspectorProfile(
          id: '1',
          fullName: 'Inspector',
          email: 'inspector@test.dev',
          userGroup: 'inspector',
          inspectorGroups: <InspectorGroup>[
            InspectorGroup(id: '10', name: 'Zona Norte'),
          ],
        ),
      );

      expect(notifier.state.requiresSelection, isFalse);
      expect(notifier.state.activeGroupId, '10');
    });
  });
}
