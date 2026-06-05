import '../../domain/entities/food.dart';
import '../../domain/entities/meal_shopping.dart';
import '../../domain/entities/user_constraints.dart';
import '../../domain/value_objects/availability_context.dart';

class MealIngredientPlanner {
  const MealIngredientPlanner();

  IngredientPlan build({
    required Food food,
    required PantryConstraints pantry,
  }) {
    final requirements = _requirementsFor(food);
    final atHome = <IngredientRequirement>[];
    final toBuy = <IngredientRequirement>[];

    for (final requirement in requirements) {
      if (_hasAtHome(requirement, pantry)) {
        atHome.add(requirement);
      } else {
        toBuy.add(requirement);
      }
    }

    return IngredientPlan(
      atHome: atHome,
      toBuy: toBuy,
      buySummary: toBuy.isEmpty
          ? 'Nothing to buy'
          : toBuy.map((item) => item.label).join(', '),
    );
  }

  List<IngredientRequirement> _requirementsFor(Food food) {
    if (_isFastFoodMenuOrder(food)) {
      return [
        IngredientRequirement(
          key: 'order-${food.id}',
          label: food.name,
          searchTerms: const [],
          pantryAliases: const [],
          evidence: IngredientEvidence.menuItem,
          quantityLabel: food.servingLabel,
        ),
      ];
    }

    final structured = _structuredMealRequirements[food.id];
    if (structured != null && structured.isNotEmpty) {
      return structured;
    }

    final fallbackTokens = food.ingredients.isEmpty
        ? _fallbackTokens(food.name)
        : food.ingredients.toList(growable: false);
    return fallbackTokens
        .map(
          (token) => IngredientRequirement(
            key: token,
            label: _titleize(token),
            searchTerms: [token],
            pantryAliases: [token],
            evidence: IngredientEvidence.estimated,
          ),
        )
        .toList(growable: false);
  }

  bool _isFastFoodMenuOrder(Food food) {
    return food.availability.length == 1 &&
        food.availability.contains(AvailabilityContext.fastFood);
  }

  bool _hasAtHome(IngredientRequirement requirement, PantryConstraints pantry) {
    for (final alias in requirement.pantryAliases) {
      final stock = pantry.stockFor(alias);
      if (stock == PantryStockLevel.enough || stock == PantryStockLevel.low) {
        return true;
      }
    }
    return false;
  }

  List<String> _fallbackTokens(String raw) {
    const stopwords = {
      'with',
      'and',
      'the',
      'style',
      'whole',
      'grain',
      'fresh',
      'mixed',
      'plain',
      'microwave',
      'instant',
    };
    return raw
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((token) => token.length > 2 && !stopwords.contains(token))
        .toSet()
        .toList(growable: false);
  }

  String _titleize(String value) {
    return value
        .split(RegExp(r'[_ ]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

IngredientRequirement _structuredIngredient(
  String key,
  String label, {
  List<String>? searchTerms,
  List<String>? pantryAliases,
  String? quantityLabel,
}) {
  return IngredientRequirement(
    key: key,
    label: label,
    searchTerms: searchTerms ?? [label.toLowerCase()],
    pantryAliases: pantryAliases ?? [key, label.toLowerCase(), ...?searchTerms],
    evidence: IngredientEvidence.structured,
    quantityLabel: quantityLabel,
  );
}

final _structuredMealRequirements = <int, List<IngredientRequirement>>{
  1: [
    _structuredIngredient(
      'lentil_soup',
      'Lentil soup',
      searchTerms: ['lentil soup'],
      pantryAliases: ['lentil soup', 'lentils'],
      quantityLabel: '1 bowl or can',
    ),
    _structuredIngredient(
      'whole_grain_bread',
      'Whole-grain bread',
      searchTerms: ['whole grain bread', 'whole wheat bread'],
      pantryAliases: ['bread', 'whole grain bread', 'whole wheat bread'],
      quantityLabel: '1 loaf',
    ),
  ],
  2: [
    _structuredIngredient(
      'black_beans',
      'Black beans',
      searchTerms: ['black beans'],
      pantryAliases: ['beans', 'black beans'],
      quantityLabel: '1 can',
    ),
    _structuredIngredient(
      'brown_rice',
      'Brown rice',
      searchTerms: ['brown rice cup', 'microwave brown rice'],
      pantryAliases: ['brown rice', 'rice'],
      quantityLabel: '1 cup',
    ),
    _structuredIngredient(
      'salsa',
      'Salsa',
      searchTerms: ['salsa'],
      pantryAliases: ['salsa'],
      quantityLabel: '1 jar',
    ),
  ],
  3: [
    _structuredIngredient(
      'chickpea_curry',
      'Chickpea curry entree',
      searchTerms: ['chickpea curry', 'curry entree'],
      pantryAliases: ['curry', 'chickpeas'],
      quantityLabel: '1 entree',
    ),
    _structuredIngredient(
      'brown_rice',
      'Brown rice',
      searchTerms: ['brown rice cup', 'microwave brown rice'],
      pantryAliases: ['brown rice', 'rice'],
      quantityLabel: '1 cup',
    ),
  ],
  4: [
    _structuredIngredient(
      'greek_yogurt',
      'Greek yogurt',
      searchTerms: ['greek yogurt'],
      pantryAliases: ['greek yogurt', 'yogurt'],
      quantityLabel: '1 tub',
    ),
    _structuredIngredient(
      'berries',
      'Berries',
      searchTerms: ['berries', 'frozen berries'],
      pantryAliases: ['berries'],
      quantityLabel: '1 bag',
    ),
    _structuredIngredient(
      'oats',
      'Oats',
      searchTerms: ['rolled oats', 'oats'],
      pantryAliases: ['oats', 'oatmeal'],
      quantityLabel: '1 container',
    ),
  ],
  5: [
    _structuredIngredient(
      'peanut_butter',
      'Peanut butter',
      searchTerms: ['peanut butter'],
      pantryAliases: ['peanut butter'],
      quantityLabel: '1 jar',
    ),
    _structuredIngredient(
      'banana',
      'Banana',
      searchTerms: ['banana'],
      pantryAliases: ['banana'],
      quantityLabel: '2 bananas',
    ),
    _structuredIngredient(
      'whole_wheat_bread',
      'Whole-wheat bread',
      searchTerms: ['whole wheat bread'],
      pantryAliases: ['bread', 'whole wheat bread'],
      quantityLabel: '1 loaf',
    ),
  ],
  6: [
    _structuredIngredient(
      'caesar_salad_kit',
      'Caesar salad kit',
      searchTerms: ['caesar salad kit'],
      pantryAliases: ['caesar salad', 'salad kit', 'lettuce'],
      quantityLabel: '1 kit',
    ),
    _structuredIngredient(
      'grilled_chicken',
      'Grilled chicken',
      searchTerms: ['grilled chicken'],
      pantryAliases: ['chicken', 'grilled chicken'],
      quantityLabel: '1 package',
    ),
  ],
  7: [
    _structuredIngredient(
      'oatmeal',
      'Oatmeal',
      searchTerms: ['oatmeal cup', 'oatmeal'],
      pantryAliases: ['oatmeal', 'oats'],
      quantityLabel: '1 cup',
    ),
    _structuredIngredient(
      'milk',
      'Milk',
      searchTerms: ['milk'],
      pantryAliases: ['milk'],
      quantityLabel: '1 carton',
    ),
  ],
  8: [
    _structuredIngredient(
      'apple',
      'Apple',
      searchTerms: ['apple'],
      pantryAliases: ['apple'],
      quantityLabel: '2 apples',
    ),
    _structuredIngredient(
      'almond_butter',
      'Almond butter packet',
      searchTerms: ['almond butter packet', 'almond butter'],
      pantryAliases: ['almond butter'],
      quantityLabel: '1 box',
    ),
  ],
  9: [
    _structuredIngredient(
      'tuna',
      'Tuna pouch',
      searchTerms: ['tuna pouch', 'tuna'],
      pantryAliases: ['tuna'],
      quantityLabel: '1 pouch',
    ),
    _structuredIngredient(
      'whole_wheat_bread',
      'Whole-wheat bread',
      searchTerms: ['whole wheat bread'],
      pantryAliases: ['bread', 'whole wheat bread'],
      quantityLabel: '1 loaf',
    ),
  ],
  10: [
    _structuredIngredient(
      'beans',
      'Beans',
      searchTerms: ['black beans', 'canned beans'],
      pantryAliases: ['beans'],
      quantityLabel: '1 can',
    ),
    _structuredIngredient(
      'rice',
      'Rice',
      searchTerms: ['rice cup', 'microwave rice'],
      pantryAliases: ['rice'],
      quantityLabel: '1 cup',
    ),
  ],
  11: [
    _structuredIngredient(
      'hummus',
      'Hummus',
      searchTerms: ['hummus'],
      pantryAliases: ['hummus'],
      quantityLabel: '1 tub',
    ),
    _structuredIngredient(
      'carrots',
      'Carrot sticks',
      searchTerms: ['baby carrots', 'carrot sticks'],
      pantryAliases: ['carrots', 'carrot sticks'],
      quantityLabel: '1 bag',
    ),
  ],
  12: [
    _structuredIngredient(
      'pizza',
      'Cheese pizza slice or ready pizza',
      searchTerms: ['cheese pizza'],
      pantryAliases: ['pizza'],
      quantityLabel: '1 pizza',
    ),
  ],
  13: [
    _structuredIngredient(
      'carnitas',
      'Pork carnitas',
      searchTerms: ['pork carnitas', 'carnitas'],
      pantryAliases: ['pork', 'carnitas'],
      quantityLabel: '1 package',
    ),
    _structuredIngredient(
      'tortillas',
      'Tortillas',
      searchTerms: ['corn tortillas', 'flour tortillas'],
      pantryAliases: ['tortillas'],
      quantityLabel: '1 pack',
    ),
  ],
  14: [
    _structuredIngredient(
      'stir_fry_vegetables',
      'Stir-fry vegetables',
      searchTerms: ['stir fry vegetables', 'frozen stir fry vegetables'],
      pantryAliases: ['vegetables', 'stir fry vegetables'],
      quantityLabel: '1 bag',
    ),
    _structuredIngredient(
      'tofu',
      'Tofu',
      searchTerms: ['tofu'],
      pantryAliases: ['tofu'],
      quantityLabel: '1 block',
    ),
    _structuredIngredient(
      'rice',
      'Rice',
      searchTerms: ['rice cup', 'microwave rice'],
      pantryAliases: ['rice'],
      quantityLabel: '1 cup',
    ),
  ],
  15: [
    _structuredIngredient(
      'banana',
      'Banana',
      searchTerms: ['banana'],
      pantryAliases: ['banana'],
      quantityLabel: '1 banana',
    ),
  ],
  16: [
    _structuredIngredient(
      'eggs',
      'Eggs',
      searchTerms: ['hard boiled eggs', 'eggs'],
      pantryAliases: ['egg', 'eggs'],
      quantityLabel: '1 dozen',
    ),
  ],
  17: [
    _structuredIngredient(
      'whole_wheat_pasta',
      'Whole-wheat pasta',
      searchTerms: ['whole wheat pasta'],
      pantryAliases: ['pasta', 'whole wheat pasta'],
      quantityLabel: '1 box',
    ),
    _structuredIngredient(
      'marinara',
      'Marinara sauce',
      searchTerms: ['marinara sauce', 'pasta sauce'],
      pantryAliases: ['marinara', 'pasta sauce'],
      quantityLabel: '1 jar',
    ),
  ],
  18: [
    _structuredIngredient(
      'salmon',
      'Salmon fillet',
      searchTerms: ['salmon fillet'],
      pantryAliases: ['salmon'],
      quantityLabel: '1 fillet',
    ),
    _structuredIngredient(
      'quinoa',
      'Quinoa',
      searchTerms: ['quinoa'],
      pantryAliases: ['quinoa'],
      quantityLabel: '1 pouch',
    ),
  ],
  19: [
    _structuredIngredient(
      'mixed_nuts',
      'Mixed nuts',
      searchTerms: ['mixed nuts'],
      pantryAliases: ['mixed nuts', 'nuts'],
      quantityLabel: '1 bag',
    ),
  ],
  20: [
    _structuredIngredient(
      'refried_beans',
      'Refried or black beans',
      searchTerms: ['refried beans', 'black beans'],
      pantryAliases: ['beans', 'refried beans'],
      quantityLabel: '1 can',
    ),
    _structuredIngredient(
      'cheese',
      'Shredded cheese',
      searchTerms: ['shredded cheese'],
      pantryAliases: ['cheese'],
      quantityLabel: '1 bag',
    ),
    _structuredIngredient(
      'tortillas',
      'Tortillas',
      searchTerms: ['tortillas'],
      pantryAliases: ['tortillas'],
      quantityLabel: '1 pack',
    ),
  ],
  44: [
    _structuredIngredient(
      'tuna_pouch',
      'Tuna pouch',
      searchTerms: ['tuna pouch'],
      pantryAliases: ['tuna'],
      quantityLabel: '1 pouch',
    ),
    _structuredIngredient(
      'whole_grain_crackers',
      'Whole-grain crackers',
      searchTerms: ['whole grain crackers'],
      pantryAliases: ['crackers', 'whole grain crackers'],
      quantityLabel: '1 box',
    ),
  ],
  45: [
    _structuredIngredient(
      'black_beans',
      'Black beans',
      searchTerms: ['black beans'],
      pantryAliases: ['beans', 'black beans'],
      quantityLabel: '1 can',
    ),
    _structuredIngredient(
      'brown_rice_cup',
      'Brown rice cup',
      searchTerms: ['brown rice cup', 'microwave brown rice'],
      pantryAliases: ['brown rice', 'rice'],
      quantityLabel: '1 cup',
    ),
  ],
  46: [
    _structuredIngredient(
      'instant_oatmeal',
      'Instant oatmeal cup',
      searchTerms: ['instant oatmeal cup', 'oatmeal cup'],
      pantryAliases: ['oatmeal', 'oats'],
      quantityLabel: '1 cup',
    ),
    _structuredIngredient(
      'peanut_butter',
      'Peanut butter',
      searchTerms: ['peanut butter'],
      pantryAliases: ['peanut butter'],
      quantityLabel: '1 jar',
    ),
  ],
  47: [
    _structuredIngredient(
      'greek_yogurt',
      'Greek yogurt',
      searchTerms: ['greek yogurt'],
      pantryAliases: ['greek yogurt', 'yogurt'],
      quantityLabel: '1 tub',
    ),
    _structuredIngredient(
      'mixed_nuts',
      'Mixed nuts',
      searchTerms: ['mixed nuts'],
      pantryAliases: ['mixed nuts', 'nuts'],
      quantityLabel: '1 bag',
    ),
  ],
  48: [
    _structuredIngredient(
      'cottage_cheese',
      'Cottage cheese',
      searchTerms: ['cottage cheese'],
      pantryAliases: ['cottage cheese'],
      quantityLabel: '1 tub',
    ),
    _structuredIngredient(
      'pineapple',
      'Pineapple',
      searchTerms: ['pineapple chunks', 'pineapple'],
      pantryAliases: ['pineapple'],
      quantityLabel: '1 can',
    ),
  ],
  49: [
    _structuredIngredient(
      'hummus_snack_box',
      'Hummus snack box',
      searchTerms: ['hummus snack box', 'hummus'],
      pantryAliases: ['hummus'],
      quantityLabel: '1 box',
    ),
    _structuredIngredient(
      'pretzels',
      'Pretzels',
      searchTerms: ['pretzels'],
      pantryAliases: ['pretzels'],
      quantityLabel: '1 bag',
    ),
    _structuredIngredient(
      'carrots',
      'Carrots',
      searchTerms: ['baby carrots'],
      pantryAliases: ['carrots'],
      quantityLabel: '1 bag',
    ),
  ],
  50: [
    _structuredIngredient(
      'sardines',
      'Sardines',
      searchTerms: ['sardines'],
      pantryAliases: ['sardines'],
      quantityLabel: '1 tin',
    ),
    _structuredIngredient(
      'saltines',
      'Saltines',
      searchTerms: ['saltines'],
      pantryAliases: ['saltines', 'crackers'],
      quantityLabel: '1 box',
    ),
  ],
  52: [
    _structuredIngredient(
      'shelf_stable_milk',
      'Shelf-stable milk carton',
      searchTerms: ['shelf stable milk', 'milk carton'],
      pantryAliases: ['milk'],
      quantityLabel: '1 carton',
    ),
    _structuredIngredient(
      'cereal_cup',
      'Cereal cup',
      searchTerms: ['cereal cup', 'cereal'],
      pantryAliases: ['cereal'],
      quantityLabel: '1 cup',
    ),
  ],
  53: [
    _structuredIngredient(
      'split_pea_soup',
      'Split pea soup can',
      searchTerms: ['split pea soup'],
      pantryAliases: ['soup', 'split pea soup'],
      quantityLabel: '1 can',
    ),
    _structuredIngredient(
      'crackers',
      'Crackers',
      searchTerms: ['crackers'],
      pantryAliases: ['crackers'],
      quantityLabel: '1 box',
    ),
  ],
  54: [
    _structuredIngredient(
      'lentil_pasta',
      'Lentil pasta',
      searchTerms: ['lentil pasta'],
      pantryAliases: ['lentil pasta', 'pasta'],
      quantityLabel: '1 box',
    ),
    _structuredIngredient(
      'tomato_sauce',
      'Tomato sauce',
      searchTerms: ['tomato sauce', 'marinara sauce'],
      pantryAliases: ['tomato sauce', 'marinara'],
      quantityLabel: '1 jar',
    ),
  ],
  55: [
    _structuredIngredient(
      'eggs',
      'Eggs',
      searchTerms: ['eggs'],
      pantryAliases: ['egg', 'eggs'],
      quantityLabel: '1 dozen',
    ),
    _structuredIngredient(
      'toast_bread',
      'Bread',
      searchTerms: ['bread'],
      pantryAliases: ['bread'],
      quantityLabel: '1 loaf',
    ),
  ],
  56: [
    _structuredIngredient(
      'black_bean_chili',
      'Black bean chili cup',
      searchTerms: ['black bean chili', 'chili cup'],
      pantryAliases: ['chili', 'beans'],
      quantityLabel: '1 cup',
    ),
  ],
  58: [
    _structuredIngredient(
      'chickpea_salad_wrap_kit',
      'Chickpea salad wrap kit',
      searchTerms: ['chickpea salad wrap kit', 'chickpea salad'],
      pantryAliases: ['chickpeas', 'wrap'],
      quantityLabel: '1 kit',
    ),
  ],
  60: [
    _structuredIngredient(
      'edamame',
      'Shelled edamame',
      searchTerms: ['shelled edamame', 'edamame'],
      pantryAliases: ['edamame'],
      quantityLabel: '1 bag',
    ),
    _structuredIngredient(
      'brown_rice_cup',
      'Brown rice cup',
      searchTerms: ['brown rice cup', 'microwave brown rice'],
      pantryAliases: ['brown rice', 'rice'],
      quantityLabel: '1 cup',
    ),
  ],
  61: [
    _structuredIngredient(
      'instant_oats',
      'Instant oats cup',
      searchTerms: ['instant oats cup', 'oatmeal cup'],
      pantryAliases: ['oats', 'oatmeal'],
      quantityLabel: '1 cup',
    ),
  ],
  62: [
    _structuredIngredient(
      'canned_black_beans',
      'Canned black beans',
      searchTerms: ['canned black beans', 'black beans'],
      pantryAliases: ['beans', 'black beans'],
      quantityLabel: '1 can',
    ),
  ],
  64: [
    _structuredIngredient(
      'shelf_stable_milk',
      'Shelf-stable low-fat milk carton',
      searchTerms: ['shelf stable low fat milk', 'low fat milk carton'],
      pantryAliases: ['milk'],
      quantityLabel: '1 carton',
    ),
  ],
  65: [
    _structuredIngredient(
      'tuna_pouch',
      'Tuna pouch',
      searchTerms: ['tuna pouch'],
      pantryAliases: ['tuna'],
      quantityLabel: '1 pouch',
    ),
    _structuredIngredient(
      'crackers',
      'Crackers',
      searchTerms: ['crackers'],
      pantryAliases: ['crackers'],
      quantityLabel: '1 box',
    ),
  ],
  68: [
    _structuredIngredient(
      'corn_tortillas',
      'Corn tortillas',
      searchTerms: ['corn tortillas'],
      pantryAliases: ['tortillas', 'corn tortillas'],
      quantityLabel: '1 pack',
    ),
    _structuredIngredient(
      'refried_beans',
      'Refried beans',
      searchTerms: ['refried beans'],
      pantryAliases: ['beans', 'refried beans'],
      quantityLabel: '1 can',
    ),
  ],
  70: [
    _structuredIngredient(
      'rice_pouch',
      'Rice pouch',
      searchTerms: ['rice pouch', 'microwave rice'],
      pantryAliases: ['rice'],
      quantityLabel: '1 pouch',
    ),
    _structuredIngredient(
      'sardines',
      'Sardines',
      searchTerms: ['sardines'],
      pantryAliases: ['sardines'],
      quantityLabel: '1 tin',
    ),
  ],
  71: [
    _structuredIngredient(
      'chicken_noodle_soup',
      'Chicken noodle soup',
      searchTerms: ['chicken noodle soup'],
      pantryAliases: ['soup', 'chicken noodle soup'],
      quantityLabel: '1 can',
    ),
    _structuredIngredient(
      'saltines',
      'Saltines',
      searchTerms: ['saltines'],
      pantryAliases: ['saltines', 'crackers'],
      quantityLabel: '1 box',
    ),
  ],
  73: [
    _structuredIngredient(
      'canned_chicken',
      'Canned chicken',
      searchTerms: ['canned chicken', 'chicken pouch'],
      pantryAliases: ['chicken'],
      quantityLabel: '1 can',
    ),
    _structuredIngredient(
      'crackers',
      'Crackers',
      searchTerms: ['crackers'],
      pantryAliases: ['crackers'],
      quantityLabel: '1 box',
    ),
  ],
  74: [
    _structuredIngredient(
      'peanut_butter',
      'Peanut butter',
      searchTerms: ['peanut butter'],
      pantryAliases: ['peanut butter'],
      quantityLabel: '1 jar',
    ),
    _structuredIngredient(
      'tortillas',
      'Tortillas',
      searchTerms: ['tortillas'],
      pantryAliases: ['tortillas'],
      quantityLabel: '1 pack',
    ),
  ],
  96: [
    _structuredIngredient(
      'flour_tortillas',
      'Flour tortillas',
      searchTerms: ['flour tortillas'],
      pantryAliases: ['tortillas', 'flour tortillas'],
      quantityLabel: '1 pack',
    ),
    _structuredIngredient(
      'refried_beans',
      'Refried beans',
      searchTerms: ['refried beans'],
      pantryAliases: ['beans', 'refried beans'],
      quantityLabel: '1 can',
    ),
    _structuredIngredient(
      'cheese_slices',
      'Cheese slices',
      searchTerms: ['cheese slices'],
      pantryAliases: ['cheese', 'cheese slices'],
      quantityLabel: '1 pack',
    ),
  ],
  169: [
    _structuredIngredient(
      'pancake_mix',
      'Pancake mix',
      searchTerms: ['pancake mix'],
      pantryAliases: ['pancake mix', 'pancakes'],
      quantityLabel: '1 box',
    ),
  ],
};
