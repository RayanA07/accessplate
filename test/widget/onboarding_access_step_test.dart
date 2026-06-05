import 'package:access_plate/core/theme/app_theme.dart';
import 'package:access_plate/domain/entities/user_profile.dart';
import 'package:access_plate/domain/value_objects/benefit_program.dart';
import 'package:access_plate/presentation/providers/nearby_store_providers.dart';
import 'package:access_plate/presentation/providers/profile_controller.dart';
import 'package:access_plate/presentation/screens/onboarding/onboarding_access_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('daily access step shows benefit cards and toggles their state', (
    tester,
  ) async {
    final controller = _TestProfileController(
      UserProfile.defaults().copyWith(onboardingStage: OnboardingStage.access),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileControllerProvider.overrideWith(() => controller),
          shoppingLocationStateProvider.overrideWith(
            (ref) => const ShoppingLocationState(apiConfigured: true),
          ),
        ],
        child: MaterialApp(
          theme: AccessPlateTheme.light(),
          home: const Scaffold(
            body: SingleChildScrollView(child: OnboardingAccessStep()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SNAP / EBT'), findsOneWidget);
    expect(
      find.text("We'll only show foods purchasable with SNAP benefits."),
      findsOneWidget,
    );
    expect(find.text('WIC'), findsOneWidget);
    expect(
      find.text("We'll filter to WIC-approved foods only."),
      findsOneWidget,
    );
    expect(find.text('Emergency mode'), findsOneWidget);
    expect(
      find.text(
        'Extreme budget and travel constraints. Only the most accessible options shown.',
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.credit_card_rounded), findsOneWidget);
    expect(find.byIcon(Icons.child_care_rounded), findsOneWidget);
    expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);

    await tester.ensureVisible(find.text('SNAP / EBT'));
    await tester.tap(find.text('SNAP / EBT'));
    await tester.pumpAndSettle();
    expect(
      controller.current.constraints.access.benefitPrograms,
      contains(BenefitProgram.snap),
    );

    await tester.ensureVisible(find.text('WIC'));
    await tester.tap(find.text('WIC'));
    await tester.pumpAndSettle();
    expect(
      controller.current.constraints.access.benefitPrograms,
      contains(BenefitProgram.wic),
    );

    await tester.ensureVisible(find.text('Emergency mode'));
    await tester.tap(find.text('Emergency mode'));
    await tester.pumpAndSettle();
    expect(controller.current.constraints.access.emergencyMode, isTrue);

    await tester.ensureVisible(find.text('SNAP / EBT'));
    await tester.tap(find.text('SNAP / EBT'));
    await tester.pumpAndSettle();
    expect(
      controller.current.constraints.access.benefitPrograms,
      isNot(contains(BenefitProgram.snap)),
    );
  });
}

class _TestProfileController extends ProfileController {
  _TestProfileController(this._profile);

  UserProfile _profile;

  @override
  Future<UserProfile> build() async => _profile;

  @override
  Future<void> updateBenefitPrograms(
    Set<BenefitProgram> benefitPrograms,
  ) async {
    _profile = _profile.copyWith(
      constraints: _profile.constraints.copyWith(
        access: _profile.constraints.access.copyWith(
          benefitPrograms: benefitPrograms,
        ),
      ),
    );
    state = AsyncData(_profile);
  }

  @override
  Future<void> updateEmergencyMode(bool emergencyMode) async {
    _profile = _profile.copyWith(
      constraints: _profile.constraints.copyWith(
        access: _profile.constraints.access.copyWith(
          emergencyMode: emergencyMode,
        ),
      ),
    );
    state = AsyncData(_profile);
  }
}
