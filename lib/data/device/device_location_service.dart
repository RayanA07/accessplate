import 'package:geolocator/geolocator.dart';

import '../../domain/entities/store_search.dart';

class DeviceLocationService {
  const DeviceLocationService();

  Future<DeviceLocationFix> determineCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const StoreSearchException('Location services are turned off.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const StoreSearchException('Location permission was denied.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw const StoreSearchException(
        'Location permission is permanently denied for this device.',
      );
    }

    final accuracy = await Geolocator.getLocationAccuracy();
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    return DeviceLocationFix(
      latitude: position.latitude,
      longitude: position.longitude,
      isPrecise: accuracy != LocationAccuracyStatus.reduced,
    );
  }
}
