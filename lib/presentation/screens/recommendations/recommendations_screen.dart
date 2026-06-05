// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../domain/entities/recommendation.dart';
import '../../../domain/entities/user_profile.dart';
import '../../copy/app_copy.dart';
import '../../providers/profile_controller.dart';
import '../../providers/recommendations_provider.dart';
import '../../providers/nearby_store_providers.dart';
import '../../widgets/compact_action_plan_section.dart';
import '../../widgets/medical_disclaimer_banner.dart';
import '../../widgets/quick_adjust_sheet.dart';
import '../../widgets/recommendation_card.dart';
import '../../widgets/section_card.dart';
import '../../widgets/shopping_location_card.dart';
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
    final availabilityMode = ref.watch(storeAvailabilityModeProvider);
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
              copy.choose(
                'Meals you can get today',
                'Comidas que puedes conseguir hoy',
              ),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              copy.choose(
                'Practical meal options with verified nearby store lookup when live data is available.',
                'Opciones practicas con busqueda verificada de tiendas cercanas cuando hay datos en vivo.',
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (availabilityMode.isOffline) ...[
              const SizedBox(height: 14),
              _OfflineMealsBanner(copy: copy),
            ],
            const SizedBox(height: 14),
            MedicalDisclaimerBanner(copy: copy),
            const SizedBox(height: 14),
            const ShoppingLocationCard(),
            if (result != null &&
                (result.todayPlan != null || result.sourceTripPlan != null)) ...[
              const SizedBox(height: 12),
              CompactActionPlanSection(
                copy: copy,
                todayPlan: result.todayPlan,
                sourceTripPlan: result.sourceTripPlan,
                emergencyMode: profile.constraints.access.emergencyMode,
              ),
            ],
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
                    constraints: profile.constraints,
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

class _OfflineMealsBanner extends StatelessWidget {
  const _OfflineMealsBanner({required this.copy});

  final AppCopy copy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFC107)),
      ),
      child: Text(
        copy.offlineMealsBanner,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF8A5300),
          fontWeight: FontWeight.w700,
        ),
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
                name.trim().isEmpty ? 'Practical food help' : 'Meals for $name',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: NihPalette.warmSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: NihPalette.borderSoft),
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

