import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../widgets/onboarding_ui.dart';
import '../../widgets/section_card.dart';

class OnboardingSplashStep extends StatelessWidget {
  const OnboardingSplashStep({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingStepLayout(
      title:
          'Choose food with the\nsame clarity you expect\nfrom a polished health app.',
      subtitle:
          'AccessPlate scores each option through safety, feasibility, preferences, and nutrition so the shortlist stays understandable.',
      topSpacing: 26,
      children: [
        _FeatureGrid(),
        SizedBox(height: 18),
        SectionCard(
          tintColor: NihPalette.primaryAltLight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OnboardingMetaLabel('What stays local'),
              SizedBox(height: 10),
              Text(
                'Your profile stays on-device, and this prototype currently ranks from a bundled offline food set backed by the local cache.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.34,
                  color: Color(0xFF5E5E64),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _FeatureCard(
          title: 'Constraint-aware',
          detail:
              'Budget, prep setup, allergens, religion, and context shape every recommendation directly.',
          icon: Icons.tune_rounded,
          color: NihPalette.primary,
        ),
        SizedBox(height: 14),
        _FeatureCard(
          title: 'Explainable',
          detail:
              'Each recommendation carries reasons, tradeoffs, and comparable alternatives.',
          icon: Icons.insights_rounded,
          color: NihPalette.secondary,
        ),
        SizedBox(height: 14),
        _FeatureCard(
          title: 'Cache-first',
          detail:
              'The architecture is already prepared for online refresh later without changing the experience.',
          icon: Icons.cloud_done_rounded,
          color: NihPalette.success,
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.detail,
    required this.icon,
    required this.color,
  });

  final String title;
  final String detail;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      tintColor: color.withValues(alpha: 0.14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(detail, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
