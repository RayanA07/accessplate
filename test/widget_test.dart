import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:access_plate/presentation/widgets/section_card.dart';
import 'package:access_plate/presentation/widgets/selection_tile.dart';

void main() {
  testWidgets('section card renders child content', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SectionCard(child: Text('AccessPlate'))),
      ),
    );

    expect(find.text('AccessPlate'), findsOneWidget);
  });

  testWidgets('selection tile gives selected items a darker surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SelectionTile(title: 'Selected', selected: true, onTap: () {}),
              SelectionTile(title: 'Unselected', selected: false, onTap: () {}),
            ],
          ),
        ),
      ),
    );

    final inks = tester.widgetList<Ink>(find.byType(Ink)).toList();
    final selectedDecoration = inks.first.decoration! as BoxDecoration;
    final unselectedDecoration = inks.last.decoration! as BoxDecoration;

    expect(selectedDecoration.color, const Color(0xFFE3E3E8));
    expect(unselectedDecoration.color, Colors.white);
  });
}
