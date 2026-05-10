import 'package:access_plate/domain/entities/user_constraints.dart';
import 'package:access_plate/domain/entities/user_profile.dart';
import 'package:access_plate/domain/value_objects/availability_context.dart';
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
      equals({
        AvailabilityContext.grocery,
        AvailabilityContext.convenience,
      }),
    );
  });
}
