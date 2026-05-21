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
          'Choose the safest,\ncheapest meal you can\nactually reach today.',
      subtitle:
          'AccessPlate ranks food through safety, budget, prep setup, travel reality, pantry overlap, and nutrition so the shortlist stays practical.',
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
                'Your profile stays on-device, and this version already combines offline foods, low-resource access tags, and optional ZIP-based grocery matching.',
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
          title: 'Real-world access',
          detail:
              'Budget, pantry items, travel limits, and low-resource food sources shape every recommendation directly.',
          icon: Icons.route_rounded,
          color: NihPalette.primary,
        ),
        SizedBox(height: 14),
        _FeatureCard(
          title: 'Explainable',
          detail:
              'Each recommendation explains why it fits today and what tradeoffs still matter.',
          icon: Icons.insights_rounded,
          color: NihPalette.secondary,
        ),
        SizedBox(height: 14),
        _FeatureCard(
          title: 'Local-first',
          detail:
              'The app still works from saved foods when bandwidth is limited and keeps sensitive profile data local.',
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
