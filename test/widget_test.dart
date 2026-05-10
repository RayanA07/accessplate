import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:access_plate/presentation/widgets/section_card.dart';

void main() {
  testWidgets('section card renders child content', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SectionCard(child: Text('AccessPlate'))),
      ),
    );

    expect(find.text('AccessPlate'), findsOneWidget);
  });
}
