import '../entities/food.dart';
import '../value_objects/availability_context.dart';
import '../value_objects/meal_type.dart';

class SourceContentModel {
  const SourceContentModel();

  double fitForFood(Food food, AvailabilityContext source) {
    final staple = looksLikeStaple(food);
    final readyMeal = looksLikeReadyMeal(food);
    final quickGrab = _looksLikeQuickGrab(food);
    final shelfStable = _looksLikeShelfStable(food);
    final fresh = _looksLikeFresh(food);
    final produceOrBread = _looksLikeProduceOrBread(food);
    final storePreparedMeal = _looksLikeStorePreparedMeal(food);

    var score = switch (source) {
      AvailabilityContext.foodPantry => 0.34,
      AvailabilityContext.dollarStore => 0.4,
      AvailabilityContext.convenience => 0.36,
      AvailabilityContext.grocery => 0.72,
      AvailabilityContext.fastFood => 0.14,
    };

    switch (source) {
      case AvailabilityContext.foodPantry:
        if (staple) {
          score += 0.26;
        }
        if (shelfStable) {
          score += 0.16;
        }
        if (produceOrBread) {
          score += 0.12;
        }
        if (readyMeal && !shelfStable) {
          score -= 0.18;
        }
        if (food.category == 'prepared_meal') {
          score -= 0.12;
        }
        if (storePreparedMeal) {
          score -= 0.24;
        }
        break;
      case AvailabilityContext.dollarStore:
        if (staple) {
          score += 0.18;
        }
        if (shelfStable) {
          score += 0.2;
        }
        if (quickGrab) {
          score += 0.06;
        }
        if (fresh && !produceOrBread) {
          score -= 0.1;
        }
        if (food.category == 'prepared_meal' && !shelfStable) {
          score -= 0.14;
        }
        if (storePreparedMeal) {
          score -= 0.14;
        }
        break;
      case AvailabilityContext.convenience:
        if (quickGrab) {
          score += 0.26;
        }
        if (readyMeal) {
          score += 0.12;
        }
        if (food.prepTimeMin > 5) {
          score -= 0.18;
        }
        if (staple && !quickGrab && !shelfStable) {
          score -= 0.12;
        }
        if (fresh && !quickGrab) {
          score -= 0.12;
        }
        break;
      case AvailabilityContext.grocery:
        if (fresh) {
          score += 0.12;
        }
        if (staple) {
          score += 0.08;
        }
        if (food.category == 'prepared_meal') {
          score += 0.08;
        }
        if (storePreparedMeal) {
          score += 0.04;
        }
        break;
      case AvailabilityContext.fastFood:
        if (readyMeal) {
          score += 0.24;
        }
        if (food.category == 'prepared_meal') {
          score += 0.18;
        }
        if (shelfStable || staple) {
          score -= 0.22;
        }
        if (food.prepTimeMin > 5) {
          score -= 0.08;
        }
        break;
    }

    if (food.costEstimate >= 6.5 &&
        source != AvailabilityContext.grocery &&
        source != AvailabilityContext.fastFood) {
      score -= 0.05;
    }

    return score.clamp(0.08, 0.98).toDouble();
  }

  bool plausibleFitForFood(Food food, AvailabilityContext source) {
    return fitForFood(food, source) >= 0.42;
  }

  bool strongFitForFood(Food food, AvailabilityContext source) {
    return fitForFood(food, source) >= 0.58;
  }

  bool looksLikeStaple(Food food) {
    return _stapleCategories.contains(food.category) ||
        food.ingredients.any(_stapleTokens.contains);
  }

  bool looksLikeReadyMeal(Food food) {
    if (food.readyToEat) {
      return true;
    }
    return food.category == 'prepared_meal' && food.prepTimeMin <= 5;
  }

  bool looksLikeMeal(Food food) {
    if (food.category == 'prepared_meal') {
      return true;
    }
    return food.mealTypes.contains(MealType.lunch) ||
        food.mealTypes.contains(MealType.dinner);
  }

  bool _looksLikeQuickGrab(Food food) {
    return food.readyToEat ||
        food.prepTimeMin <= 5 ||
        food.mealTypes.contains(MealType.snack) ||
        food.mealTypes.contains(MealType.breakfast) ||
        food.ingredients.any(_quickGrabTokens.contains);
  }

  bool _looksLikeShelfStable(Food food) {
    return _shelfStableCategories.contains(food.category) ||
        food.ingredients.any(_shelfStableTokens.contains);
  }

  bool _looksLikeFresh(Food food) {
    return _freshCategories.contains(food.category) ||
        food.ingredients.any(_freshTokens.contains);
  }

  bool _looksLikeProduceOrBread(Food food) {
    return _produceBreadCategories.contains(food.category) ||
        food.ingredients.any(_produceBreadTokens.contains);
  }

  bool _looksLikeStorePreparedMeal(Food food) {
    return food.category == 'prepared_meal' &&
        food.ingredients.any(_storePreparedTokens.contains);
  }

  static const Set<String> _stapleCategories = {
    'grain_whole',
    'legume',
    'dairy',
    'fruit',
    'vegetable_starchy',
  };

  static const Set<String> _shelfStableCategories = {
    'grain_whole',
    'legume',
    'snack',
  };

  static const Set<String> _freshCategories = {
    'fruit',
    'protein_animal',
    'dairy',
    'vegetable_starchy',
  };

  static const Set<String> _produceBreadCategories = {
    'fruit',
    'vegetable_starchy',
  };

  static const Set<String> _stapleTokens = {
    'beans',
    'bread',
    'cereal',
    'eggs',
    'milk',
    'oats',
    'pasta',
    'peanut',
    'potato',
    'ramen',
    'rice',
    'soup',
    'tortilla',
    'tuna',
    'yogurt',
  };

  static const Set<String> _shelfStableTokens = {
    'beans',
    'cereal',
    'crackers',
    'oats',
    'pasta',
    'peanut',
    'ramen',
    'rice',
    'soup',
    'tortilla',
    'tuna',
  };

  static const Set<String> _freshTokens = {
    'apple',
    'banana',
    'broccoli',
    'carrot',
    'cheese',
    'chicken',
    'egg',
    'greens',
    'lettuce',
    'milk',
    'orange',
    'potato',
    'salad',
    'spinach',
    'tomato',
    'yogurt',
  };

  static const Set<String> _produceBreadTokens = {
    'apple',
    'banana',
    'bread',
    'carrot',
    'greens',
    'lettuce',
    'orange',
    'potato',
    'tomato',
  };

  static const Set<String> _quickGrabTokens = {
    'bar',
    'bowl',
    'burrito',
    'combo',
    'crackers',
    'cup',
    'deli',
    'sandwich',
    'snack',
    'soup',
    'wrap',
    'yogurt',
  };

  static const Set<String> _storePreparedTokens = {
    'bowl',
    'burrito',
    'combo',
    'deli',
    'salad',
    'sandwich',
    'wrap',
  };
}
