import 'package:access_plate/presentation/widgets/shopping_location_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'shopping location card shows the static demo location and live tag',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ShoppingLocationCard())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nearby stores'), findsOneWidget);
      expect(find.text('3758 W Madison St, Chicago, IL 60624'), findsOneWidget);
      expect(find.text('6 nearby stores matched.'), findsOneWidget);
      expect(find.text('Live'), findsOneWidget);
      expect(find.text('Device location'), findsNothing);
      expect(find.text('Offline mode'), findsNothing);
      expect(find.text('Search'), findsNothing);
      expect(find.text('Use current location'), findsNothing);
    },
  );

  testWidgets('shopping location card shows the hardcoded nearby store list', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ShoppingLocationCard())),
    );
    await tester.pumpAndSettle();

    expect(find.text("McDonald's | 0.2 mi"), findsOneWidget);
    expect(find.text('Dollar General | 0.4 mi'), findsOneWidget);
    expect(find.text('Family Dollar | 0.5 mi'), findsOneWidget);
    expect(find.text('Aldi | 0.7 mi'), findsOneWidget);
    expect(find.text('Popeyes | 0.3 mi'), findsOneWidget);
    expect(find.text('7-Eleven | 0.1 mi'), findsOneWidget);
  });
}
