import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../domain/entities/food.dart';
import '../../domain/entities/meal_shopping.dart';
import '../../domain/entities/user_constraints.dart';
import '../../domain/value_objects/availability_context.dart';

class FoodThumbnail extends StatelessWidget {
  const FoodThumbnail({
    super.key,
    required this.food,
    required this.accent,
    this.plan,
    this.constraints,
  });

  final Food food;
  final Color accent;
  final MealShoppingPlan? plan;
  final UserConstraints? constraints;

  @override
  Widget build(BuildContext context) {
    final kind = _MealArtKind.fromFood(food);
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0E8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _MealArtScene(kind: kind, accent: accent),
      ),
    );
  }
}

enum _MealArtKind {
  nutBag,
  fruitSnack,
  snackBowl,
  wrapSandwich,
  tunaPlate,
  steamedBowl,
  burgerCombo,
  wrapMeal,
  soupBread,
  breakfastCup,
  saladBowl,
  riceBowl,
  pizzaCombo,
  sandwichPlate,
  snackPack,
  proteinPlate,
  genericPlate;

  static _MealArtKind fromFood(Food food) {
    final normalizedName = food.name.trim().toLowerCase();
    final summary = '${food.name} ${food.ingredients.join(' ')}'.toLowerCase();

    if (normalizedName == 'trail mix snack pack') {
      return _MealArtKind.nutBag;
    }
    if (normalizedName == 'bean and cheese wrap') {
      return _MealArtKind.wrapSandwich;
    }
    if (normalizedName == 'tuna and cracker plate' ||
        normalizedName == 'pantry coleslaw mix bowl') {
      return _MealArtKind.tunaPlate;
    }
    if (normalizedName == 'fresh banana and peanut butter' ||
        normalizedName == 'convenience banana bunch') {
      return _MealArtKind.fruitSnack;
    }
    if (summary.contains('peanut') ||
        summary.contains('almond') ||
        summary.contains('cashew') ||
        summary.contains('nut') ||
        summary.contains('trail mix') ||
        summary.contains('snack')) {
      return _MealArtKind.snackBowl;
    }
    if (summary.contains('whole wheat') ||
        summary.contains('whole-wheat') ||
        summary.contains('bread') ||
        summary.contains('sandwich') ||
        summary.contains('toast') ||
        summary.contains('bagel')) {
      return _MealArtKind.wrapSandwich;
    }
    if (summary.contains('beans') ||
        summary.contains('bean') ||
        summary.contains('rice') ||
        summary.contains('grain') ||
        summary.contains('quinoa') ||
        summary.contains('lentil') ||
        summary.contains('dal') ||
        summary.contains('oatmeal') ||
        summary.contains('oats')) {
      return _MealArtKind.steamedBowl;
    }
    if (summary.contains('burger') ||
        summary.contains('mcmuffin') ||
        summary.contains('hamburger') ||
        summary.contains('cheeseburger') ||
        summary.contains('whopper')) {
      return _MealArtKind.burgerCombo;
    }
    if (summary.contains('taco') ||
        summary.contains('burrito') ||
        summary.contains('quesadilla') ||
        summary.contains('wrap')) {
      return _MealArtKind.wrapMeal;
    }
    if (summary.contains('soup') ||
        summary.contains('chili') ||
        summary.contains('dal')) {
      return _MealArtKind.soupBread;
    }
    if (summary.contains('oatmeal') ||
        summary.contains('yogurt') ||
        summary.contains('cereal') ||
        summary.contains('smoothie') ||
        summary.contains('milk') ||
        summary.contains('pancake')) {
      return _MealArtKind.breakfastCup;
    }
    if (summary.contains('salad')) {
      return _MealArtKind.saladBowl;
    }
    if (summary.contains('rice') ||
        summary.contains('quinoa') ||
        summary.contains('curry') ||
        summary.contains('stir-fry') ||
        summary.contains('beans') ||
        summary.contains('tofu')) {
      return _MealArtKind.riceBowl;
    }
    if (summary.contains('pizza')) {
      return _MealArtKind.pizzaCombo;
    }
    if (summary.contains('sandwich') ||
        summary.contains('toast') ||
        summary.contains('crackers') ||
        summary.contains('bagel')) {
      return _MealArtKind.sandwichPlate;
    }
    if (summary.contains('banana') ||
        summary.contains('apple') ||
        summary.contains('nuts') ||
        summary.contains('bar') ||
        summary.contains('edamame') ||
        summary.contains('egg')) {
      return _MealArtKind.snackPack;
    }
    if (summary.contains('chicken') ||
        summary.contains('salmon') ||
        summary.contains('shrimp')) {
      return _MealArtKind.proteinPlate;
    }
    if (food.availability.contains(AvailabilityContext.fastFood)) {
      return _MealArtKind.burgerCombo;
    }
    return _MealArtKind.genericPlate;
  }
}

class _MealArtScene extends StatelessWidget {
  const _MealArtScene({required this.kind, required this.accent});

  final _MealArtKind kind;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return switch (kind) {
      _MealArtKind.nutBag => _IconMealArtScene(
        icon: Icons.shopping_bag_rounded,
        accent: accent,
      ),
      _MealArtKind.fruitSnack => _IconMealArtScene(
        icon: Icons.food_bank_rounded,
        accent: accent,
      ),
      _MealArtKind.snackBowl || _MealArtKind.snackPack => _IconMealArtScene(
        icon: Icons.ramen_dining_rounded,
        accent: accent,
      ),
      _MealArtKind.tunaPlate => _IconMealArtScene(
        icon: Icons.dinner_dining_rounded,
        accent: accent,
      ),
      _MealArtKind.wrapSandwich || _MealArtKind.sandwichPlate =>
        _IconMealArtScene(icon: Icons.lunch_dining_rounded, accent: accent),
      _MealArtKind.steamedBowl ||
      _MealArtKind.soupBread ||
      _MealArtKind.saladBowl ||
      _MealArtKind.riceBowl ||
      _MealArtKind.proteinPlate ||
      _MealArtKind.genericPlate => _IconMealArtScene(
        icon: Icons.restaurant_rounded,
        accent: accent,
      ),
      _MealArtKind.burgerCombo ||
      _MealArtKind.wrapMeal ||
      _MealArtKind.pizzaCombo => _IconMealArtScene(
        icon: Icons
            .restaurant_rounded, // Defaulting to plate for these complex scenes in icon mode
        accent: accent,
      ),
      _MealArtKind.breakfastCup => _IconMealArtScene(
        icon: Icons.breakfast_dining_rounded,
        accent: accent,
      ),
    };
  }
}

class _IconMealArtScene extends StatelessWidget {
  const _IconMealArtScene({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Center(child: Icon(icon, size: 48, color: const Color(0xFF1B4332)));
  }
}

class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
