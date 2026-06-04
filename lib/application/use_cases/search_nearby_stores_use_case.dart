import '../../domain/entities/grocery.dart';
import '../../domain/entities/store_search.dart';
import '../../domain/repositories/grocery_catalog_repository.dart';
import '../../domain/repositories/store_locator_repository.dart';
import '../../domain/value_objects/availability_context.dart';
import '../../domain/value_objects/transportation_mode.dart';

class SearchNearbyStoresUseCase {
  SearchNearbyStoresUseCase(
    this._storeLocatorRepository, {
    GroceryCatalogRepository? groceryCatalogRepository,
  }) : _groceryCatalogRepository = groceryCatalogRepository;

  final StoreLocatorRepository _storeLocatorRepository;
  final GroceryCatalogRepository? _groceryCatalogRepository;

  Future<List<NearbyStore>> execute({
    required SearchLocation origin,
    required Set<AvailabilityContext> categories,
    required TransportationMode transportationMode,
    required int maxTravelMinutes,
  }) async {
    if (!_storeLocatorRepository.isConfigured || categories.isEmpty) {
      return const [];
    }

    final stores = await _storeLocatorRepository.searchNearbyStores(
      origin: origin,
      categories: categories,
      radiusMeters: _radiusMetersFor(
        transportationMode: transportationMode,
        maxTravelMinutes: maxTravelMinutes,
      ),
    );
    if (stores.isEmpty) {
      return const [];
    }

    final routeMetrics = await _storeLocatorRepository.computeTravelMetrics(
      origin: origin,
      stores: stores,
      transportationMode: transportationMode,
    );

    final withRoutes = stores
        .map(
          (store) => store.copyWith(
            travelMetric: routeMetrics[store.placeId] ?? store.travelMetric,
          ),
        )
        .toList(growable: false);

    final linked = await _linkKrogerStores(
      withRoutes,
      fallbackPostalCode: origin.postalCode,
    );
    linked.sort((left, right) {
      final leftMetric = left.travelMetric;
      final rightMetric = right.travelMetric;
      final leftDuration = leftMetric.durationMinutes;
      final rightDuration = rightMetric.durationMinutes;
      if (leftDuration != null && rightDuration != null) {
        final byDuration = leftDuration.compareTo(rightDuration);
        if (byDuration != 0) {
          return byDuration;
        }
      }
      final leftDistance = leftMetric.distanceMiles ?? double.infinity;
      final rightDistance = rightMetric.distanceMiles ?? double.infinity;
      final byDistance = leftDistance.compareTo(rightDistance);
      if (byDistance != 0) {
        return byDistance;
      }
      return left.name.compareTo(right.name);
    });
    return linked;
  }

  Future<List<NearbyStore>> _linkKrogerStores(
    List<NearbyStore> stores, {
    String? fallbackPostalCode,
  }) async {
    final repository = _groceryCatalogRepository;
    if (repository == null || !repository.isConfigured) {
      return stores;
    }

    final cache = <String, List<GroceryStore>>{};
    final result = <NearbyStore>[];
    for (final store in stores) {
      if (!_looksLikeKrogerBrand(store.name)) {
        result.add(store);
        continue;
      }

      final postalCode = _postalCodeFromAddress(store.address) ?? fallbackPostalCode;
      if (postalCode == null) {
        result.add(store);
        continue;
      }

      final candidates = cache.putIfAbsent(
        postalCode,
        () => [],
      );
      if (candidates.isEmpty) {
        try {
          final found = await repository.searchStores(postalCode: postalCode);
          candidates.addAll(found);
        } on GroceryCatalogException {
          result.add(store);
          continue;
        }
      }

      final match = _bestKrogerMatch(store, candidates);
      result.add(store.copyWith(linkedGroceryStore: match));
    }
    return result;
  }

  GroceryStore? _bestKrogerMatch(
    NearbyStore store,
    List<GroceryStore> candidates,
  ) {
    final normalizedStoreName = _normalize(store.name);
    GroceryStore? best;
    int bestScore = -1;

    for (final candidate in candidates) {
      var score = 0;
      final normalizedCandidateName = _normalize(candidate.name);
      if (normalizedStoreName == normalizedCandidateName) {
        score += 5;
      } else if (normalizedStoreName.contains(normalizedCandidateName) ||
          normalizedCandidateName.contains(normalizedStoreName)) {
        score += 3;
      }

      final candidateAddress = _normalize(candidate.addressLabel);
      final storeAddress = _normalize(store.address);
      if (candidateAddress.isNotEmpty &&
          storeAddress.isNotEmpty &&
          (candidateAddress.contains(storeAddress) ||
              storeAddress.contains(candidateAddress))) {
        score += 4;
      }

      if (candidate.postalCode.isNotEmpty &&
          store.address.contains(candidate.postalCode)) {
        score += 2;
      }

      if (score > bestScore) {
        bestScore = score;
        best = candidate;
      }
    }

    return bestScore > 0 ? best : null;
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _looksLikeKrogerBrand(String name) {
    final normalized = _normalize(name);
    return _krogerBrands.any(normalized.contains);
  }

  String? _postalCodeFromAddress(String address) {
    final match = RegExp(r'\b(\d{5})(?:-\d{4})?\b').firstMatch(address);
    return match?.group(1);
  }

  int _radiusMetersFor({
    required TransportationMode transportationMode,
    required int maxTravelMinutes,
  }) {
    final speedMph = switch (transportationMode) {
      TransportationMode.limited => 2.0,
      TransportationMode.walk => 3.0,
      TransportationMode.transit => 12.0,
      TransportationMode.car => 25.0,
    };
    final minutes = maxTravelMinutes.clamp(5, 60);
    final miles = (speedMph * minutes / 60) * 0.8;
    final meters = (miles * 1609.344).round();
    return meters.clamp(1600, 32000);
  }
}

const _krogerBrands = <String>[
  'kroger',
  'ralphs',
  'fred meyer',
  'king soopers',
  'frys',
  'fry s',
  'dillons',
  'smiths',
  'smith s',
  'marianos',
  'mariano s',
  'harris teeter',
  'qfc',
  'food 4 less',
  'city market',
  'metro market',
  'pick n save',
  'gerbes',
  'bakers',
  'jay c',
  'owens',
  'copps',
];
