import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_profile.dart';
import '../../providers/profile_controller.dart';

class OnboardingSplashStep extends ConsumerWidget {
  const OnboardingSplashStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose safe, feasible food in seconds.',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          'AccessPlate ranks foods with a four-layer pipeline: safety first, then feasibility, then preferences, then nutrition scoring.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        const _IntroBullet(
          title: 'Always offline',
          detail: 'No accounts, cloud calls, or subscription costs.',
        ),
        const _IntroBullet(
          title: 'Constraint-aware',
          detail: 'Budget, prep setup, allergens, religion, and context are all modeled directly.',
        ),
        const _IntroBullet(
          title: 'Explainable',
          detail: 'Every recommendation includes reasons and tradeoffs.',
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () {
            ref.read(profileControllerProvider.notifier).setStage(
                  OnboardingStage.safety,
                );
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Get started'),
          ),
        ),
      ],
    );
  }
}

class _IntroBullet extends StatelessWidget {
  const _IntroBullet({
    required this.title,
    required this.detail,
  });

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: '$title. ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: detail),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
