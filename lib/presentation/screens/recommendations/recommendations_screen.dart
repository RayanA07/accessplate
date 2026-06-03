// ignore_for_file: unused_element

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
import '../../providers/profile_controller.dart';
import '../../providers/recommendations_provider.dart';
import '../../widgets/quick_adjust_sheet.dart';
import '../../widgets/recommendation_card.dart';
import '../../widgets/section_card.dart';
import '../explain/explain_detail_screen.dart';
import '../profile/settings_screen.dart';

class RecommendationsScreen extends ConsumerStatefulWidget {
  const RecommendationsScreen({
    super.key,
    this.embedded = false,
    this.onOpenProfile,
  });

  final bool embedded;
  final VoidCallback? onOpenProfile;

  @override
  ConsumerState<RecommendationsScreen> createState() =>
      _RecommendationsScreenState();
}

class _RecommendationsScreenState extends ConsumerState<RecommendationsScreen> {
  bool _showAllRecommendations = false;

  @override
  Widget build(BuildContext context) {
    final profile =
        ref.watch(profileControllerProvider).valueOrNull ??
        UserProfile.defaults();
    final copy = AppCopy(profile.constraints.access.language);
    final recommendationsAsync = ref.watch(recommendationsProvider);
    final result = recommendationsAsync.valueOrNull;
    final error = recommendationsAsync.hasError
        ? recommendationsAsync.error
        : null;
    final shownRecommendations = result == null
        ? const <ScoredFood>[]
        : _showAllRecommendations || result.recommendations.length <= 3
        ? result.recommendations
        : result.recommendations.take(3).toList();

    final content = DecoratedBox(
      decoration: const BoxDecoration(
        gradient: NihPalette.lightContentBackground,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
          children: [
            _TopBar(
              name: profile.localLogin.displayName,
              onSettings: () {
                final openProfile = widget.onOpenProfile;
                if (openProfile != null) {
                  openProfile();
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            const SizedBox(height: 18),
            Text(
              copy.choose('Suggested Meals', 'Comidas sugeridas'),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              copy.choose(
                'High-fit meals ranked from your existing decision system.',
                'Comidas con mejor ajuste segun tu sistema actual de decisiones.',
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (recommendationsAsync.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: LinearProgressIndicator(),
              ),
            const SizedBox(height: 12),
            if (result == null && recommendationsAsync.isLoading)
              SectionCard(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    copy.choose(
                      'Refreshing your recommendations...',
                      'Actualizando tus recomendaciones...',
                    ),
                  ),
                ),
              )
            else if (error != null)
              _RecommendationsErrorState(
                copy: copy,
                plainLanguage: profile.constraints.access.plainLanguage,
                error: error,
                onRetry: () => ref.invalidate(recommendationsProvider),
                onAdjust: () => _showQuickAdjustSheet(context),
              )
            else if (result != null && result.isEmpty)
              _EmptyState(
                copy: copy,
                plainLanguage: profile.constraints.access.plainLanguage,
                result: result,
                onAdjust: () => _showQuickAdjustSheet(context),
              )
            else if (result != null)
              ...shownRecommendations.map(
                (recommendation) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: RecommendationCard(
                    recommendation: recommendation,
                    language: profile.constraints.access.language,
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
                    onTrack: () async {
                      await ref
                          .read(profileControllerProvider.notifier)
                          .logRecommendation(recommendation);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              copy.choose(
                                'Added to daily tracking',
                                'Agregado al seguimiento diario',
                              ),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            if (result != null && result.recommendations.length > 3)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showAllRecommendations = !_showAllRecommendations;
                    });
                  },
                  icon: Icon(
                    _showAllRecommendations
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                  ),
                  label: Text(
                    _showAllRecommendations
                        ? copy.choose('Show fewer options', 'Mostrar menos')
                        : copy.choose(
                            'Show ${result.recommendations.length - 3} more options',
                            'Mostrar ${result.recommendations.length - 3} opciones mas',
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return widget.embedded ? content : Scaffold(body: content);
  }

  void _showQuickAdjustSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const QuickAdjustSheet(),
    );
  }
}

class _ExpandableSummarySection extends StatelessWidget {
  const _ExpandableSummarySection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle),
        ),
        children: [const SizedBox(height: 10), child],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.name, required this.onSettings});

  final String name;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFE7F4E7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.restaurant_menu_rounded,
            color: Color(0xFF219653),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AccessPlate',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                name.trim().isEmpty ? 'Healthy meal suggestions' : 'For $name',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEAEAF0)),
          ),
          child: IconButton(
            tooltip: 'Profile',
            onPressed: onSettings,
            icon: const Icon(Icons.person_outline_rounded),
          ),
        ),
      ],
    );
  }
}

class _RecommendationsErrorState extends StatelessWidget {
  const _RecommendationsErrorState({
    required this.copy,
    required this.plainLanguage,
    required this.error,
    required this.onRetry,
    required this.onAdjust,
  });

  final AppCopy copy;
  final bool plainLanguage;
  final Object error;
  final VoidCallback onRetry;
  final VoidCallback onAdjust;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      tintColor: NihPalette.secondaryLight,
      child: Semantics(
        container: true,
        label: copy.choose(
          'Recommendation loading problem',
          'Problema al cargar recomendaciones',
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              copy.choose(
                'We could not build a plan right now.',
                'No pudimos armar un plan en este momento.',
              ),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              plainLanguage
                  ? copy.choose(
                      'Try again now, or loosen one rule a little so more food options can show up.',
                      'Intenta otra vez ahora, o afloja un poco una regla para que aparezcan mas opciones.',
                    )
                  : copy.choose(
                      'The recommendation engine did not return a list for this profile. You can retry now or widen one of the current filters.',
                      'El motor no devolvio una lista para este perfil. Puedes intentar otra vez o abrir un poco alguno de los filtros.',
                    ),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 14),
            Text(
              copy.choose('Try this first', 'Prueba esto primero'),
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _BulletLine(
              text: copy.choose(
                'Retry once in case this was just a brief loading failure.',
                'Intenta otra vez una vez por si solo fue una falla breve.',
              ),
            ),
            _BulletLine(
              text: copy.choose(
                'If nothing changes, open Adjust and widen your hardest filter.',
                'Si nada cambia, abre Ajustar y afloja el filtro mas duro.',
              ),
            ),
            const SizedBox(height: 14),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: Text(copy.choose('Technical detail', 'Detalle tecnico')),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$error',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton(
                  onPressed: onRetry,
                  child: Text(copy.choose('Retry', 'Intentar otra vez')),
                ),
                OutlinedButton(
                  onPressed: onAdjust,
                  child: Text(copy.choose('Adjust filters', 'Ajustar filtros')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryHero extends StatelessWidget {
  const _SummaryHero({
    required this.profile,
    required this.result,
    required this.accessResolution,
    required this.copy,
    required this.plainLanguage,
  });

  final UserProfile profile;
  final RecommendationResult? result;
  final LocalAccessProfileResolution? accessResolution;
  final AppCopy copy;
  final bool plainLanguage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final feasibility = profile.constraints.feasibility;
    final preference = profile.constraints.preference;
    final access = profile.constraints.access;
    final groceryStore = feasibility.groceryStore;
    final visibleCount = result?.recommendations.length ?? 0;
    final summaryText = result == null
        ? copy.choose(
            'Preparing today\'s food access plan.',
            'Preparando el plan de acceso a comida de hoy.',
          )
        : result!.isEmpty
        ? copy.choose(
            'Nothing currently matches every active rule.',
            'Nada coincide con todas las reglas activas en este momento.',
          )
        : plainLanguage
        ? copy.choose(
            'Showing $visibleCount food choices that fit what you can reach today.',
            'Mostrando $visibleCount opciones de comida que si puedes alcanzar hoy.',
          )
        : copy.choose(
            'Showing $visibleCount foods from ${result!.candidatePoolSize} candidates after safety and real-world access filters.',
            'Mostrando $visibleCount alimentos de ${result!.candidatePoolSize} candidatos despues de filtros de seguridad y acceso real.',
          );

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
                      copy.choose(
                        'Best fit for today',
                        'Mejor ajuste para hoy',
                      ),
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
                label: copy.choose('Pool', 'Base'),
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
                  copy.choose(
                    'Budget \$${feasibility.maxCostPerMeal.toStringAsFixed(0)}',
                    'Presupuesto \$${feasibility.maxCostPerMeal.toStringAsFixed(0)}',
                  ),
                ),
              ),
              Chip(
                label: Text(copy.prepEnvironmentLabel(feasibility.environment)),
              ),
              Chip(label: Text(copy.mealTimingLabel(preference.mealType))),
              Chip(
                label: Text(copy.transportationLabel(access.transportation)),
              ),
              if (groceryStore != null) Chip(label: Text(groceryStore.name)),
              if (preference.dietaryStyle != DietaryStyle.unrestricted)
                Chip(
                  label: Text(copy.dietaryStyleLabel(preference.dietaryStyle)),
                ),
              if (access.postalCode.isNotEmpty)
                Chip(label: Text('ZIP ${access.postalCode}')),
              if (access.emergencyMode)
                Chip(
                  label: Text(
                    copy.choose('Emergency mode', 'Modo de emergencia'),
                  ),
                ),
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
              copy.choose(
                'Meal timing was broadened to keep enough matching options on screen.',
                'Se amplio el horario de comida para mantener suficientes opciones en pantalla.',
              ),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  String _heroTitle(PreferenceConstraints preference) {
    final mealLabel = copy.mealTimingLabel(preference.mealType);
    if (preference.dietaryStyle == DietaryStyle.unrestricted) {
      return copy.choose(
        '$mealLabel options you can realistically reach today',
        'Opciones de ${mealLabel.toLowerCase()} que puedes alcanzar hoy',
      );
    }
    final styleLabel = copy.dietaryStyleLabel(preference.dietaryStyle);
    return copy.choose(
      '$styleLabel options for ${mealLabel.toLowerCase()} you can realistically reach today',
      'Opciones para ${mealLabel.toLowerCase()} con estilo ${styleLabel.toLowerCase()} que puedes alcanzar hoy',
    );
  }

  String _accessSnapshotLine(LocalAccessProfileResolution resolution) {
    final profile = resolution.profile;
    final pantry = profile.sourceFor(AvailabilityContext.foodPantry);
    final grocery = profile.sourceFor(AvailabilityContext.grocery);
    final intro = switch (resolution.matchType) {
      LocalAccessMatchType.exact => copy.choose(
        'Higher-confidence bundled ZIP snapshot',
        'Panorama ZIP incluido de mayor confianza',
      ),
      LocalAccessMatchType.prefix => copy.choose(
        'Broader bundled ZIP-area estimate',
        'Estimacion incluida mas amplia por area ZIP',
      ),
      LocalAccessMatchType.fallback => copy.choose(
        'Lower-confidence bundled fallback estimate',
        'Estimacion incluida de respaldo con menor confianza',
      ),
    };
    if (pantry != null &&
        grocery != null &&
        pantry.typicalTravelMinutes < grocery.typicalTravelMinutes) {
      return copy.choose(
        '$intro: ${profile.communityLabel} favors pantry, convenience, and discount sources before a full grocery trip.',
        '$intro: ${profile.communityLabel} favorece despensa, conveniencia y descuento antes de un viaje grande al supermercado.',
      );
    }
    return copy.choose(
      '$intro: ${profile.communityLabel} access is built into today\'s ranking.',
      '$intro: el acceso de ${profile.communityLabel} ya esta incluido en el ranking de hoy.',
    );
  }
}

class _EvidenceStatusCard extends StatelessWidget {
  const _EvidenceStatusCard({
    required this.copy,
    required this.profile,
    required this.accessResolution,
  });

  final AppCopy copy;
  final UserProfile profile;
  final LocalAccessProfileResolution? accessResolution;

  @override
  Widget build(BuildContext context) {
    final store = profile.constraints.feasibility.groceryStore;
    final access = profile.constraints.access;

    String bundledLine() {
      if (accessResolution == null || access.postalCode.isEmpty) {
        return copy.choose(
          'No ZIP access model is loaded, so source burden falls back to your saved setup.',
          'No hay modelo ZIP cargado, asi que la carga de viaje usa tu configuracion guardada.',
        );
      }

      final modelType = switch (accessResolution!.matchType) {
        LocalAccessMatchType.exact => copy.choose(
          'a higher-confidence bundled ZIP snapshot',
          'un panorama ZIP incluido de mayor confianza',
        ),
        LocalAccessMatchType.prefix => copy.choose(
          'a broader bundled ZIP-area estimate',
          'una estimacion incluida mas amplia por area ZIP',
        ),
        LocalAccessMatchType.fallback => copy.choose(
          'a lower-confidence bundled fallback estimate',
          'una estimacion incluida de respaldo con menor confianza',
        ),
      };

      return copy.choose(
        'Access burden for pantry, convenience, dollar-store, and grocery trips is modeled from $modelType for ${accessResolution!.profile.communityLabel}.',
        'La carga de viaje para despensa, conveniencia, tienda de dolar y supermercado se modela con $modelType para ${accessResolution!.profile.communityLabel}.',
      );
    }

    final lines = <String>[
      bundledLine(),
      if (accessResolution != null && access.postalCode.isNotEmpty)
        _confidenceLine(),
      if (accessResolution != null && access.postalCode.isNotEmpty)
        copy.choose(
          'Bundled coverage includes ${accessResolution!.profile.sources.length} source types for this area model.',
          'La cobertura incluida usa ${accessResolution!.profile.sources.length} tipos de fuente para este modelo de area.',
        ),
      if (store != null)
        copy.choose(
          'Live grocery brands and prices are store-specific only for ${store.name}. Other source types still use bundled modeled access, not live inventory.',
          'Las marcas y precios en vivo solo son especificos para ${store.name}. Las otras fuentes siguen usando acceso modelado incluido, no inventario en vivo.',
        )
      else
        copy.choose(
          'No live grocery store is attached right now. Grocery access is still ranked with bundled modeled data.',
          'No hay una tienda de comestibles en vivo conectada ahora. El acceso a supermercado sigue usando datos modelados incluidos.',
        ),
      if (accessResolution?.profile.notes?.isNotEmpty == true)
        accessResolution!.profile.notes!,
    ];

    return SectionCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Semantics(
        container: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              copy.choose('Decision evidence', 'Evidencia de la decision'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            for (final line in lines) ...[
              Text(line, style: Theme.of(context).textTheme.bodyMedium),
              if (line != lines.last) const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }

  String _confidenceLine() {
    final resolution = accessResolution!;
    switch (resolution.matchType) {
      case LocalAccessMatchType.exact:
        return copy.choose(
          'Confidence is stronger here because this is an exact ZIP match.',
          'La confianza es mayor aqui porque esta usando un ZIP exacto.',
        );
      case LocalAccessMatchType.prefix:
        return copy.choose(
          'Confidence is moderate here because this uses a broader ZIP-area estimate.',
          'La confianza es media aqui porque usa una estimacion mas amplia por area ZIP.',
        );
      case LocalAccessMatchType.fallback:
        return copy.choose(
          'Confidence is lower here because this falls back to a general low-resource model.',
          'La confianza es menor aqui porque usa un modelo general de respaldo para contextos de pocos recursos.',
        );
    }
  }
}

class _ActionSummaryCard extends StatelessWidget {
  const _ActionSummaryCard({
    required this.copy,
    required this.result,
    required this.emergencyMode,
  });

  final AppCopy copy;
  final RecommendationResult? result;
  final bool emergencyMode;

  @override
  Widget build(BuildContext context) {
    final todayPlan = result?.todayPlan;
    final sourceTrip = result?.sourceTripPlan;
    final homeFact = _homeFact(todayPlan);
    final buyFirst = _purchaseLabels(
      todayPlan,
      PlannedPurchasePriority.buyFirst,
      fallback: copy.choose(
        'No purchase needed yet',
        'Todavia no hace falta comprar',
      ),
    );
    final skipFirst = _purchaseLabels(
      todayPlan,
      PlannedPurchasePriority.skipFirst,
      fallback: copy.choose(
        'No clear skip item yet',
        'Todavia no hay algo claro para dejar',
      ),
    );
    final backup = todayPlan?.backupAction?.trim().isNotEmpty == true
        ? todayPlan!.backupAction!
        : sourceTrip?.backupSource != null
        ? copy.sourceTripBackupStop(copy.sourceLabel(sourceTrip!.backupSource!))
        : copy.choose(
            'No backup listed yet',
            'Todavia no hay respaldo listado',
          );
    final routeReason = _routeReason(todayPlan, sourceTrip);

    return SectionCard(
      tintColor: emergencyMode
          ? NihPalette.warning.withValues(alpha: 0.18)
          : NihPalette.primaryAltLight,
      child: Semantics(
        container: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              emergencyMode
                  ? copy.choose('Do this now', 'Haz esto ahora')
                  : copy.choose('Do this first today', 'Haz esto primero hoy'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              emergencyMode
                  ? copy.choose(
                      'Emergency mode is active, so this is the fastest practical path.',
                      'El modo de emergencia esta activo, asi que esta es la ruta practica mas rapida.',
                    )
                  : copy.choose(
                      'This pulls the key action from your first stop, home inventory, and budget plan.',
                      'Esto junta la accion clave de tu primera parada, lo que tienes en casa y tu plan de presupuesto.',
                    ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            _ActionLine(
              label: copy.choose('Go first', 'Ve primero'),
              value:
                  sourceTrip?.title ??
                  copy.choose('Open today plan', 'Abre el plan de hoy'),
            ),
            const SizedBox(height: 10),
            _ActionLine(
              label: copy.choose('Use from home', 'Usa de casa'),
              value: homeFact,
            ),
            const SizedBox(height: 10),
            _ActionLine(
              label: copy.choose('Buy first', 'Compra primero'),
              value: buyFirst,
            ),
            const SizedBox(height: 10),
            _ActionLine(
              label: copy.choose('Skip first', 'Deja para despues'),
              value: skipFirst,
            ),
            const SizedBox(height: 10),
            _ActionLine(
              label: copy.choose('Why this route', 'Por que esta ruta'),
              value: routeReason,
            ),
            const SizedBox(height: 10),
            _ActionLine(
              label: copy.choose('Backup', 'Respaldo'),
              value: backup,
            ),
          ],
        ),
      ),
    );
  }

  String _homeFact(TodayPlan? todayPlan) {
    final facts = todayPlan?.leadRecommendation.explanation?.decisionFacts;
    if (facts != null) {
      final match = facts.where(
        (fact) => fact.label == copy.choose('From home', 'Desde casa'),
      );
      if (match.isNotEmpty) {
        return match.first.value;
      }
    }

    String? homeStep;
    for (final step in todayPlan?.steps ?? const <String>[]) {
      final lowered = step.toLowerCase();
      if (lowered.contains('home') || lowered.contains('casa')) {
        homeStep = step;
        break;
      }
    }
    return homeStep ??
        copy.choose(
          'No pantry step is listed yet',
          'Todavia no hay un paso claro de despensa',
        );
  }

  String _purchaseLabels(
    TodayPlan? todayPlan,
    PlannedPurchasePriority priority, {
    required String fallback,
  }) {
    final matches =
        todayPlan?.purchases
            .where((item) => item.priority == priority)
            .take(2)
            .map((item) => item.label)
            .toList(growable: false) ??
        const <String>[];
    if (matches.isEmpty) {
      return fallback;
    }
    return matches.join(' | ');
  }

  String _routeReason(TodayPlan? todayPlan, SourceTripPlan? sourceTrip) {
    final todayReason = todayPlan?.routeReason?.trim();
    if (todayReason != null && todayReason.isNotEmpty) {
      return todayReason;
    }
    final tripReason = sourceTrip?.routeReason?.trim();
    if (tripReason != null && tripReason.isNotEmpty) {
      return tripReason;
    }
    return sourceTrip?.summary ??
        copy.choose(
          'This is the lowest-burden route still on the board.',
          'Esta es la ruta de menor carga que todavia queda disponible.',
        );
  }
}

class _PinnedOverview extends StatelessWidget {
  const _PinnedOverview({
    required this.profile,
    required this.result,
    required this.copy,
  });

  final UserProfile profile;
  final RecommendationResult? result;
  final AppCopy copy;

  @override
  Widget build(BuildContext context) {
    final feasibility = profile.constraints.feasibility;
    final preference = profile.constraints.preference;
    final access = profile.constraints.access;
    final pantry = profile.constraints.pantry;
    final cards = <Widget>[
      _MiniInsightCard(
        color: NihPalette.primary,
        title: copy.choose('Preparation', 'Preparacion'),
        value: copy.prepEnvironmentLabel(feasibility.environment),
        detail: copy.choose(
          '${feasibility.availability.length} shopping contexts',
          '${feasibility.availability.length} contextos de compra',
        ),
        icon: Icons.microwave_rounded,
      ),
      _MiniInsightCard(
        color: NihPalette.secondary,
        title: copy.choose('Meal', 'Comida'),
        value: copy.mealTimingLabel(preference.mealType),
        detail: preference.dietaryStyle == DietaryStyle.unrestricted
            ? copy.choose('No extra diet filter', 'Sin filtro extra')
            : copy.dietaryStyleLabel(preference.dietaryStyle),
        icon: Icons.restaurant_menu_rounded,
      ),
      _MiniInsightCard(
        color: NihPalette.success,
        title: copy.choose('Access', 'Acceso'),
        value: access.emergencyMode
            ? copy.choose('Emergency on', 'Emergencia activa')
            : copy.transportationLabel(access.transportation),
        detail: _accessDetail(
          access: access,
          pantry: pantry,
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
    required PantryConstraints pantry,
    required int shownCount,
  }) {
    final detailParts = <String>[];
    if (pantry.enoughItems.isNotEmpty) {
      detailParts.add('${pantry.enoughItems.length} ready');
    }
    if (pantry.lowStockItems.isNotEmpty) {
      detailParts.add('${pantry.lowStockItems.length} low');
    }
    if (pantry.restockItems.isNotEmpty) {
      detailParts.add('${pantry.restockItems.length} restock');
    }
    if (access.benefitPrograms.contains(BenefitProgram.snap)) {
      detailParts.add(copy.choose('SNAP aware', 'Con SNAP'));
    }
    if (access.benefitPrograms.contains(BenefitProgram.wic)) {
      detailParts.add(copy.choose('WIC aware', 'Con WIC'));
    }
    if (detailParts.isEmpty) {
      detailParts.add(
        copy.choose(
          '$shownCount options shown now',
          '$shownCount opciones visibles ahora',
        ),
      );
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

class _ActionLine extends StatelessWidget {
  const _ActionLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 320 || textScale > 1.15;
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 92,
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CompareChoicesCard extends StatelessWidget {
  const _CompareChoicesCard({
    required this.recommendations,
    required this.copy,
    required this.emergencyMode,
  });

  final List<ScoredFood> recommendations;
  final AppCopy copy;
  final bool emergencyMode;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Semantics(
        container: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              copy.choose('Compare top picks', 'Compara las mejores opciones'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              emergencyMode
                  ? copy.choose(
                      'Fast comparison for your top option and the next reachable backups.',
                      'Comparacion rapida entre tu mejor opcion y los siguientes respaldos alcanzables.',
                    )
                  : copy.choose(
                      'See cost, trip burden, benefits fit, and home-use fit before you choose.',
                      'Mira costo, carga de viaje, ajuste con beneficios y apoyo desde casa antes de elegir.',
                    ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            for (var index = 0; index < recommendations.length; index++) ...[
              _CompareChoiceRow(
                recommendation: recommendations[index],
                label: index == 0
                    ? copy.choose('Top pick', 'Mejor opcion')
                    : copy.choose('Backup $index', 'Respaldo $index'),
              ),
              if (index < recommendations.length - 1)
                const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompareChoiceRow extends StatelessWidget {
  const _CompareChoiceRow({required this.recommendation, required this.label});

  final ScoredFood recommendation;
  final String label;

  @override
  Widget build(BuildContext context) {
    final facts = recommendation.explanation?.decisionFacts ?? const [];
    final visibleFacts = facts.length > 1
        ? facts.sublist(0, facts.length - 1).take(5).toList()
        : facts;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            recommendation.food.name,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            recommendation.explanation?.accessSummary ??
                '${recommendation.displayScore.round()}/100',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (visibleFacts.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: visibleFacts
                  .map(
                    (fact) =>
                        _CompareFactPill(label: fact.label, value: fact.value),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompareFactPill extends StatelessWidget {
  const _CompareFactPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(
        '$label: $value',
        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.copy,
    required this.plainLanguage,
    required this.result,
    required this.onAdjust,
  });

  final AppCopy copy;
  final bool plainLanguage;
  final RecommendationResult result;
  final VoidCallback onAdjust;

  @override
  Widget build(BuildContext context) {
    final diagnostic = result.diagnostic;
    return SectionCard(
      tintColor: NihPalette.secondaryLight,
      child: Semantics(
        container: true,
        label: copy.choose(
          'No current matches found',
          'No se encontraron opciones ahora',
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              copy.choose(
                'Nothing matches every rule right now.',
                'Nada coincide con todas las reglas ahora mismo.',
              ),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              diagnostic == null
                  ? copy.choose(
                      'Open Adjust and loosen one part of your setup so more safe options can appear.',
                      'Abre Ajustar y afloja una parte de tu configuracion para que salgan mas opciones seguras.',
                    )
                  : diagnostic.suggestion,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 14),
            Text(
              copy.choose('Try this first', 'Prueba esto primero'),
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _BulletLine(
              text: diagnostic == null
                  ? copy.choose(
                      'Widen one filter such as budget, store type, or meal timing.',
                      'Abre un poco un filtro como presupuesto, tipo de tienda u horario de comida.',
                    )
                  : diagnostic.suggestion,
            ),
            if (diagnostic != null)
              _BulletLine(
                text: plainLanguage
                    ? copy.choose(
                        'Start with the main blocker: ${_blockerLabel(diagnostic.mostRestrictive)}.',
                        'Empieza por el bloqueo principal: ${_blockerLabel(diagnostic.mostRestrictive)}.',
                      )
                    : copy.choose(
                        'Most restrictive area right now: ${diagnostic.mostRestrictive.label}.',
                        'El area mas restrictiva ahora es: ${diagnostic.mostRestrictive.label}.',
                      ),
              ),
            if (diagnostic != null) ...[
              const SizedBox(height: 12),
              Chip(
                label: Text(
                  '${copy.choose('Biggest blocker', 'Bloqueo principal')}: ${_blockerLabel(diagnostic.mostRestrictive)}',
                ),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAdjust,
              icon: const Icon(Icons.tune_rounded),
              label: Text(
                copy.choose('Adjust constraints', 'Ajustar restricciones'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _blockerLabel(BlockingConstraint blocker) {
    switch (blocker) {
      case BlockingConstraint.safety:
        return copy.choose('Safety rules', 'Reglas de seguridad');
      case BlockingConstraint.budget:
        return copy.choose('Budget', 'Presupuesto');
      case BlockingConstraint.environment:
        return copy.choose('Cooking setup', 'Equipo para cocinar');
      case BlockingConstraint.availability:
        return copy.choose(
          'Places you can shop',
          'Lugares donde puedes comprar',
        );
      case BlockingConstraint.preference:
        return copy.choose('Food preferences', 'Preferencias de comida');
    }
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
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
