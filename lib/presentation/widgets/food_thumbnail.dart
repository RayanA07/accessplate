import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../domain/entities/food.dart';
import '../../domain/entities/meal_shopping.dart';
import '../../domain/entities/user_constraints.dart';
import '../../domain/value_objects/availability_context.dart';
import 'meal_logo_resolver.dart';

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
    final logo = MealLogoResolver.resolve(
      food: food,
      plan: plan,
      constraints: constraints,
    );
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0E8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: NihPalette.borderSoft.withValues(alpha: 0.9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Positioned(
              right: -8,
              top: -10,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: -6,
              bottom: -6,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF).withValues(alpha: 0.54),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F0E8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: logo == null
                        ? _MealArtScene(kind: kind, accent: accent)
                        : _MealLogoScene(logo: logo, accent: accent),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealLogoScene extends StatelessWidget {
  const _MealLogoScene({required this.logo, required this.accent});

  final MealLogoSelection logo;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 10,
          top: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              logo.isFastFood ? 'FAST FOOD' : 'STORE',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.9,
                color: Color(0xFF5B5245),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 24, 10, 10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFF8F3E9),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0x14000000)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Image.asset(
                  logo.assetPath,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum _MealArtKind {
  snackBowl,
  wrapSandwich,
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
    final summary = '${food.name} ${food.ingredients.join(' ')}'.toLowerCase();

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
        summary.contains('milk')) {
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
      _MealArtKind.snackBowl || _MealArtKind.snackPack => _IconMealArtScene(
        icon: Icons.ramen_dining_rounded,
        accent: accent,
      ),
      _MealArtKind.wrapSandwich || _MealArtKind.sandwichPlate => _IconMealArtScene(
        icon: Icons.lunch_dining_rounded,
        accent: accent,
      ),
      _MealArtKind.steamedBowl || _MealArtKind.soupBread || _MealArtKind.saladBowl || _MealArtKind.riceBowl || _MealArtKind.proteinPlate || _MealArtKind.genericPlate => _IconMealArtScene(
        icon: Icons.restaurant_rounded,
        accent: accent,
      ),
      _MealArtKind.burgerCombo || _MealArtKind.wrapMeal || _MealArtKind.pizzaCombo => _IconMealArtScene(
        icon: Icons.restaurant_rounded, // Defaulting to plate for these complex scenes in icon mode
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
  const _IconMealArtScene({
    required this.icon,
    required this.accent,
  });

  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F0E8),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 24, // Icon size within the 48dp container
          color: const Color(0xFF1B4332),
        ),
      ),
    );
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
