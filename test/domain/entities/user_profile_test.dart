import 'package:access_plate/domain/entities/grocery.dart';
import 'package:access_plate/domain/entities/store_search.dart';
import 'package:access_plate/domain/entities/user_constraints.dart';
import 'package:access_plate/domain/entities/user_profile.dart';
import 'package:access_plate/domain/value_objects/allergen.dart';
import 'package:access_plate/domain/value_objects/availability_context.dart';
import 'package:access_plate/domain/value_objects/benefit_program.dart';
import 'package:access_plate/domain/value_objects/medical_restriction.dart';
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

  test('legacy height and weight stages migrate to the body-stats step', () {
    expect(OnboardingStage.fromName('height'), OnboardingStage.age);
    expect(OnboardingStage.fromName('weight'), OnboardingStage.age);
  });

  test('legacy allergen and religion stages migrate to food restrictions', () {
    expect(OnboardingStage.fromName('allergens'), OnboardingStage.dietaryStyle);
    expect(OnboardingStage.fromName('religion'), OnboardingStage.dietaryStyle);
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

  test('default access zip starts unset', () {
    expect(UserConstraints.defaults().access.postalCode, isEmpty);
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
        stockByItem: {
          'rice': PantryStockLevel.enough,
          'beans': PantryStockLevel.low,
          'oats': PantryStockLevel.out,
        },
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
    expect(roundTrip.pantry.enoughItems, contains('rice'));
    expect(roundTrip.pantry.lowStockItems, contains('beans'));
    expect(roundTrip.pantry.restockItems, contains('oats'));
  });

  test('cached nearby store lookup survives json round-trip', () {
    final loggedAt = DateTime.utc(2026, 6, 4, 20, 26);
    final constraints = UserConstraints.defaults().copyWith(
      cachedNearbyStoreLookup: CachedNearbyStoreLookup(
        origin: const SearchLocation(
          kind: SearchLocationKind.device,
          label: '4001 W Chicago Ave, Chicago, IL 60651',
          latitude: 41.8955,
          longitude: -87.7261,
          verification: DataVerification.live,
          postalCode: '60651',
        ),
        stores: const [
          NearbyStore(
            placeId: 'store-1',
            name: 'Save A Lot',
            address: '4200 W Chicago Ave, Chicago, IL 60651',
            latitude: 41.896,
            longitude: -87.727,
            categories: {AvailabilityContext.grocery},
            primaryCategory: AvailabilityContext.grocery,
            discoveryVerification: DataVerification.live,
            travelMetric: TravelMetric(
              source: TravelMetricSource.liveRoute,
              distanceMiles: 0.8,
              durationMinutes: 6,
            ),
          ),
        ],
        cachedAt: loggedAt,
      ),
    );

    final roundTrip = UserConstraints.fromJson(constraints.toJson());

    expect(roundTrip.cachedNearbyStoreLookup, isNotNull);
    expect(roundTrip.cachedNearbyStoreLookup?.origin.postalCode, '60651');
    expect(roundTrip.cachedNearbyStoreLookup?.stores, hasLength(1));
    expect(roundTrip.cachedNearbyStoreLookup?.stores.first.name, 'Save A Lot');
  });

  test('logged meal entries survive json round-trip', () {
    final loggedAt = DateTime.utc(2026, 6, 4, 20, 26);
    final constraints = UserConstraints.defaults().copyWith(
      loggedMeals: [
        LoggedMealEntry(
          mealName: 'Tuna salad on whole-wheat',
          loggedAt: loggedAt,
          caloriesKcal: 390,
          foodIds: const [42],
        ),
      ],
      loggedMealHistory: [
        LoggedMealEntry(
          mealName: 'Bean and rice bowl',
          loggedAt: loggedAt.subtract(const Duration(days: 1)),
          caloriesKcal: 420,
          foodIds: const [7],
        ),
      ],
    );

    final roundTrip = UserConstraints.fromJson(constraints.toJson());

    expect(roundTrip.loggedMeals, hasLength(1));
    expect(roundTrip.loggedMeals.first.mealName, 'Tuna salad on whole-wheat');
    expect(roundTrip.loggedMeals.first.loggedAt.toUtc(), loggedAt);
    expect(roundTrip.loggedMeals.first.caloriesKcal, 390);
    expect(roundTrip.loggedMeals.first.foodIds, orderedEquals([42]));
    expect(roundTrip.loggedMealHistory, hasLength(1));
    expect(roundTrip.loggedMealHistory.first.mealName, 'Bean and rice bowl');
    expect(roundTrip.loggedMealHistory.first.caloriesKcal, 420);
  });

  test(
    'legacy logged meals seed lifetime history when no history exists yet',
    () {
      final constraints = UserConstraints.fromJson({
        'loggedMeals': [
          {
            'mealName': 'Peanut butter on whole wheat',
            'loggedAt': DateTime.utc(2026, 6, 4, 14, 30).toIso8601String(),
            'caloriesKcal': 280,
            'foodIds': [5],
          },
        ],
      });

      expect(constraints.loggedMeals, hasLength(1));
      expect(constraints.loggedMealHistory, hasLength(1));
      expect(
        constraints.loggedMealHistory.first.mealName,
        'Peanut butter on whole wheat',
      );
      expect(constraints.loggedMealHistory.first.caloriesKcal, 280);
    },
  );

  test('legacy pantry lists migrate to enough stock', () {
    final constraints = UserConstraints.fromJson(const {
      'pantry': {
        'itemsOnHand': ['rice', 'beans'],
      },
    });

    expect(constraints.pantry.stockFor('rice'), PantryStockLevel.enough);
    expect(constraints.pantry.stockFor('beans'), PantryStockLevel.enough);
  });

  test('celiac avoid derives wheat and gluten allergen exclusions', () {
    final constraints = UserConstraints.defaults().copyWith(
      safety: const SafetyConstraints(
        medicalAvoid: {MedicalRestriction.celiacDiseaseGlutenIntolerance},
      ),
    );

    expect(constraints.safety.effectiveAllergens, contains(Allergen.wheat));
    expect(constraints.safety.effectiveAllergens, contains(Allergen.gluten));
    expect(constraints.safety.allergens, isEmpty);
  });
}
