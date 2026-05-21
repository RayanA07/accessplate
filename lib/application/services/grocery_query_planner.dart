import '../../domain/entities/food.dart';
import '../../domain/entities/grocery.dart';
import '../../domain/value_objects/availability_context.dart';

class GroceryQueryPlanner {
  List<GrocerySearchPlan> buildSearchPlans(Food food) {
    if (!food.availability.contains(AvailabilityContext.grocery)) {
      return const [];
    }

    final plans = <GrocerySearchPlan>[];
    final conceptPlan = _buildConceptPlan(food);
    if (conceptPlan != null) {
      plans.add(conceptPlan);
    }

    final exactPlan = _buildExactNamePlan(food);
    if (exactPlan != null &&
        plans.every(
          (existing) =>
              existing.term != exactPlan.term ||
              existing.displayLabel != exactPlan.displayLabel,
        )) {
      plans.add(exactPlan);
    }

    return plans;
  }

  GrocerySearchPlan? _buildConceptPlan(Food food) {
    final haystack = '${food.name.toLowerCase()} ${food.ingredients.join(' ')}';
    for (final concept in _concepts) {
      if (concept.matches(haystack)) {
        final exactMatch = _normalized(food.name) == concept.label;
        return GrocerySearchPlan(
          term: concept.term,
          displayLabel: concept.label,
          rationale: exactMatch
              ? 'Exact grocery item search'
              : 'Core staple search for this suggestion',
          exactMatch: exactMatch,
        );
      }
    }
    return null;
  }

  GrocerySearchPlan? _buildExactNamePlan(Food food) {
    final cleaned = _significantTokens(food.name);
    if (cleaned.isEmpty) {
      return null;
    }

    final displayLabel = cleaned.take(4).join(' ');
    if (displayLabel.isEmpty) {
      return null;
    }

    return GrocerySearchPlan(
      term: displayLabel,
      displayLabel: displayLabel,
      rationale: 'Closest product name search',
      exactMatch: cleaned.length <= 4,
    );
  }

  List<String> _significantTokens(String raw) {
    return _normalized(raw)
        .split(' ')
        .where((token) => token.isNotEmpty && !_stopwords.contains(token))
        .toList(growable: false);
  }

  String _normalized(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9& ]'), ' ')
        .replaceAll('&', ' and ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _Concept {
  const _Concept({
    required this.term,
    required this.label,
    required this.patterns,
  });

  final String term;
  final String label;
  final List<String> patterns;

  bool matches(String haystack) {
    return patterns.any(haystack.contains);
  }
}

const _concepts = <_Concept>[
  _Concept(
    term: 'greek yogurt',
    label: 'greek yogurt',
    patterns: ['greek yogurt'],
  ),
  _Concept(term: 'yogurt', label: 'yogurt', patterns: [' yogurt', 'yogurt ']),
  _Concept(
    term: 'cottage cheese',
    label: 'cottage cheese',
    patterns: ['cottage cheese'],
  ),
  _Concept(
    term: 'peanut butter',
    label: 'peanut butter',
    patterns: ['peanut butter'],
  ),
  _Concept(
    term: 'almond butter',
    label: 'almond butter',
    patterns: ['almond butter'],
  ),
  _Concept(term: 'tuna pouch', label: 'tuna pouch', patterns: ['tuna pouch']),
  _Concept(term: 'tuna', label: 'tuna', patterns: ['tuna']),
  _Concept(term: 'oatmeal', label: 'oatmeal', patterns: ['oatmeal', 'oats']),
  _Concept(term: 'cereal cup', label: 'cereal cup', patterns: ['cereal cup']),
  _Concept(term: 'cereal', label: 'cereal', patterns: ['cereal']),
  _Concept(term: 'soup', label: 'soup', patterns: ['soup']),
  _Concept(term: 'chili cup', label: 'chili cup', patterns: ['chili cup']),
  _Concept(term: 'rice cup', label: 'rice cup', patterns: ['rice cup']),
  _Concept(
    term: 'black beans',
    label: 'black beans',
    patterns: ['black beans', 'black bean'],
  ),
  _Concept(term: 'chickpeas', label: 'chickpeas', patterns: ['chickpea']),
  _Concept(term: 'edamame', label: 'edamame', patterns: ['edamame']),
  _Concept(term: 'milk', label: 'milk', patterns: ['milk']),
  _Concept(term: 'crackers', label: 'crackers', patterns: ['crackers']),
  _Concept(term: 'pretzels', label: 'pretzels', patterns: ['pretzels']),
  _Concept(term: 'banana', label: 'banana', patterns: ['banana']),
  _Concept(term: 'apple', label: 'apple', patterns: ['apple']),
  _Concept(term: 'mixed nuts', label: 'mixed nuts', patterns: ['mixed nuts']),
  _Concept(
    term: 'hard boiled eggs',
    label: 'hard boiled eggs',
    patterns: ['hard boiled eggs', 'hard boiled egg'],
  ),
  _Concept(
    term: 'lentil pasta',
    label: 'lentil pasta',
    patterns: ['lentil pasta'],
  ),
];

const _stopwords = {
  'a',
  'an',
  'and',
  'cup',
  'cups',
  'fresh',
  'kit',
  'low',
  'medium',
  'mix',
  'mixed',
  'of',
  'on',
  'plain',
  'salad',
  'sandwich',
  'small',
  'snack',
  'sticks',
  'whole',
  'with',
};
