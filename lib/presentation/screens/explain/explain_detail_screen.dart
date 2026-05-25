import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../domain/entities/explanation.dart';
import '../../../domain/entities/recommendation.dart';
import '../../../domain/value_objects/user_language.dart';
import '../../copy/app_copy.dart';
import '../../providers/profile_controller.dart';
import '../../widgets/live_store_match_widgets.dart';
import '../../widgets/section_card.dart';

class ExplainDetailScreen extends ConsumerWidget {
  const ExplainDetailScreen({
    super.key,
    required this.recommendation,
    required this.allRecommendations,
  });

  final ScoredFood recommendation;
  final List<ScoredFood> allRecommendations;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider).valueOrNull;
    final language =
        profile?.constraints.access.language ?? UserLanguage.english;
    final plainLanguage = profile?.constraints.access.plainLanguage ?? true;
    final copy = AppCopy(language);
    final explanation = recommendation.explanation;
    final comparables = <ScoredFood>[
      for (final id in explanation?.compareWithIds ?? const <int>[])
        ...allRecommendations.where((item) => item.food.id == id).take(1),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(copy.choose('Why this food', 'Por que esta comida')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        children: [
          SectionCard(
            tintColor: NihPalette.primaryAltLight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation.food.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${recommendation.displayScore.round()}/100 | \$${recommendation.food.costEstimate.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (explanation != null) ...[
            SectionCard(
              child: _ExplanationSection(
                title: plainLanguage
                    ? copy.choose('Quick read', 'Lectura rapida')
                    : copy.choose('At a glance', 'Vista rapida'),
                children: _quickReadChildren(copy, explanation),
              ),
            ),
            const SizedBox(height: 12),
            if (explanation.decisionFacts.isNotEmpty) ...[
              SectionCard(
                child: _ExplanationSection(
                  title: plainLanguage
                      ? copy.choose(
                          'Decision details',
                          'Detalles de la decision',
                        )
                      : copy.choose('Decision snapshot', 'Resumen de decision'),
                  children: explanation.decisionFacts
                      .map(
                        (fact) => _BulletText('${fact.label}: ${fact.value}'),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (explanation.accessSummary?.isNotEmpty == true) ...[
              SectionCard(
                child: _ExplanationSection(
                  title: plainLanguage
                      ? copy.choose('Access details', 'Detalles de acceso')
                      : copy.choose('Access snapshot', 'Panorama de acceso'),
                  children: [
                    _BulletText(explanation.accessSummary!),
                    if (explanation.accessTags.isNotEmpty)
                      _BulletText(explanation.accessTags.join(' | ')),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            SectionCard(
              child: _ExplanationSection(
                title: plainLanguage
                    ? copy.choose('Works for you because', 'Te sirve porque')
                    : copy.choose(
                        'Satisfied constraints',
                        'Restricciones cumplidas',
                      ),
                children: explanation.satisfied
                    .map((item) => _BulletText(item.description))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              child: _ExplanationSection(
                title: plainLanguage
                    ? copy.choose('Why it helps', 'Por que ayuda')
                    : copy.choose('Top reasons', 'Razones principales'),
                children: explanation.positives
                    .map(
                      (item) => _BulletText(
                        item.detail == null
                            ? item.label
                            : '${item.label} | ${item.detail}',
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              child: _ExplanationSection(
                title: plainLanguage
                    ? copy.choose('Watch for', 'Ojo con esto')
                    : copy.choose('Tradeoffs', 'Concesiones'),
                children: explanation.tradeoffs.isEmpty
                    ? [
                        _BulletText(
                          copy.choose(
                            'No major tradeoffs surfaced for this profile.',
                            'No aparecieron concesiones grandes para este perfil.',
                          ),
                        ),
                      ]
                    : explanation.tradeoffs
                          .map(
                            (item) => _BulletText(
                              item.detail == null
                                  ? item.label
                                  : '${item.label} | ${item.detail}',
                            ),
                          )
                          .toList(),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SectionCard(
            child: _ExplanationSection(
              title: plainLanguage
                  ? copy.choose('Nutrition facts', 'Datos de nutricion')
                  : copy.choose('Nutrition snapshot', 'Panorama nutricional'),
              children: [
                _BulletText(
                  copy.choose(
                    'Protein: ${recommendation.nutrients.proteinG.toStringAsFixed(0)}g',
                    'Proteina: ${recommendation.nutrients.proteinG.toStringAsFixed(0)}g',
                  ),
                ),
                _BulletText(
                  copy.choose(
                    'Fiber: ${recommendation.nutrients.fiberG.toStringAsFixed(0)}g',
                    'Fibra: ${recommendation.nutrients.fiberG.toStringAsFixed(0)}g',
                  ),
                ),
                _BulletText(
                  copy.choose(
                    'Sodium: ${recommendation.nutrients.sodiumMg.toStringAsFixed(0)}mg',
                    'Sodio: ${recommendation.nutrients.sodiumMg.toStringAsFixed(0)}mg',
                  ),
                ),
                _BulletText(
                  copy.choose(
                    'Iron: ${recommendation.nutrients.ironMg.toStringAsFixed(1)}mg',
                    'Hierro: ${recommendation.nutrients.ironMg.toStringAsFixed(1)}mg',
                  ),
                ),
                _BulletText(
                  copy.choose(
                    'Calories: ${recommendation.nutrients.caloriesKcal.toStringAsFixed(0)} kcal',
                    'Calorias: ${recommendation.nutrients.caloriesKcal.toStringAsFixed(0)} kcal',
                  ),
                ),
              ],
            ),
          ),
          LiveStoreProductsSection(
            food: recommendation.food,
            emptyFallback: false,
          ),
          if (comparables.isNotEmpty) ...[
            const SizedBox(height: 12),
            SectionCard(
              child: _ExplanationSection(
                title: plainLanguage
                    ? copy.choose('Backups', 'Respaldos')
                    : copy.choose(
                        'Comparable alternatives',
                        'Alternativas comparables',
                      ),
                children: comparables
                    .map((item) => _AlternativeBullet(item: item))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _quickReadChildren(AppCopy copy, Explanation explanation) {
    final children = <Widget>[
      _BulletText(
        explanation.accessSummary ??
            copy.choose(
              'This option stayed near the top after safety, access, and cost checks.',
              'Esta opcion quedo arriba despues de revisar seguridad, acceso y costo.',
            ),
      ),
    ];

    for (final fact in explanation.decisionFacts.take(4)) {
      children.add(_BulletText('${fact.label}: ${fact.value}'));
    }

    if (explanation.tradeoffs.isNotEmpty) {
      final tradeoff = explanation.tradeoffs.first;
      children.add(
        _BulletText(
          '${copy.choose('Watch for', 'Ojo con esto')}: '
          '${tradeoff.detail == null ? tradeoff.label : '${tradeoff.label} | ${tradeoff.detail}'}',
        ),
      );
    }

    return children;
  }
}

class _AlternativeBullet extends StatelessWidget {
  const _AlternativeBullet({required this.item});

  final ScoredFood item;

  @override
  Widget build(BuildContext context) {
    final facts = item.explanation?.decisionFacts.take(3).toList() ?? const [];
    final factText = facts
        .map((fact) => '${fact.label}: ${fact.value}')
        .join(' | ');
    final line =
        '${item.food.name} (${item.displayScore.round()}/100, \$${item.food.costEstimate.toStringAsFixed(2)})';
    return _BulletText(factText.isEmpty ? line : '$line | $factText');
  }
}

class _ExplanationSection extends StatelessWidget {
  const _ExplanationSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _BulletText extends StatelessWidget {
  const _BulletText(this.text);

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
            child: Icon(Icons.circle, size: 6, color: NihPalette.primary),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
