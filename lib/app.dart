import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final themePreference = profileAsync.valueOrNull?.themePreference ??
        AppThemePreference.system;

    return MaterialApp(
      title: 'AccessPlate',
      debugShowCheckedModeBanner: false,
      themeMode: switch (themePreference) {
        AppThemePreference.light => ThemeMode.light,
        AppThemePreference.dark => ThemeMode.dark,
        AppThemePreference.system => ThemeMode.system,
      },
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: profileAsync.when(
        data: (profile) => profile.onboardingComplete
            ? const RecommendationsScreen()
            : const OnboardingFlowScreen(),
        loading: () => const _BootstrapScreen(),
        error: (error, stackTrace) => _ErrorScreen(error: error),
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    const navy = Color(0xFF17324D);
    const sky = Color(0xFF5E94B8);
    const gold = Color(0xFFF2C14E);
    final scheme = ColorScheme.fromSeed(
      seedColor: sky,
      brightness: brightness,
      primary: isDark ? const Color(0xFF9CC7E4) : navy,
      secondary: gold,
      surface: isDark ? const Color(0xFF102032) : const Color(0xFFF7FAFC),
    );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF08121D) : const Color(0xFFF0F6FA),
      textTheme: ThemeData(brightness: brightness).textTheme.apply(
            bodyColor: scheme.onSurface,
            displayColor: scheme.onSurface,
            fontFamily: 'Georgia',
          ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
        selectedColor: scheme.primary.withValues(alpha: 0.15),
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        thumbColor: scheme.secondary,
        inactiveTrackColor: scheme.primary.withValues(alpha: 0.2),
      ),
      cardTheme: CardThemeData(
        color: isDark ? const Color(0xFF10273C) : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF132A3D) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
    );
  }
}

class _BootstrapScreen extends StatelessWidget {
  const _BootstrapScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF17324D), Color(0xFF5E94B8), Color(0xFFEAF2F7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: const SectionCard(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AccessPlate',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Preparing the offline food database and your profile...',
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(height: 20),
                    LinearProgressIndicator(),
                  ],
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
