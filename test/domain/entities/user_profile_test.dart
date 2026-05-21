import 'package:access_plate/domain/entities/grocery.dart';
import 'package:access_plate/domain/entities/user_constraints.dart';
import 'package:access_plate/domain/entities/user_profile.dart';
import 'package:access_plate/domain/value_objects/availability_context.dart';
import 'package:access_plate/domain/value_objects/benefit_program.dart';
import 'package:access_plate/domain/value_objects/transportation_mode.dart';
import 'package:access_plate/domain/value_objects/user_language.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('legacy preference stage migrates to dietary style screen', () {
    expect(
      OnboardingStage.fromName('preference'),
      OnboardingStage.dietaryStyle,
    );
  });

  test('empty saved availability falls back to default contexts', () {
    final constraints = UserConstraints.fromJson(const {
      'feasibility': {'availability': []},
    });

    expect(
      constraints.feasibility.availability,
      equals({AvailabilityContext.grocery, AvailabilityContext.convenience}),
    );
  });

  test('selected grocery store survives json round-trip', () {
    final constraints = UserConstraints.defaults().copyWith(
      feasibility: const FeasibilityConstraints(
        groceryStore: GroceryStore(
          retailer: GroceryRetailer.kroger,
          locationId: '01400477',
          name: 'Kroger Delhi',
          addressLine1: '5080 Delhi Pike',
          city: 'Cincinnati',
          state: 'OH',
          postalCode: '45238',
        ),
      ),
    );

    final roundTrip = UserConstraints.fromJson(constraints.toJson());

    expect(roundTrip.feasibility.groceryStore?.locationId, '01400477');
    expect(roundTrip.feasibility.groceryStore?.name, 'Kroger Delhi');
  });

  test('access and pantry settings survive json round-trip', () {
    final constraints = UserConstraints.defaults().copyWith(
      access: const AccessConstraints(
        postalCode: '45211',
        transportation: TransportationMode.transit,
        maxTravelMinutes: 35,
        benefitPrograms: {BenefitProgram.snap, BenefitProgram.wic},
        emergencyMode: true,
        language: UserLanguage.spanish,
        plainLanguage: false,
      ),
      pantry: const PantryConstraints(
        itemsOnHand: {'rice', 'beans', 'oats'},
      ),
    );

    final roundTrip = UserConstraints.fromJson(constraints.toJson());

    expect(roundTrip.access.postalCode, '45211');
    expect(roundTrip.access.transportation, TransportationMode.transit);
    expect(roundTrip.access.maxTravelMinutes, 35);
    expect(
      roundTrip.access.benefitPrograms,
      equals({BenefitProgram.snap, BenefitProgram.wic}),
    );
    expect(roundTrip.access.emergencyMode, isTrue);
    expect(roundTrip.access.language, UserLanguage.spanish);
    expect(roundTrip.access.plainLanguage, isFalse);
    expect(roundTrip.pantry.itemsOnHand, containsAll({'rice', 'beans', 'oats'}));
  });
}
