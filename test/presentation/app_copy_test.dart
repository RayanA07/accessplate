import 'package:flutter_test/flutter_test.dart';

import 'package:access_plate/domain/value_objects/dietary_style.dart';
import 'package:access_plate/domain/value_objects/meal_type.dart';
import 'package:access_plate/domain/value_objects/prep_environment.dart';
import 'package:access_plate/domain/value_objects/transportation_mode.dart';
import 'package:access_plate/domain/value_objects/user_language.dart';
import 'package:access_plate/presentation/copy/app_copy.dart';

void main() {
  test('spanish copy localizes recommendation-summary labels', () {
    const copy = AppCopy(UserLanguage.spanish);

    expect(copy.mealTimingLabel(MealType.lunch), 'Almuerzo');
    expect(copy.dietaryStyleLabel(DietaryStyle.vegetarian), 'Vegetariano');
    expect(
      copy.prepEnvironmentLabel(PrepEnvironment.microwave),
      'Solo microondas',
    );
    expect(
      copy.transportationLabel(TransportationMode.limited),
      'Viaje muy limitado',
    );
  });
}
