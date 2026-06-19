import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/inspector_group_storage.dart';
import '../models/inspector_group.dart';
import '../models/inspector_profile.dart';

class InspectorGroupSessionState {
  const InspectorGroupSessionState({
    this.isInspector = false,
    this.availableGroups = const <InspectorGroup>[],
    this.activeGroupId,
    this.errorMessage,
    this.initialized = false,
  });

  final bool isInspector;
  final List<InspectorGroup> availableGroups;
  final String? activeGroupId;
  final String? errorMessage;
  final bool initialized;

  bool get hasConfigurationError =>
      isInspector && availableGroups.isEmpty && errorMessage != null;

  bool get requiresSelection =>
      isInspector &&
      availableGroups.length > 1 &&
      (activeGroupId == null || activeGroupId!.trim().isEmpty) &&
      errorMessage == null;

  String? get activeGroupName {
    if (activeGroupId == null || activeGroupId!.trim().isEmpty) {
      return null;
    }

    for (final group in availableGroups) {
      if (group.id == activeGroupId) {
        return group.name;
      }
    }

    return null;
  }

  InspectorGroupSessionState copyWith({
    bool? isInspector,
    List<InspectorGroup>? availableGroups,
    String? activeGroupId,
    bool clearActiveGroupId = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? initialized,
  }) {
    return InspectorGroupSessionState(
      isInspector: isInspector ?? this.isInspector,
      availableGroups: availableGroups ?? this.availableGroups,
      activeGroupId: clearActiveGroupId
          ? null
          : (activeGroupId ?? this.activeGroupId),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      initialized: initialized ?? this.initialized,
    );
  }
}

class InspectorGroupSessionNotifier
    extends StateNotifier<InspectorGroupSessionState> {
  InspectorGroupSessionNotifier(this._storage)
    : super(const InspectorGroupSessionState());

  final InspectorGroupStorage _storage;

  Future<void> syncWithProfile(
    InspectorProfile profile,
  ) async {
    if (!profile.isInspector) {
      await clearSession();
      state = const InspectorGroupSessionState(
        isInspector: false,
        initialized: true,
      );
      return;
    }

    final availableGroups = profile.inspectorGroups
        .where((group) => group.id.trim().isNotEmpty)
        .toList(growable: false);

    if (availableGroups.isEmpty) {
      await _storage.clearActiveGroupId();
      state = const InspectorGroupSessionState(
        isInspector: true,
        availableGroups: <InspectorGroup>[],
        activeGroupId: null,
        errorMessage:
            'Tu usuario inspector no tiene grupos configurados. Contacta al administrador.',
        initialized: true,
      );
      return;
    }

    final persistedId = await _storage.readActiveGroupId();
    final hasPersisted = persistedId != null &&
        availableGroups.any((group) => group.id == persistedId);

    if (availableGroups.length == 1) {
      final id = availableGroups.first.id;
      await _storage.saveActiveGroupId(id);
      state = InspectorGroupSessionState(
        isInspector: true,
        availableGroups: availableGroups,
        activeGroupId: id,
        initialized: true,
      );
      return;
    }

    state = InspectorGroupSessionState(
      isInspector: true,
      availableGroups: availableGroups,
      activeGroupId: hasPersisted ? persistedId : null,
      initialized: true,
    );
  }

  Future<void> setActiveGroupId(String groupId) async {
    final normalizedId = groupId.trim();
    if (normalizedId.isEmpty) {
      return;
    }

    final exists = state.availableGroups.any((group) => group.id == normalizedId);
    if (!exists) {
      state = state.copyWith(
        errorMessage: 'El grupo inspector seleccionado no esta autorizado.',
      );
      return;
    }

    await _storage.saveActiveGroupId(normalizedId);
    state = state.copyWith(
      activeGroupId: normalizedId,
      clearErrorMessage: true,
      initialized: true,
    );
  }

  Future<void> clearSession() async {
    await _storage.clearActiveGroupId();
    state = const InspectorGroupSessionState();
  }
}
