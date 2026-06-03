import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_palette.dart';
import 'core/theme/app_theme.dart';
import 'domain/entities/user_profile.dart';
import 'presentation/providers/profile_controller.dart';
import 'presentation/screens/onboarding/onboarding_flow_screen.dart';
import 'presentation/screens/recommendations/recommendations_screen.dart';
import 'presentation/widgets/section_card.dart';

class AccessPlateApp extends ConsumerWidget {
  const AccessPlateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileControllerProvider);
    final themePreference =
        profileAsync.valueOrNull?.themePreference ?? AppThemePreference.system;

    return MaterialApp(
      title: 'AccessPlate',
      debugShowCheckedModeBanner: false,
      themeMode: switch (themePreference) {
        AppThemePreference.light => ThemeMode.light,
        AppThemePreference.dark => ThemeMode.dark,
        AppThemePreference.system => ThemeMode.system,
      },
      theme: AccessPlateTheme.light(),
      darkTheme: AccessPlateTheme.dark(),
      home: profileAsync.when(
        data: (profile) {
          return profile.onboardingComplete
              ? const RecommendationsScreen()
              : const OnboardingFlowScreen();
        },
        loading: () => const _BootstrapScreen(),
        error: (error, stackTrace) => _ErrorScreen(error: error),
      ),
    );
  }
}

class _BootstrapScreen extends StatelessWidget {
  const _BootstrapScreen();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isDark
              ? NihPalette.darkBackground
              : NihPalette.lightBackground,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SectionCard(
                tintColor: NihPalette.secondaryLight,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AccessPlate',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: NihPalette.primaryDarkest,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Preparing your profile and cached foods...',
                        style: TextStyle(color: NihPalette.grayDark),
                      ),
                      SizedBox(height: 20),
                      LinearProgressIndicator(minHeight: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'AccessPlate could not start.\n$error',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
