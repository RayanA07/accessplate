import 'package:access_plate/presentation/providers/nearby_store_providers.dart';
import 'package:access_plate/presentation/widgets/shopping_location_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shopping location card uses non-Google copy by default', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shoppingLocationStateProvider.overrideWith(
            (ref) => const ShoppingLocationState(apiConfigured: true),
          ),
          nearbyStoresProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ShoppingLocationCard()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Location is set during onboarding'),
      findsOneWidget,
    );
    expect(find.text('Address or ZIP'), findsNothing);
    expect(find.text('Use current location'), findsNothing);
    expect(find.textContaining('GOOGLE_MAPS_API_KEY'), findsNothing);
    expect(find.textContaining('map key'), findsNothing);
  });
}
