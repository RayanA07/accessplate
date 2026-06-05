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
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFF7F2E8), Color(0xFFF2ECE0), Color(0xFFEEE8DB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: NihPalette.borderSoft),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
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
                padding: const EdgeInsets.all(10),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.74),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: logo == null
                        ? Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                left: 16,
                                right: 16,
                                bottom: 6,
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: const Color(0x12000000),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                              _MealArtScene(kind: kind),
                            ],
                          )
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
  const _MealArtScene({required this.kind});

  final _MealArtKind kind;

  @override
  Widget build(BuildContext context) {
    return switch (kind) {
      _MealArtKind.burgerCombo => const Stack(
        children: [
          Positioned(left: 2, bottom: 8, child: _BurgerIllustration()),
          Positioned(right: 2, bottom: 10, child: _CupIllustration()),
        ],
      ),
      _MealArtKind.wrapMeal => const Stack(
        children: [
          Positioned(left: 0, bottom: 10, child: _WrapIllustration()),
          Positioned(right: 10, bottom: 14, child: _SauceCup()),
        ],
      ),
      _MealArtKind.soupBread => const Stack(
        children: [
          Positioned(left: 2, bottom: 10, child: _SoupIllustration()),
          Positioned(right: 0, bottom: 20, child: _BreadSlices()),
        ],
      ),
      _MealArtKind.breakfastCup => const Stack(
        children: [
          Positioned(left: 6, bottom: 8, child: _BreakfastCup()),
          Positioned(right: 6, bottom: 18, child: _BerryCluster()),
        ],
      ),
      _MealArtKind.saladBowl => const Stack(
        children: [
          Positioned(left: 2, bottom: 8, child: _SaladIllustration()),
          Positioned(right: 6, bottom: 18, child: _ForkAccent()),
        ],
      ),
      _MealArtKind.riceBowl => const Stack(
        children: [
          Positioned(left: 2, bottom: 8, child: _RiceBowlIllustration()),
          Positioned(right: 6, bottom: 18, child: _ForkAccent()),
        ],
      ),
      _MealArtKind.pizzaCombo => const Stack(
        children: [
          Positioned(left: 2, bottom: 10, child: _PizzaSliceIllustration()),
          Positioned(right: 2, bottom: 10, child: _CupIllustration()),
        ],
      ),
      _MealArtKind.sandwichPlate => const Stack(
        children: [
          Positioned(left: 0, bottom: 10, child: _SandwichIllustration()),
          Positioned(right: 6, bottom: 18, child: _FruitAccent()),
        ],
      ),
      _MealArtKind.snackPack => const Stack(
        children: [
          Positioned(left: 0, bottom: 10, child: _SnackPackIllustration()),
        ],
      ),
      _MealArtKind.proteinPlate => const Stack(
        children: [
          Positioned(left: 2, bottom: 8, child: _ProteinPlateIllustration()),
        ],
      ),
      _MealArtKind.genericPlate => const Stack(
        children: [
          Positioned(left: 2, bottom: 8, child: _RiceBowlIllustration()),
        ],
      ),
    };
  }
}

class _BurgerIllustration extends StatelessWidget {
  const _BurgerIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 56,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          _roundedLayer(
            width: 52,
            height: 14,
            color: const Color(0xFFCC8B3D),
            bottom: 0,
          ),
          _roundedLayer(
            width: 48,
            height: 8,
            color: const Color(0xFF6B4025),
            bottom: 11,
          ),
          _roundedLayer(
            width: 48,
            height: 6,
            color: const Color(0xFF6AB062),
            bottom: 17,
          ),
          _roundedLayer(
            width: 34,
            height: 5,
            color: const Color(0xFFEEC246),
            bottom: 22,
          ),
          _roundedLayer(
            width: 42,
            height: 6,
            color: const Color(0xFFD95A48),
            bottom: 26,
          ),
          Positioned(
            bottom: 31,
            child: Container(
              width: 50,
              height: 17,
              decoration: const BoxDecoration(
                color: Color(0xFFD9A24F),
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Positioned _roundedLayer({
    required double width,
    required double height,
    required Color color,
    required double bottom,
  }) {
    return Positioned(
      bottom: bottom,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _CupIllustration extends StatelessWidget {
  const _CupIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 58,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            top: 0,
            child: Container(
              width: 2,
              height: 18,
              color: const Color(0xFFB9B0A2),
            ),
          ),
          Positioned(
            top: 14,
            child: Container(
              width: 24,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFE4DACC)),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: Container(
              width: 22,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F0D9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE4DACC)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WrapIllustration extends StatelessWidget {
  const _WrapIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 66,
      height: 56,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: Transform.rotate(angle: -0.18, child: _wrapHalf()),
          ),
          Positioned(
            right: 0,
            bottom: 6,
            child: Transform.rotate(angle: 0.18, child: _wrapHalf()),
          ),
        ],
      ),
    );
  }

  Widget _wrapHalf() {
    return SizedBox(
      width: 34,
      height: 48,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            top: 2,
            child: Container(
              width: 24,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF6AB062),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            top: 8,
            child: Container(
              width: 20,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFD95A48),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: ClipPath(
              clipper: _TriangleClipper(),
              child: Container(
                width: 30,
                height: 38,
                color: const Color(0xFFF0D7A8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoupIllustration extends StatelessWidget {
  const _SoupIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      height: 48,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 0,
            child: Container(
              width: 54,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFE4DACC)),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            child: Container(
              width: 42,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFFCF7A4B),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const Positioned(top: 2, left: 18, child: _SteamLine()),
          const Positioned(top: 0, left: 28, child: _SteamLine()),
          const Positioned(top: 3, left: 38, child: _SteamLine()),
        ],
      ),
    );
  }
}

class _BreadSlices extends StatelessWidget {
  const _BreadSlices();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 34,
      child: Stack(
        children: [
          Positioned(
            left: 4,
            top: 2,
            child: _bread(color: const Color(0xFFE8BB73)),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: _bread(color: const Color(0xFFD9A860)),
          ),
        ],
      ),
    );
  }

  Widget _bread({required Color color}) {
    return Container(
      width: 20,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(10),
          bottom: Radius.circular(6),
        ),
      ),
    );
  }
}

class _BreakfastCup extends StatelessWidget {
  const _BreakfastCup();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 0,
            child: Container(
              width: 44,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE4DACC)),
              ),
            ),
          ),
          Positioned(
            bottom: 18,
            child: Container(
              width: 36,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFFE7D2A1),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const Positioned(
            bottom: 24,
            left: 16,
            child: _BerryCluster(compact: true),
          ),
        ],
      ),
    );
  }
}

class _BerryCluster extends StatelessWidget {
  const _BerryCluster({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final radius = compact ? 7.0 : 8.0;
    return SizedBox(
      width: compact ? 18 : 24,
      height: compact ? 16 : 22,
      child: Stack(
        children: [
          _berry(0, 8, radius, const Color(0xFF7D5AB5)),
          _berry(radius * 0.9, 0, radius, const Color(0xFFE55B6E)),
          _berry(radius * 1.8, 7, radius, const Color(0xFF648AD1)),
        ],
      ),
    );
  }

  Positioned _berry(double left, double top, double size, Color color) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _SaladIllustration extends StatelessWidget {
  const _SaladIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 50,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 0,
            child: Container(
              width: 56,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFE4DACC)),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            child: SizedBox(
              width: 48,
              height: 24,
              child: Stack(
                children: [
                  _leaf(4, 10, const Color(0xFF62A95E)),
                  _leaf(14, 4, const Color(0xFF7CCB76)),
                  _leaf(26, 10, const Color(0xFF58A35B)),
                  _leaf(12, 12, const Color(0xFFD95A48)),
                  _leaf(28, 4, const Color(0xFFE4C24D)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Positioned _leaf(double left, double top, Color color) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: 14,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _RiceBowlIllustration extends StatelessWidget {
  const _RiceBowlIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 66,
      height: 52,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 0,
            child: Container(
              width: 58,
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFFF7FBFF),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFE4DACC)),
              ),
            ),
          ),
          Positioned(
            bottom: 9,
            child: SizedBox(
              width: 50,
              height: 20,
              child: Stack(
                children: [
                  _grain(2, 6, const Color(0xFFE0C585)),
                  _grain(14, 2, const Color(0xFF6AB062)),
                  _grain(24, 8, const Color(0xFFD95A48)),
                  _grain(34, 4, const Color(0xFF7E5D32)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Positioned _grain(double left, double top, Color color) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: 14,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _PizzaSliceIllustration extends StatelessWidget {
  const _PizzaSliceIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        children: [
          Positioned(
            left: 4,
            top: 4,
            child: Transform.rotate(
              angle: -0.2,
              child: ClipPath(
                clipper: _TriangleClipper(),
                child: Container(
                  width: 38,
                  height: 42,
                  color: const Color(0xFFF2D690),
                ),
              ),
            ),
          ),
          Positioned(
            left: 2,
            top: 2,
            child: Transform.rotate(
              angle: -0.2,
              child: Container(
                width: 40,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFD38742),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          const Positioned(left: 14, top: 18, child: _PizzaToppings()),
        ],
      ),
    );
  }
}

class _PizzaToppings extends StatelessWidget {
  const _PizzaToppings();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 16,
      child: Stack(
        children: const [
          _TinyCircle(left: 0, top: 2, color: Color(0xFFD95A48)),
          _TinyCircle(left: 10, top: 0, color: Color(0xFF62A95E)),
          _TinyCircle(left: 14, top: 8, color: Color(0xFFD95A48)),
        ],
      ),
    );
  }
}

class _SandwichIllustration extends StatelessWidget {
  const _SandwichIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 50,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            bottom: 2,
            child: Transform.rotate(angle: -0.1, child: _sandwichHalf()),
          ),
          Positioned(
            right: 4,
            bottom: 8,
            child: Transform.rotate(angle: 0.16, child: _sandwichHalf()),
          ),
        ],
      ),
    );
  }

  Widget _sandwichHalf() {
    return SizedBox(
      width: 28,
      height: 34,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            top: 0,
            child: Container(
              width: 28,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFFE2BB79),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Positioned(
            top: 10,
            child: Container(
              width: 24,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFF6AB062),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            top: 14,
            child: Container(
              width: 22,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD95A48),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: Container(
              width: 28,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFFF0D6A5),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SnackPackIllustration extends StatelessWidget {
  const _SnackPackIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 56,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            bottom: 8,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Color(0xFFE7BB4A),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 18,
            bottom: 4,
            child: Container(
              width: 30,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFFF0D7A8),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 10,
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: List.generate(
                4,
                (_) => Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF9C6A3A),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProteinPlateIllustration extends StatelessWidget {
  const _ProteinPlateIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 54,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 0,
            child: Container(
              width: 62,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFE4DACC)),
              ),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 8,
            child: Container(
              width: 24,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFFA36940),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 10,
            child: Container(
              width: 20,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFF69B063),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SauceCup extends StatelessWidget {
  const _SauceCup();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 12,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE4DACC)),
      ),
      child: Center(
        child: Container(
          width: 10,
          height: 5,
          decoration: BoxDecoration(
            color: const Color(0xFFD95A48),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _ForkAccent extends StatelessWidget {
  const _ForkAccent();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.35,
      child: Icon(
        Icons.restaurant_rounded,
        color: NihPalette.grayDark.withValues(alpha: 0.72),
        size: 18,
      ),
    );
  }
}

class _FruitAccent extends StatelessWidget {
  const _FruitAccent();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: const BoxDecoration(
        color: Color(0xFFE5B45C),
        shape: BoxShape.circle,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: 3,
          height: 6,
          margin: const EdgeInsets.only(top: 1),
          color: Color(0xFF6B8E3E),
        ),
      ),
    );
  }
}

class _SteamLine extends StatelessWidget {
  const _SteamLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      height: 12,
      decoration: BoxDecoration(
        color: const Color(0xFFB8B0A6),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _TinyCircle extends StatelessWidget {
  const _TinyCircle({
    required this.left,
    required this.top,
    required this.color,
  });

  final double left;
  final double top;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
