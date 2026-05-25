import '../../domain/entities/demographics.dart';
import '../../domain/value_objects/allergen.dart';
import '../../domain/value_objects/availability_context.dart';
import '../../domain/value_objects/dietary_style.dart';
import '../../domain/value_objects/medical_restriction.dart';
import '../../domain/value_objects/meal_type.dart';
import '../../domain/value_objects/prep_environment.dart';
import '../../domain/value_objects/religion.dart';
import '../../domain/value_objects/transportation_mode.dart';
import '../../domain/value_objects/user_language.dart';

class AppCopy {
  const AppCopy(this.language);

  final UserLanguage language;

  bool get _es => language == UserLanguage.spanish;

  String choose(String english, String spanish) => _es ? spanish : english;

  String get summaryTitle => choose('Today snapshot', 'Panorama de hoy');
  String get summarySubtitle => choose(
    'Best food access choices for right now.',
    'Las mejores opciones de acceso a comida para ahorita.',
  );
  String get settingsTitle => choose('Settings', 'Ajustes');
  String get accessLanguageTitle =>
      choose('Language and access', 'Idioma y acceso');
  String get accessLanguageSubtitle => choose(
    'Change reading language and keep explanations direct when the day is busy.',
    'Cambia el idioma y manten explicaciones directas cuando el dia esta pesado.',
  );
  String get languageSettingLabel => choose('Language', 'Idioma');
  String get plainLanguageSettingTitle =>
      choose('Plain-language explanations', 'Explicaciones en lenguaje simple');
  String get plainLanguageSettingSubtitle => choose(
    'Keep the plan short, direct, and easier to scan.',
    'Mantiene el plan corto, directo y facil de revisar.',
  );
  String get todayPlanTitle => choose('Today plan', 'Plan de hoy');
  String get todayPlanSubtitle => choose(
    'A concrete next step built from what you have, what you can reach, and what you can afford.',
    'Un siguiente paso concreto basado en lo que tienes, lo que puedes alcanzar y lo que puedes pagar.',
  );
  String get sourceTripTitle =>
      choose('Best first stop', 'Mejor primera parada');
  String get sourceTripSubtitle => choose(
    'Where to go first based on travel burden, bundled ZIP access modeling, and what you need today.',
    'A donde ir primero segun la carga del viaje, el modelo ZIP incluido y lo que necesitas hoy.',
  );
  String get basketTitle => choose('Meal baskets', 'Canastas de comida');
  String get basketSubtitle => choose(
    'Low-cost combinations built around pantry food plus the fewest add-ons.',
    'Combinaciones de bajo costo hechas alrededor de tu despensa y pocos extras.',
  );
  String get recommendationsTitle =>
      choose('Reachable food options', 'Opciones de comida alcanzables');
  String get recommendationsSubtitle => choose(
    'Use from home first, then compare safe buys you can actually reach.',
    'Usa primero lo de casa y luego compara compras seguras que si puedes alcanzar.',
  );
  String get splashTitle => choose(
    'Choose the safest,\ncheapest meal you can\nactually reach today.',
    'Elige la comida mas segura,\nbarata y alcanzable para hoy.',
  );
  String get splashSubtitle => choose(
    'AccessPlate helps you decide what to use from home, what to buy first, and where to go first when money, travel, and cooking setup are tight.',
    'AccessPlate te ayuda a decidir que usar de casa, que comprar primero y a donde ir primero cuando el dinero, el viaje y la cocina estan limitados.',
  );
  String get splashAccessTitle => choose('Real-world access', 'Acceso real');
  String get splashAccessDetail => choose(
    'Pantry food, benefits, travel limits, and low-resource food sources shape every decision directly.',
    'La despensa, los beneficios, los limites de viaje y las fuentes de comida de bajos recursos cambian cada decision.',
  );
  String get splashExplainableTitle => choose('Explainable', 'Explicable');
  String get splashExplainableDetail => choose(
    'Each plan shows why it fits today, what to buy first, and what tradeoffs still matter.',
    'Cada plan muestra por que sirve hoy, que comprar primero y que costos o limites siguen importando.',
  );
  String get splashLocalFirstTitle => choose('Local-first', 'Primero local');
  String get splashLocalFirstDetail => choose(
    'The app still works from saved foods when bandwidth is limited and keeps sensitive profile data local.',
    'La app sigue funcionando con comida guardada cuando hay poco internet y mantiene tus datos locales.',
  );
  String get splashLocalDataTitle =>
      choose('What stays local', 'Lo que se queda local');
  String get splashLocalDataDetail => choose(
    'Your profile stays on-device, and this version already combines offline food data, bundled low-resource access modeling, and optional live grocery matching.',
    'Tu perfil se queda en el telefono, y esta version ya combina datos de comida sin internet, acceso local modelado y comparacion opcional con tienda en vivo.',
  );
  String get accessSetupTitle =>
      choose('Daily access\nsetup', 'Acceso diario\ny apoyo');
  String get accessSetupSubtitle => choose(
    'Set the places, benefits, and travel limits that are actually realistic today.',
    'Ajusta lugares, beneficios y limites de viaje que si son reales hoy.',
  );
  String get pantryTitle =>
      choose('What do you\nalready have?', 'Que tienes\nen casa?');
  String get pantrySubtitle => choose(
    'AccessPlate can stretch foods you already have at home instead of assuming every meal starts from zero.',
    'AccessPlate puede estirar lo que ya tienes en casa en vez de asumir que cada comida empieza desde cero.',
  );
  String get pantryCommonItemsLabel =>
      choose('Common pantry items', 'Articulos comunes de despensa');
  String get pantryCycleHint => choose(
    'Tap once for have enough, again for running low, again for restock, and once more to remove it.',
    'Toca una vez para suficiente, otra para poco, otra para reponer y otra mas para quitarlo.',
  );
  String get pantryAddItemLabel =>
      choose('Add another item', 'Agregar otro articulo');
  String get pantryAddItemHint => choose('canned soup', 'sopa enlatada');
  String pantryTrackedLabel(int count) =>
      choose('Tracked: $count', 'Registrados: $count');
  String get pantryEnoughLabel => choose('Have enough', 'Tienes suficiente');
  String get pantryLowLabel => choose('Running low', 'Se esta acabando');
  String get pantryRestockLabel => choose('Restock soon', 'Reponer pronto');
  String get sourceTripBestForLabel => choose('Best for', 'Sirve mejor para');
  String sourceTripBackupStop(String sourceLabel) =>
      choose('Backup stop: $sourceLabel', 'Parada de respaldo: $sourceLabel');
  String get todayPlanRestockSoonLabel =>
      choose('Restock soon', 'Reponer pronto');
  String get todayPlanNextMealsLabel =>
      choose('Next 2 meals', 'Siguientes 2 comidas');
  String get todayPlanBuyFirstLabel => choose('Buy first', 'Compra primero');
  String get todayPlanIfMoneyLeftLabel =>
      choose('If money is left', 'Si sobra dinero');
  String get todayPlanSkipTightBudgetLabel => choose(
    'Skip first if budget gets tight',
    'Dejalo para despues si el dinero no alcanza',
  );
  String get todayPlanBuiltAroundLabel =>
      choose('Built around', 'Hecho alrededor de');
  String get todayPlanLeadOptionLabel =>
      choose('Lead option', 'Opcion principal');
  String get accessZipCodeLabel => choose('ZIP code', 'Codigo postal');
  String get accessZipFieldLabel =>
      choose('Home or usual shopping ZIP', 'Codigo postal de casa o compras');
  String get accessZipHelp => choose(
    'Used for local grocery lookup and bundled ZIP-based access realism.',
    'Se usa para la busqueda local de tiendas y el acceso realista por codigo postal.',
  );
  String get accessTransportationLabel =>
      choose('Transportation', 'Transporte');
  String accessTripTimeLabel(int minutes) => choose(
    'Trip time you can usually manage: $minutes min',
    'Tiempo de viaje que normalmente puedes manejar: $minutes min',
  );
  String get accessBenefitsModeLabel =>
      choose('Benefits and mode', 'Beneficios y modo');
  String get emergencyModeTitle =>
      choose('Emergency mode', 'Modo de emergencia');
  String get emergencyModeSubtitle => choose(
    'Push the engine toward the fastest, cheapest, easiest options when the day is falling apart.',
    'Empuja el motor hacia opciones mas rapidas, baratas y faciles cuando el dia se complica.',
  );
  String get dietaryStyleTitle => choose('Dietary\nstyle', 'Estilo de\ncomida');
  String get dietaryStyleSubtitle => choose(
    'Choose the eating style that should stay in place.',
    'Elige el estilo de comida que debe mantenerse.',
  );
  String dietaryStyleLabel(DietaryStyle style) {
    switch (style) {
      case DietaryStyle.unrestricted:
        return choose('No diet filter', 'Sin filtro de dieta');
      case DietaryStyle.vegetarian:
        return choose('Vegetarian', 'Vegetariano');
      case DietaryStyle.vegan:
        return choose('Vegan', 'Vegano');
    }
  }

  String dietaryStyleDetail(DietaryStyle style) {
    switch (style) {
      case DietaryStyle.unrestricted:
        return choose(
          'Include foods that fit your safety and access settings.',
          'Incluye comida que si cumple con seguridad y acceso.',
        );
      case DietaryStyle.vegetarian:
        return choose(
          'Leave out meat, poultry, fish, and seafood.',
          'Deja fuera carne, pollo, pescado y mariscos.',
        );
      case DietaryStyle.vegan:
        return choose(
          'Leave out all animal-based foods, including dairy and eggs.',
          'Deja fuera toda comida de origen animal, incluidos lacteos y huevo.',
        );
    }
  }

  String get mealTimingTitle => choose('Meal\ntiming', 'Momento de\ncomida');
  String get mealTimingSubtitle => choose(
    'Choose the kind of meal to focus on first.',
    'Elige el tipo de comida en que enfocarse primero.',
  );
  String mealTimingLabel(MealType mealType) {
    switch (mealType) {
      case MealType.breakfast:
        return choose('Breakfast', 'Desayuno');
      case MealType.lunch:
        return choose('Lunch', 'Almuerzo');
      case MealType.dinner:
        return choose('Dinner', 'Cena');
      case MealType.snack:
        return choose('Snack', 'Botana');
      case MealType.any:
        return choose('Any time', 'A cualquier hora');
    }
  }

  String mealTimingDetail(MealType mealType) {
    switch (mealType) {
      case MealType.breakfast:
        return choose(
          'Prioritize morning meals and breakfast-friendly options.',
          'Da prioridad a comidas de la manana y opciones de desayuno.',
        );
      case MealType.lunch:
        return choose(
          'Focus on midday meals and quick lunch picks.',
          'Enfoca comidas del mediodia y opciones rapidas para almuerzo.',
        );
      case MealType.dinner:
        return choose(
          'Favor more filling evening meals.',
          'Favorece comidas de la tarde o noche mas llenadoras.',
        );
      case MealType.snack:
        return choose(
          'Keep the shortlist centered on lighter snack options.',
          'Mantiene la lista en opciones ligeras para botana.',
        );
      case MealType.any:
        return choose(
          'Allow the engine to match options regardless of meal timing.',
          'Deja que el motor encuentre opciones sin importar la hora.',
        );
    }
  }

  String get cuisineTitle => choose('Cuisine\npreference', 'Tipo de\ncomida');
  String get cuisineSubtitle => choose(
    'This is a softer preference and can relax if the pool gets too small.',
    'Esta es una preferencia suave y se puede soltar si quedan muy pocas opciones.',
  );
  String get cuisineNoPreferenceTitle =>
      choose('No preference', 'Sin preferencia');
  String get cuisineNoPreferenceSubtitle => choose(
    'Do not favor one cuisine family.',
    'No favorecer un tipo de comida.',
  );
  String cuisineLabel(String cuisine) {
    switch (cuisine) {
      case 'mexican':
        return choose('Mexican', 'Mexicana');
      case 'mediterranean':
        return choose('Mediterranean', 'Mediterranea');
      case 'asian':
        return choose('Asian', 'Asiatica');
      case 'indian':
        return choose('Indian', 'India');
      case 'american':
        return choose('American', 'Americana');
      case 'italian':
        return choose('Italian', 'Italiana');
      default:
        return _labelize(cuisine);
    }
  }

  String cuisineDetail(String cuisine) {
    final label = cuisineLabel(cuisine).toLowerCase();
    return choose(
      'Favor $label options when possible.',
      'Favorece opciones de estilo $label cuando sea posible.',
    );
  }

  String get dislikesTitle =>
      choose('Disliked\ningredients', 'Ingredientes\nque no quieres');
  String get dislikesSubtitle => choose(
    'Only add ingredients you truly want excluded from the shortlist.',
    'Solo agrega ingredientes que de verdad quieres dejar fuera.',
  );
  String get dislikesFieldHint =>
      choose('Add one ingredient', 'Agrega un ingrediente');
  String get dislikesSectionLabel =>
      choose('Excluded ingredients', 'Ingredientes fuera');
  String get dislikesEmptyLabel =>
      choose('Nothing excluded yet.', 'Todavia no has quitado nada.');
  String get dislikesAddButton =>
      choose('Add ingredient', 'Agregar ingrediente');
  String get profileTitle => choose('Profile\ncontext', 'Contexto\ndel perfil');
  String get profileSubtitle => choose(
    'This helps the app watch for nutrition needs without ignoring access reality.',
    'Esto ayuda a ver necesidades nutricionales sin ignorar la realidad del acceso.',
  );
  String get profileSexLabel => choose('Sex', 'Sexo');
  String sexLabel(Sex sex) {
    switch (sex) {
      case Sex.female:
        return choose('Female', 'Mujer');
      case Sex.male:
        return choose('Male', 'Hombre');
    }
  }

  String ageLabel(int age) => choose('Age: $age', 'Edad: $age');
  String get healthPrioritiesLabel =>
      choose('Health priorities', 'Prioridades de salud');
  String healthConcernLabel(HealthConcern concern) {
    switch (concern) {
      case HealthConcern.anemia:
        return choose('Anemia', 'Anemia');
      case HealthConcern.pregnancy:
        return choose('Pregnancy', 'Embarazo');
      case HealthConcern.lactating:
        return choose('Lactating', 'Lactancia');
      case HealthConcern.boneDensity:
        return choose('Bone density', 'Salud osea');
      case HealthConcern.vegetarian:
        return choose('Vegetarian', 'Vegetariano');
      case HealthConcern.vegan:
        return choose('Vegan', 'Vegano');
      case HealthConcern.postoperative:
        return choose('Postoperative recovery', 'Recuperacion posoperatoria');
      case HealthConcern.hypertension:
        return choose('Hypertension', 'Hipertension');
    }
  }

  String get targetsTitle => choose('Meal\ntargets', 'Objetivos de\ncomida');
  String get targetsSubtitle => choose(
    'Pick a rough meal size, then set the balance as percentages instead of a fixed preset.',
    'Elige un tamano aproximado de comida y luego ajusta el balance con porcentajes.',
  );
  String get caloriesLabel => choose('Calories', 'Calorias');
  String get macroMixLabel =>
      choose('Macronutrient mix', 'Balance de macronutrientes');
  String get macroMixSubtitle => choose(
    'The three shares always add up to 100%.',
    'Las tres partes siempre suman 100%.',
  );
  String macroChipLabel(String label, double value) =>
      '$label ${value.round()}%';
  String get proteinLabel => choose('Protein', 'Proteina');
  String get carbsLabel => choose('Carbs', 'Carbohidratos');
  String get fatLabel => choose('Fat', 'Grasa');
  String get proteinShareLabel => choose('Protein share', 'Parte de proteina');
  String get carbShareLabel => choose('Carb share', 'Parte de carbohidratos');
  String macroSummary({
    required double proteinG,
    required double carbsG,
    required double fatG,
  }) => choose(
    'Derived targets: ${proteinG.toStringAsFixed(0)}g protein | ${carbsG.toStringAsFixed(0)}g carbs | ${fatG.toStringAsFixed(0)}g fat',
    'Objetivos resultantes: ${proteinG.toStringAsFixed(0)}g proteina | ${carbsG.toStringAsFixed(0)}g carbohidratos | ${fatG.toStringAsFixed(0)}g grasa',
  );
  String get fiberTargetLabel => choose('Fiber target', 'Meta de fibra');
  String transportDetail(String code) {
    switch (code) {
      case 'limited':
        return choose(
          'Best for pantry, corner-store, and near-home options.',
          'Mejor para despensa, tienda de esquina y opciones cerca de casa.',
        );
      case 'walk':
        return choose(
          'Favor shorter trips and fewer stops.',
          'Favorece viajes cortos y menos paradas.',
        );
      case 'transit':
        return choose(
          'Public transit is possible, but long detours still matter.',
          'El transporte publico ayuda, pero los desvios largos siguen pesando.',
        );
      case 'car':
        return choose(
          'Broader store access is realistic if the trip is worth it.',
          'Mas tiendas son posibles si el viaje vale la pena.',
        );
      default:
        return '';
    }
  }

  String transportationLabel(TransportationMode mode) {
    switch (mode) {
      case TransportationMode.limited:
        return choose('Very limited travel', 'Viaje muy limitado');
      case TransportationMode.walk:
        return choose('Walking', 'Caminando');
      case TransportationMode.transit:
        return choose('Bus or train', 'Bus o tren');
      case TransportationMode.car:
        return choose('Car access', 'Acceso a carro');
    }
  }

  String prepEnvironmentLabel(PrepEnvironment environment) {
    switch (environment) {
      case PrepEnvironment.none:
        return choose('No prep', 'Sin preparacion');
      case PrepEnvironment.microwave:
        return choose('Microwave only', 'Solo microondas');
      case PrepEnvironment.stoveTop:
        return choose('Stovetop + microwave', 'Estufa + microondas');
      case PrepEnvironment.fullKitchen:
        return choose('Full kitchen', 'Cocina completa');
    }
  }

  String prepEnvironmentDetail(PrepEnvironment environment) {
    switch (environment) {
      case PrepEnvironment.none:
        return choose(
          'Ready-to-eat foods only.',
          'Solo comida lista para comer.',
        );
      case PrepEnvironment.microwave:
        return choose(
          'Microwave meals and simple reheating.',
          'Comidas de microondas y recalentado simple.',
        );
      case PrepEnvironment.stoveTop:
        return choose(
          'Stovetop plus microwave meals.',
          'Comidas de estufa y microondas.',
        );
      case PrepEnvironment.fullKitchen:
        return choose(
          'All standard home cooking methods.',
          'Todos los metodos normales de cocina en casa.',
        );
    }
  }

  String availabilityDetail(AvailabilityContext source) {
    switch (source) {
      case AvailabilityContext.grocery:
        return choose(
          'Prepared foods, staples, and produce.',
          'Comida preparada, basicos y frutas o verduras.',
        );
      case AvailabilityContext.convenience:
        return choose(
          'Grab-and-go food and small essentials.',
          'Comida rapida para llevar y cosas basicas.',
        );
      case AvailabilityContext.fastFood:
        return choose(
          'Restaurant and drive-thru options.',
          'Opciones de restaurante y ventanilla.',
        );
      case AvailabilityContext.foodPantry:
        return choose(
          'Shelf-stable or donated basics.',
          'Basicos de anaquel o donados.',
        );
      case AvailabilityContext.dollarStore:
        return choose(
          'Low-cost pantry items and snacks.',
          'Basicos baratos de despensa y botanas.',
        );
    }
  }

  String allergenLabel(Allergen allergen) {
    switch (allergen) {
      case Allergen.peanut:
        return choose('Peanut', 'Cacahuate');
      case Allergen.treeNut:
        return choose('Tree nut', 'Nuez de arbol');
      case Allergen.dairy:
        return choose('Dairy / milk', 'Lacteos / leche');
      case Allergen.egg:
        return choose('Egg', 'Huevo');
      case Allergen.soy:
        return choose('Soy', 'Soya');
      case Allergen.wheat:
        return choose('Wheat', 'Trigo');
      case Allergen.gluten:
        return choose('Gluten', 'Gluten');
      case Allergen.fish:
        return choose('Fish', 'Pescado');
      case Allergen.shellfish:
        return choose('Shellfish', 'Mariscos');
      case Allergen.sesame:
        return choose('Sesame', 'Sesamo');
    }
  }

  String religionLabel(Religion religion) {
    switch (religion) {
      case Religion.none:
        return choose('No restriction', 'Sin restriccion');
      case Religion.halal:
        return 'Halal';
      case Religion.kosher:
        return 'Kosher';
      case Religion.hinduVeg:
        return choose('Hindu vegetarian', 'Vegetariano hindu');
      case Religion.jain:
        return 'Jain';
    }
  }

  String religionDetail(Religion religion) {
    switch (religion) {
      case Religion.none:
        return choose(
          'Do not apply religion-based food filtering.',
          'No aplicar filtros de religion a la comida.',
        );
      case Religion.halal:
        return choose(
          'Hide foods that conflict with halal rules.',
          'Oculta comida que choque con reglas halal.',
        );
      case Religion.kosher:
        return choose(
          'Hide foods that conflict with kosher rules.',
          'Oculta comida que choque con reglas kosher.',
        );
      case Religion.hinduVeg:
        return choose(
          'Keep picks vegetarian for Hindu users.',
          'Mantiene opciones vegetarianas para usuarios hinduistas.',
        );
      case Religion.jain:
        return choose(
          'Hide foods that conflict with Jain rules.',
          'Oculta comida que choque con reglas jainistas.',
        );
    }
  }

  String medicalRestrictionLabel(MedicalRestriction restriction) {
    switch (restriction) {
      case MedicalRestriction.diabetic:
        return choose('Diabetes-aware', 'Cuidado con diabetes');
      case MedicalRestriction.lowSodium:
        return choose('Low sodium', 'Bajo en sodio');
      case MedicalRestriction.lowPotassiumCkd:
        return choose('Low potassium (CKD)', 'Bajo en potasio (ERC)');
      case MedicalRestriction.hypertension:
        return choose('Hypertension', 'Hipertension');
    }
  }

  String languageChoiceLabel(UserLanguage language) {
    switch (language) {
      case UserLanguage.english:
        return choose('English', 'Ingles');
      case UserLanguage.spanish:
        return choose('Spanish', 'Espanol');
    }
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

  String _labelize(String value) {
    return value
        .split('_')
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }
}
