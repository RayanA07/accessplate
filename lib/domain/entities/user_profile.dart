import '../engine/scoring/composite_scorer.dart';
import 'local_login.dart';
import 'user_constraints.dart';

enum OnboardingStage {
  splash,
  name,
  age,
  height,
  weight,
  profile,
  budget,
  environment,
  availability,
  access,
  dietaryStyle,
  mealTiming,
  pantry,
  allergens,
  religion,
  medical,
  targets;

  static OnboardingStage fromName(String? name) {
    switch (name) {
      case 'splash':
        return OnboardingStage.splash;
      case 'name':
        return OnboardingStage.name;
      case 'age':
        return OnboardingStage.age;
      case 'height':
        return OnboardingStage.age;
      case 'weight':
        return OnboardingStage.age;
      case 'profile':
        return OnboardingStage.profile;
      case 'allergens':
        return OnboardingStage.dietaryStyle;
      case 'religion':
        return OnboardingStage.dietaryStyle;
      case 'medical':
        return OnboardingStage.medical;
      case 'budget':
        return OnboardingStage.budget;
      case 'environment':
        return OnboardingStage.environment;
      case 'availability':
        return OnboardingStage.availability;
      case 'access':
        return OnboardingStage.access;
      case 'dietaryStyle':
        return OnboardingStage.dietaryStyle;
      case 'mealTiming':
        return OnboardingStage.dietaryStyle;
      case 'cuisine':
      case 'dislikes':
        return OnboardingStage.pantry;
      case 'pantry':
        return OnboardingStage.pantry;
      case 'targets':
        return OnboardingStage.targets;
      // Legacy stage names from the earlier bundled-screen flow.
      case 'safety':
        return OnboardingStage.dietaryStyle;
      case 'feasibility':
        return OnboardingStage.budget;
      case 'preference':
        return OnboardingStage.dietaryStyle;
      default:
        return OnboardingStage.splash;
    }
  }
}

enum AppThemePreference { system, light, dark }

class UserProfile {
  const UserProfile({
    required this.constraints,
    required this.scoringWeights,
    this.localLogin = const LocalLogin(),
    this.onboardingComplete = false,
    this.onboardingStage = OnboardingStage.splash,
    this.themePreference = AppThemePreference.system,
  });

  final UserConstraints constraints;
  final CompositeWeights scoringWeights;
  final LocalLogin localLogin;
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
    LocalLogin? localLogin,
    bool? onboardingComplete,
    OnboardingStage? onboardingStage,
    AppThemePreference? themePreference,
  }) {
    return UserProfile(
      constraints: constraints ?? this.constraints,
      scoringWeights: scoringWeights ?? this.scoringWeights,
      localLogin: localLogin ?? this.localLogin,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      onboardingStage: onboardingStage ?? this.onboardingStage,
      themePreference: themePreference ?? this.themePreference,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'constraints': constraints.toJson(),
      'scoringWeights': scoringWeights.toJson(),
      'localLogin': localLogin.toJson(),
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
        Map<String, dynamic>.from(json['scoringWeights'] as Map? ?? const {}),
      ),
      localLogin: LocalLogin.fromJson(
        Map<String, dynamic>.from(json['localLogin'] as Map? ?? const {}),
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
