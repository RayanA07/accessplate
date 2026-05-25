import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../domain/entities/user_profile.dart';
import '../../copy/app_copy.dart';
import '../../providers/profile_controller.dart';
import '../../widgets/onboarding_ui.dart';
import '../../widgets/section_card.dart';

class OnboardingSplashStep extends ConsumerWidget {
  const OnboardingSplashStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider).valueOrNull;
    final copy = AppCopy(
      profile?.constraints.access.language ??
          UserProfile.defaults().constraints.access.language,
    );

    return OnboardingStepLayout(
      title: copy.splashTitle,
      subtitle: copy.splashSubtitle,
      topSpacing: 26,
      children: [
        _FeatureGrid(copy: copy),
        const SizedBox(height: 18),
        SectionCard(
          tintColor: NihPalette.primaryAltLight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OnboardingMetaLabel(copy.splashLocalDataTitle),
              const SizedBox(height: 10),
              Text(
                copy.splashLocalDataDetail,
                style: const TextStyle(
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
  const _FeatureGrid({required this.copy});

  final AppCopy copy;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FeatureCard(
          title: copy.splashAccessTitle,
          detail: copy.splashAccessDetail,
          icon: Icons.route_rounded,
          color: NihPalette.primary,
        ),
        const SizedBox(height: 14),
        _FeatureCard(
          title: copy.splashExplainableTitle,
          detail: copy.splashExplainableDetail,
          icon: Icons.insights_rounded,
          color: NihPalette.secondary,
        ),
        const SizedBox(height: 14),
        _FeatureCard(
          title: copy.splashLocalFirstTitle,
          detail: copy.splashLocalFirstDetail,
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
