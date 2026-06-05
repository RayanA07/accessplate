import '../../domain/entities/store_search.dart';

String? resolvedStoreDisplayName(NearbyStore store) {
  for (final candidate in [store.name, store.linkedGroceryStore?.name]) {
    final cleaned = candidate?.trim();
    if (cleaned == null || cleaned.isEmpty) {
      continue;
    }
    if (_looksLikeRawStoreIdentifier(cleaned, store.placeId)) {
      continue;
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(cleaned)) {
      continue;
    }
    return cleaned;
  }
  return null;
}

String? compactStoreTravelLabel(TravelMetric metric) {
  final distance = metric.distanceMiles;
  if (distance != null) {
    final prefix = metric.isApproximate ? 'Approx. ' : '';
    if (distance < 0.1) {
      return '${prefix}<0.1 mi';
    }
    return '$prefix${distance.toStringAsFixed(1)} mi';
  }

  final duration = metric.durationMinutes;
  if (duration != null) {
    return '$duration min';
  }
  return null;
}

bool _looksLikeRawStoreIdentifier(String candidate, String placeId) {
  final normalizedCandidate = _normalize(candidate);
  if (normalizedCandidate.isEmpty) {
    return true;
  }
  if (RegExp(r'^\d+$').hasMatch(normalizedCandidate)) {
    return true;
  }

  final normalizedPlaceId = _normalize(placeId);
  if (normalizedPlaceId.isNotEmpty &&
      normalizedCandidate == normalizedPlaceId) {
    return true;
  }

  final placeIdSuffix = RegExp(r'(\d+)$').firstMatch(placeId)?.group(1);
  if (placeIdSuffix != null && normalizedCandidate == placeIdSuffix) {
    return true;
  }

  return false;
}

String _normalize(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
}
