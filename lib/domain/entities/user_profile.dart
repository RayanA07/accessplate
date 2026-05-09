import '../engine/scoring/composite_scorer.dart';
import 'user_constraints.dart';

enum OnboardingStage {
  splash,
  safety,
  feasibility,
  preference,
  targets;

  static OnboardingStage fromName(String? name) {
    return values.firstWhere(
      (value) => value.name == name,
      orElse: () => OnboardingStage.splash,
    );
  }
}

enum AppThemePreference { system, light, dark }

class UserProfile {
  const UserProfile({
    required this.constraints,
    required this.scoringWeights,
    this.onboardingComplete = false,
    this.onboardingStage = OnboardingStage.splash,
    this.themePreference = AppThemePreference.system,
  });

  final UserConstraints constraints;
  final CompositeWeights scoringWeights;
  final bool onboardingComplete;
  final OnboardingStage onboardingStage;
  final AppThemePreference themePreference;

  factory UserProfile.defaults() {
    return UserProfile(
      constraints: UserConstraints.defaults(),
      scoringWeights: const CompositeWeights(),
    );
  }

  UserProfile copyWith({
    UserConstraints? constraints,
    CompositeWeights? scoringWeights,
    bool? onboardingComplete,
    OnboardingStage? onboardingStage,
    AppThemePreference? themePreference,
  }) {
    return UserProfile(
      constraints: constraints ?? this.constraints,
      scoringWeights: scoringWeights ?? this.scoringWeights,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      onboardingStage: onboardingStage ?? this.onboardingStage,
      themePreference: themePreference ?? this.themePreference,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'constraints': constraints.toJson(),
      'scoringWeights': scoringWeights.toJson(),
      'onboardingComplete': onboardingComplete,
      'onboardingStage': onboardingStage.name,
      'themePreference': themePreference.name,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      constraints: UserConstraints.fromJson(
        Map<String, dynamic>.from(json['constraints'] as Map? ?? const {}),
      ),
      scoringWeights: CompositeWeights.fromJson(
        Map<String, dynamic>.from(
          json['scoringWeights'] as Map? ?? const {},
        ),
      ),
      onboardingComplete: json['onboardingComplete'] as bool? ?? false,
      onboardingStage: OnboardingStage.fromName(
        json['onboardingStage'] as String?,
      ),
      themePreference: AppThemePreference.values.firstWhere(
        (value) => value.name == json['themePreference'],
        orElse: () => AppThemePreference.system,
      ),
    );
  }
}
