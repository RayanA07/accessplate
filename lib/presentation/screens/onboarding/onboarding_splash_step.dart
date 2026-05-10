import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../widgets/section_card.dart';

class OnboardingSplashStep extends StatelessWidget {
  const OnboardingSplashStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose food with the same clarity you expect from a polished health app.',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Text(
          'AccessPlate scores each option through safety, feasibility, preferences, and nutrition so the shortlist stays understandable.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        const _FeatureGrid(),
        const SizedBox(height: 18),
        SectionCard(
          tintColor: NihPalette.primaryAltLight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What stays local',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Your profile stays on-device, and this prototype currently ranks from a bundled offline food set backed by the local cache.',
                style: Theme.of(context).textTheme.bodyLarge,
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
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: const [
        SizedBox(
          width: 250,
          child: _FeatureCard(
            title: 'Constraint-aware',
            detail:
                'Budget, prep setup, allergens, religion, and context shape every recommendation directly.',
            icon: Icons.tune_rounded,
            color: NihPalette.primary,
          ),
        ),
        SizedBox(
          width: 250,
          child: _FeatureCard(
            title: 'Explainable',
            detail:
                'Each recommendation carries reasons, tradeoffs, and comparable alternatives.',
            icon: Icons.insights_rounded,
            color: NihPalette.secondary,
          ),
        ),
        SizedBox(
          width: 250,
          child: _FeatureCard(
            title: 'Cache-first',
            detail:
                'The architecture is already prepared for online refresh later without changing the experience.',
            icon: Icons.cloud_done_rounded,
            color: NihPalette.success,
          ),
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
