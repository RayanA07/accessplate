import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../domain/entities/store_search.dart';

class DeviceLocationService {
  const DeviceLocationService();

  static const Duration _fixTimeout = Duration(seconds: 15);

  /// Distance accuracy (in meters) above which a fix is treated as approximate.
  static const double _preciseAccuracyMeters = 100;

  Future<DeviceLocationFix> determineCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const StoreSearchException(
        'Location services are turned off. Turn them on or enter an address instead.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw const StoreSearchException(
        'Location permission is permanently denied. Enable it in Settings or enter an address instead.',
      );
    }

    if (permission == LocationPermission.denied) {
      throw const StoreSearchException(
        'Location permission was denied. Enter an address or ZIP to search instead.',
      );
    }

    // System-level precision (e.g. iOS "Precise Location" off) plus the actual
    // reported accuracy together decide whether the fix is precise.
    final accuracyStatus = await Geolocator.getLocationAccuracy();

    final Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _fixTimeout,
        ),
      );
    } on TimeoutException {
      throw const StoreSearchException(
        'Getting your current location timed out. Try again or enter an address.',
      );
    } on LocationServiceDisabledException {
      throw const StoreSearchException(
        'Location services are turned off. Turn them on or enter an address instead.',
      );
    }

    final reducedSystemAccuracy =
        accuracyStatus == LocationAccuracyStatus.reduced;
    final coarseFix = position.accuracy > _preciseAccuracyMeters;

    return DeviceLocationFix(
      latitude: position.latitude,
      longitude: position.longitude,
      isPrecise: !reducedSystemAccuracy && !coarseFix,
    );
  }
}
