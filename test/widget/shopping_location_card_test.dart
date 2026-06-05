import 'dart:async';

import 'package:access_plate/domain/entities/user_profile.dart';
import 'package:access_plate/presentation/providers/nearby_store_providers.dart';
import 'package:access_plate/presentation/providers/profile_controller.dart';
import 'package:access_plate/domain/entities/store_search.dart';
import 'package:access_plate/domain/value_objects/availability_context.dart';
import 'package:access_plate/presentation/widgets/shopping_location_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'shopping location card shows offline mode when location is unavailable',
    (tester) async {
      await tester.pumpWidget(
        _buildHarness(
          state: const ShoppingLocationState(apiConfigured: true),
          mode: const StoreAvailabilityModeState(
            mode: StoreAvailabilityMode.offline,
            apiConfigured: true,
            hasInternet: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Using your saved store access — connect to internet for live store lookup',
        ),
        findsOneWidget,
      );
      expect(find.text('Address or ZIP'), findsNothing);
      expect(find.text('Use current location'), findsNothing);
      expect(find.textContaining('GOOGLE_MAPS_API_KEY'), findsNothing);
      expect(find.textContaining('map key'), findsNothing);
      expect(find.text('Offline mode'), findsNothing);
      expect(find.text('Device location'), findsNothing);
      expect(find.text('Live'), findsNothing);
      expect(find.text('Loading'), findsNothing);
    },
  );

  testWidgets(
    'shopping location card shows device location and live when nearby stores are found',
    (tester) async {
      await tester.pumpWidget(
        _buildHarness(
          state: ShoppingLocationState(
            apiConfigured: true,
            location: _liveDeviceLocation,
          ),
          mode: const StoreAvailabilityModeState(
            mode: StoreAvailabilityMode.online,
            apiConfigured: true,
            hasInternet: true,
            location: _liveDeviceLocation,
            nearbyStores: [_nearbyStore],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Device location'), findsOneWidget);
      expect(find.text('Live'), findsOneWidget);
      expect(find.text('Offline mode'), findsNothing);
      expect(find.text('Searching...'), findsNothing);
      expect(find.text('Loading'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('1 stores'), findsNothing);
    },
  );

  testWidgets(
    'shopping location card shows searching state with spinner while nearby stores are loading',
    (tester) async {
      final completer = Completer<List<NearbyStore>>();

      await tester.pumpWidget(
        _buildHarness(
          state: ShoppingLocationState(
            apiConfigured: true,
            location: _liveDeviceLocation,
          ),
          mode: const StoreAvailabilityModeState(
            mode: StoreAvailabilityMode.searching,
            apiConfigured: true,
            hasInternet: true,
            location: _liveDeviceLocation,
          ),
          nearbyBuilder: (ref) => completer.future,
        ),
      );
      await tester.pump();

      expect(find.text('Device location'), findsOneWidget);
      expect(find.text('Searching...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Live'), findsNothing);
      expect(find.text('Offline mode'), findsNothing);
      expect(find.text('Loading'), findsNothing);
    },
  );
}

Widget _buildHarness({
  required ShoppingLocationState state,
  required StoreAvailabilityModeState mode,
  Future<List<NearbyStore>> Function(Ref ref)? nearbyBuilder,
}) {
  return ProviderScope(
    overrides: [
      profileControllerProvider.overrideWith(
        () => _TestProfileController(UserProfile.defaults()),
      ),
      shoppingLocationStateProvider.overrideWith((ref) => state),
      storeAvailabilityModeProvider.overrideWith((ref) => mode),
      if (nearbyBuilder != null)
        nearbyStoresProvider.overrideWith(nearbyBuilder),
    ],
    child: const MaterialApp(home: Scaffold(body: ShoppingLocationCard())),
  );
}

const _liveDeviceLocation = SearchLocation(
  kind: SearchLocationKind.device,
  label: '4001 W Chicago Ave, Chicago, IL 60651',
  latitude: 41.8955,
  longitude: -87.7261,
  verification: DataVerification.live,
  postalCode: '60651',
);

const _nearbyStore = NearbyStore(
  placeId: 'store-1',
  name: 'Save A Lot',
  address: '4200 W Chicago Ave, Chicago, IL 60651',
  latitude: 41.896,
  longitude: -87.727,
  categories: {AvailabilityContext.grocery},
  discoveryVerification: DataVerification.live,
  travelMetric: TravelMetric(
    source: TravelMetricSource.liveRoute,
    distanceMiles: 0.8,
    durationMinutes: 6,
  ),
);

class _TestProfileController extends ProfileController {
  _TestProfileController(this._profile);

  final UserProfile _profile;

  @override
  Future<UserProfile> build() async => _profile;
}
