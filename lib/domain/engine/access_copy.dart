import '../entities/user_constraints.dart';
import '../value_objects/availability_context.dart';
import '../value_objects/user_language.dart';

class AccessCopy {
  const AccessCopy(this.access);

  final AccessConstraints access;

  bool get isSpanish => access.language == UserLanguage.spanish;
  bool get plain => access.plainLanguage;

  String choose(
    String english,
    String spanish, {
    String? englishDetailed,
    String? spanishDetailed,
  }) {
    if (!plain && englishDetailed != null && spanishDetailed != null) {
      return isSpanish ? spanishDetailed : englishDetailed;
    }
    return isSpanish ? spanish : english;
  }

  String sourceLabel(AvailabilityContext source) {
    switch (source) {
      case AvailabilityContext.grocery:
        return choose('Grocery store', 'Tienda de comestibles');
      case AvailabilityContext.convenience:
        return choose('Convenience store', 'Tienda pequena');
      case AvailabilityContext.fastFood:
        return choose('Fast food', 'Comida rapida');
      case AvailabilityContext.foodPantry:
        return choose('Food pantry', 'Despensa de alimentos');
      case AvailabilityContext.dollarStore:
        return choose('Dollar store', 'Tienda de dolar');
    }
  }

  String lowerSourceLabel(AvailabilityContext source) {
    return sourceLabel(source).toLowerCase();
  }
}
