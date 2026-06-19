import 'dart:async';

import 'package:geolocator/geolocator.dart';

class DeviceLocationResult {
  const DeviceLocationResult({
    this.latitude,
    this.longitude,
    this.warningMessage,
  });

  final double? latitude;
  final double? longitude;
  final String? warningMessage;
}

abstract class DeviceLocationService {
  Future<DeviceLocationResult> getManagementCoordinates();
}

class GeolocatorDeviceLocationService implements DeviceLocationService {
  @override
  Future<DeviceLocationResult> getManagementCoordinates() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const DeviceLocationResult(
        warningMessage:
            'No fue posible obtener geolocalizacion porque el GPS esta desactivado.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return const DeviceLocationResult(
        warningMessage:
            'No se otorgo permiso de ubicacion. La gestion se enviara sin coordenadas.',
      );
    }

    Position? position = await Geolocator.getLastKnownPosition();

    if (position == null) {
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 8),
          ),
        );
      } on TimeoutException {
        return const DeviceLocationResult(
          warningMessage:
              'No se pudo obtener ubicacion a tiempo. La gestion se enviara sin coordenadas.',
        );
      } catch (_) {
        return const DeviceLocationResult(
          warningMessage:
              'No fue posible obtener la ubicacion. La gestion se enviara sin coordenadas.',
        );
      }
    }

    final lat = position.latitude;
    final long = position.longitude;

    return DeviceLocationResult(latitude: lat, longitude: long);
  }
}
