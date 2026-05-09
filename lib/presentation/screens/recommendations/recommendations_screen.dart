import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/recommendation.dart';
import '../../../domain/entities/user_profile.dart';
import '../../providers/profile_controller.dart';
import '../../providers/recommendations_provider.dart';
import '../../widgets/quick_adjust_sheet.dart';
import '../../widgets/recommendation_card.dart';
import '../../widgets/section_card.dart';
import '../explain/explain_detail_screen.dart';
import '../profile/settings_screen.dart';

class RecommendationsScreen extends ConsumerWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final recommendationsAsync = ref.watch(recommendationsProvider);
    final result = recommendationsAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AccessPlate'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: _QuickStrip(profile: profile),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF0F6FA), Color(0xFFE6EEF5), Color(0xFFD9E8F2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              _SummaryHero(profile: profile, result: result),
              if (recommendationsAsync.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                ),
              const SizedBox(height: 12),
              if (result == null && recommendationsAsync.isLoading)
                const SectionCard(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Scoring foods...'),
                  ),
                )
              else if (result != null && result.isEmpty)
                _EmptyState(result: result)
              else if (result != null)
                ...result.recommendations.map(
                  (recommendation) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: RecommendationCard(
                      recommendation: recommendation,
                      onExplain: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ExplainDetailScreen(
                              recommendation: recommendation,
                              allRecommendations: result.recommendations,
                            ),
                          ),
                        );
                      },
                      onSwap: () => _showQuickAdjustSheet(context),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickAdjustSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const QuickAdjustSheet(),
    );
  }
}

class _SummaryHero extends StatelessWidget {
  const _SummaryHero({
    required this.profile,
    required this.result,
  });

  final UserProfile profile;
  final RecommendationResult? result;

  @override
  Widget build(BuildContext context) {
    final feasibility = profile.constraints.feasibility;
    final preference = profile.constraints.preference;
    final summaryText = result == null
        ? 'Preparing recommendations...'
        : result!.isEmpty
            ? 'No safe and feasible foods matched the current constraints.'
            : 'Top ${result!.recommendations.length} foods from ${result!.candidatePoolSize} candidates in ${result!.elapsedMs} ms.';

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current recommendation context',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text('Budget \$${feasibility.maxCostPerMeal.toStringAsFixed(0)}')),
              Chip(label: Text(feasibility.environment.label)),
              Chip(label: Text(preference.mealType.label)),
              Chip(label: Text('${feasibility.availability.length} contexts')),
            ],
          ),
          const SizedBox(height: 16),
          Text(summaryText),
          if (result?.preferenceRelaxed == true) ...[
            const SizedBox(height: 8),
            Text(
              'Preference filters were relaxed to preserve enough safe, feasible options.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.result});

  final RecommendationResult result;

  @override
  Widget build(BuildContext context) {
    final diagnostic = result.diagnostic;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'We could not find a safe and feasible food right now.',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          if (diagnostic != null) ...[
            Text('Biggest blocker: ${diagnostic.mostRestrictive.label}'),
            const SizedBox(height: 8),
            Text(diagnostic.suggestion),
          ],
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const QuickAdjustSheet(),
              );
            },
            child: const Text('Adjust constraints'),
          ),
        ],
      ),
    );
  }
}

class _QuickStrip extends StatelessWidget {
  const _QuickStrip({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final feasibility = profile.constraints.feasibility;
    final preference = profile.constraints.preference;
    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text('Budget \$${feasibility.maxCostPerMeal.toStringAsFixed(0)}'),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(feasibility.environment.label)),
          const SizedBox(width: 12),
          Expanded(child: Text(preference.mealType.label)),
        ],
      ),
    );
  }
}
