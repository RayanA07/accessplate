import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../domain/entities/local_access.dart';
import '../../../domain/entities/recommendation.dart';
import '../../../domain/entities/user_constraints.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/value_objects/availability_context.dart';
import '../../../domain/value_objects/benefit_program.dart';
import '../../../domain/value_objects/dietary_style.dart';
import '../../copy/app_copy.dart';
import '../../providers/app_bootstrap.dart' show localAccessCatalogProvider;
import '../../providers/profile_controller.dart';
import '../../providers/recommendations_provider.dart';
import '../../widgets/meal_basket_card.dart';
import '../../widgets/quick_adjust_sheet.dart';
import '../../widgets/recommendation_card.dart';
import '../../widgets/section_card.dart';
import '../../widgets/today_plan_card.dart';
import '../explain/explain_detail_screen.dart';
import '../profile/settings_screen.dart';

class RecommendationsScreen extends ConsumerWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile =
        ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final copy = AppCopy(profile.constraints.access.language);
    final localAccessCatalog = ref.watch(localAccessCatalogProvider).valueOrNull;
    final accessResolution = localAccessCatalog?.resolve(
      profile.constraints.access.postalCode,
    );
    final recommendationsAsync = ref.watch(recommendationsProvider);
    final result = recommendationsAsync.valueOrNull;
    final error = recommendationsAsync.hasError
        ? recommendationsAsync.error
        : null;

    return Scaffold(
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: _QuickStrip(
            profile: profile,
            result: result,
            onAdjust: () => _showQuickAdjustSheet(context),
          ),
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: NihPalette.lightContentBackground,
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
            children: [
              _TopBar(
                copy: copy,
                onSettings: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
              const SizedBox(height: 18),
              _SummaryHero(
                profile: profile,
                result: result,
                accessResolution: accessResolution,
              ),
              const SizedBox(height: 14),
              if (result?.todayPlan != null) ...[
                Text(
                  copy.todayPlanTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  copy.todayPlanSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                TodayPlanCard(plan: result!.todayPlan!),
                const SizedBox(height: 14),
              ],
              _PinnedOverview(profile: profile, result: result),
              if (result?.baskets.isNotEmpty == true) ...[
                const SizedBox(height: 20),
                Text(
                  copy.basketTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  copy.basketSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                for (final basket in result!.baskets) ...[
                  MealBasketCard(plan: basket),
                  if (basket != result.baskets.last) const SizedBox(height: 12),
                ],
              ],
              const SizedBox(height: 24),
              Text(
                copy.recommendationsTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                copy.recommendationsSubtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (recommendationsAsync.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: LinearProgressIndicator(),
                ),
              const SizedBox(height: 12),
              if (result == null && recommendationsAsync.isLoading)
                const SectionCard(
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: Text('Refreshing your recommendations...'),
                  ),
                )
              else if (error != null)
                _RecommendationsErrorState(
                  error: error,
                  onRetry: () => ref.invalidate(recommendationsProvider),
                  onAdjust: () => _showQuickAdjustSheet(context),
                )
              else if (result != null && result.isEmpty)
                _EmptyState(
                  result: result,
                  onAdjust: () => _showQuickAdjustSheet(context),
                )
              else if (result != null)
                ...result.recommendations.map(
                  (recommendation) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
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

class _TopBar extends StatelessWidget {
  const _TopBar({required this.copy, required this.onSettings});

  final AppCopy copy;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                copy.summaryTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                copy.summarySubtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surface.withValues(alpha: 0.72),
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: IconButton(
            tooltip: 'Settings',
            onPressed: onSettings,
            icon: const Icon(Icons.tune_rounded),
          ),
        ),
      ],
    );
  }
}

class _RecommendationsErrorState extends StatelessWidget {
  const _RecommendationsErrorState({
    required this.error,
    required this.onRetry,
    required this.onAdjust,
  });

  final Object error;
  final VoidCallback onRetry;
  final VoidCallback onAdjust;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      tintColor: NihPalette.secondaryLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'We hit a loading issue.',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            'The recommendation engine did not return a list for this profile. You can retry now or widen one of the current filters.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 10),
          Text(
            'Debug detail: $error',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
              OutlinedButton(
                onPressed: onAdjust,
                child: const Text('Adjust filters'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryHero extends StatelessWidget {
  const _SummaryHero({
    required this.profile,
    required this.result,
    required this.accessResolution,
  });

  final UserProfile profile;
  final RecommendationResult? result;
  final LocalAccessProfileResolution? accessResolution;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final feasibility = profile.constraints.feasibility;
    final preference = profile.constraints.preference;
    final access = profile.constraints.access;
    final groceryStore = feasibility.groceryStore;
    final visibleCount = result?.recommendations.length ?? 0;
    final summaryText = result == null
        ? 'Preparing a fresh set of recommendations.'
        : result!.isEmpty
        ? 'Nothing currently matches every active rule.'
        : 'Showing $visibleCount foods from ${result!.candidatePoolSize} matching candidates.';

    return SectionCard(
      tintColor: NihPalette.secondaryLight,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pinned for this meal',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: NihPalette.secondaryDark,
                        letterSpacing: 0.25,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _heroTitle(preference),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(summaryText, style: theme.textTheme.bodyLarge),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _HeroStat(
                label: 'Pool',
                value: result == null ? '--' : '${result!.candidatePoolSize}',
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                label: Text(
                  'Budget \$${feasibility.maxCostPerMeal.toStringAsFixed(0)}',
                ),
              ),
              Chip(label: Text(feasibility.environment.label)),
              Chip(label: Text(preference.mealType.label)),
              Chip(label: Text(access.transportation.label)),
              if (groceryStore != null) Chip(label: Text(groceryStore.name)),
              if (preference.dietaryStyle != DietaryStyle.unrestricted)
                Chip(label: Text(preference.dietaryStyle.label)),
              if (access.postalCode.isNotEmpty)
                Chip(label: Text('ZIP ${access.postalCode}')),
              if (access.emergencyMode)
                const Chip(label: Text('Emergency mode')),
              for (final benefit in access.benefitPrograms)
                Chip(label: Text(benefit.label)),
            ],
          ),
          if (accessResolution != null && access.postalCode.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _accessSnapshotLine(accessResolution!),
              style: theme.textTheme.bodyMedium,
            ),
          ],
          if (result?.preferenceRelaxed == true) ...[
            const SizedBox(height: 12),
            Text(
              'Meal timing was broadened to keep enough matching options on screen.',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  String _heroTitle(PreferenceConstraints preference) {
    if (preference.dietaryStyle == DietaryStyle.unrestricted) {
      return '${preference.mealType.label} suggestions that respect your setup';
    }
    return '${preference.dietaryStyle.label} ${preference.mealType.label.toLowerCase()} suggestions';
  }

  String _accessSnapshotLine(LocalAccessProfileResolution resolution) {
    final profile = resolution.profile;
    final pantry = profile.sourceFor(AvailabilityContext.foodPantry);
    final grocery = profile.sourceFor(AvailabilityContext.grocery);
    final intro = switch (resolution.matchType) {
      LocalAccessMatchType.exact => 'ZIP snapshot',
      LocalAccessMatchType.prefix => 'ZIP-area snapshot',
      LocalAccessMatchType.fallback => 'Fallback snapshot',
    };
    if (pantry != null &&
        grocery != null &&
        pantry.typicalTravelMinutes < grocery.typicalTravelMinutes) {
      return '$intro: ${profile.communityLabel} favors pantry, convenience, and discount sources before a full grocery trip.';
    }
    return '$intro: ${profile.communityLabel} access is built into today\'s ranking.';
  }
}

class _PinnedOverview extends StatelessWidget {
  const _PinnedOverview({required this.profile, required this.result});

  final UserProfile profile;
  final RecommendationResult? result;

  @override
  Widget build(BuildContext context) {
    final feasibility = profile.constraints.feasibility;
    final preference = profile.constraints.preference;
    final access = profile.constraints.access;
    final pantryCount = profile.constraints.pantry.itemsOnHand.length;
    final cards = <Widget>[
      _MiniInsightCard(
        color: NihPalette.primary,
        title: 'Preparation',
        value: feasibility.environment.label,
        detail: '${feasibility.availability.length} shopping contexts',
        icon: Icons.microwave_rounded,
      ),
      _MiniInsightCard(
        color: NihPalette.secondary,
        title: 'Meal',
        value: preference.mealType.label,
        detail: preference.dietaryStyle == DietaryStyle.unrestricted
            ? 'No extra diet filter'
            : preference.dietaryStyle.label,
        icon: Icons.restaurant_menu_rounded,
      ),
      _MiniInsightCard(
        color: NihPalette.success,
        title: 'Access',
        value: access.emergencyMode ? 'Emergency on' : access.transportation.label,
        detail: _accessDetail(
          access: access,
          pantryCount: pantryCount,
          shownCount: result?.recommendations.length ?? 0,
        ),
        icon: Icons.route_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 420) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < cards.length; index++) ...[
                cards[index],
                if (index < cards.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }

        return SizedBox(
          height: 188,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cards.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, index) =>
                SizedBox(width: 224, child: cards[index]),
          ),
        );
      },
    );
  }

  String _accessDetail({
    required AccessConstraints access,
    required int pantryCount,
    required int shownCount,
  }) {
    final detailParts = <String>[];
    if (pantryCount > 0) {
      detailParts.add('$pantryCount pantry items');
    }
    if (access.benefitPrograms.contains(BenefitProgram.snap)) {
      detailParts.add('SNAP aware');
    }
    if (access.benefitPrograms.contains(BenefitProgram.wic)) {
      detailParts.add('WIC aware');
    }
    if (detailParts.isEmpty) {
      detailParts.add('$shownCount options shown now');
    }
    return detailParts.join(' | ');
  }
}

class _MiniInsightCard extends StatelessWidget {
  const _MiniInsightCard({
    required this.color,
    required this.title,
    required this.value,
    required this.detail,
    required this.icon,
  });

  final Color color;
  final String title;
  final String value;
  final String detail;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      tintColor: color.withValues(alpha: 0.16),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            style: theme.textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.result, required this.onAdjust});

  final RecommendationResult result;
  final VoidCallback onAdjust;

  @override
  Widget build(BuildContext context) {
    final diagnostic = result.diagnostic;
    return SectionCard(
      tintColor: NihPalette.secondaryLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nothing is matching cleanly right now.',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            diagnostic == null
                ? 'Try widening the current setup to surface more candidates.'
                : diagnostic.suggestion,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (diagnostic != null) ...[
            const SizedBox(height: 12),
            Chip(
              label: Text(
                'Biggest blocker: ${diagnostic.mostRestrictive.label}',
              ),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onAdjust,
            icon: const Icon(Icons.tune_rounded),
            label: const Text('Adjust constraints'),
          ),
        ],
      ),
    );
  }
}

class _QuickStrip extends StatelessWidget {
  const _QuickStrip({
    required this.profile,
    required this.result,
    required this.onAdjust,
  });

  final UserProfile profile;
  final RecommendationResult? result;
  final VoidCallback onAdjust;

  @override
  Widget build(BuildContext context) {
    final feasibility = profile.constraints.feasibility;
    final preference = profile.constraints.preference;

    return SectionCard(
      borderRadius: 28,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 420) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _DockItem(
                        label: 'Budget',
                        value:
                            '\$${feasibility.maxCostPerMeal.toStringAsFixed(0)}',
                        centered: true,
                      ),
                    ),
                    Expanded(
                      child: _DockItem(
                        label: 'Meal',
                        value: preference.mealType.label,
                        centered: true,
                      ),
                    ),
                    Expanded(
                      child: _DockItem(
                        label: 'Shown',
                        value: result == null
                            ? '--'
                            : '${result!.recommendations.length}',
                        centered: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: onAdjust,
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: const Text('Adjust'),
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: _DockItem(
                  label: 'Budget',
                  value: '\$${feasibility.maxCostPerMeal.toStringAsFixed(0)}',
                ),
              ),
              Expanded(
                child: _DockItem(
                  label: 'Meal',
                  value: preference.mealType.label,
                ),
              ),
              Expanded(
                child: _DockItem(
                  label: 'Shown',
                  value: result == null
                      ? '--'
                      : '${result!.recommendations.length}',
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.tonalIcon(
                onPressed: onAdjust,
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('Adjust'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.label,
    required this.value,
    this.centered = false,
  });

  final String label;
  final String value;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
