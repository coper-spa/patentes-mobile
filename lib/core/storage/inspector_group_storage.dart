import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class InspectorGroupStorage {
  Future<void> saveActiveGroupId(String groupId);
  Future<String?> readActiveGroupId();
  Future<void> clearActiveGroupId();
}

class SecureInspectorGroupStorage implements InspectorGroupStorage {
  SecureInspectorGroupStorage(this._storage);

  static const _activeInspectorGroupKey = 'active_inspector_group_id';
  final FlutterSecureStorage _storage;

  @override
  Future<void> saveActiveGroupId(String groupId) async {
    await _storage.write(key: _activeInspectorGroupKey, value: groupId);
  }

  @override
  Future<String?> readActiveGroupId() async {
    final value = await _storage.read(key: _activeInspectorGroupKey);
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    return value.trim();
  }

  @override
  Future<void> clearActiveGroupId() async {
    await _storage.delete(key: _activeInspectorGroupKey);
  }
}
