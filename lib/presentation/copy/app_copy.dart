import '../../domain/value_objects/user_language.dart';

class AppCopy {
  const AppCopy(this.language);

  final UserLanguage language;

  bool get _es => language == UserLanguage.spanish;

  String choose(String english, String spanish) => _es ? spanish : english;

  String get summaryTitle => choose('Summary', 'Resumen');
  String get summarySubtitle =>
      choose('Your current meal snapshot.', 'Tu panorama actual de comida.');
  String get todayPlanTitle => choose('Today plan', 'Plan de hoy');
  String get todayPlanSubtitle => choose(
    'A concrete next step built from your budget, access, and top matches.',
    'Un siguiente paso concreto basado en tu presupuesto, acceso y mejores opciones.',
  );
  String get basketTitle => choose('Meal baskets', 'Canastas de comida');
  String get basketSubtitle => choose(
    'Practical one-stop combinations built from the current shortlist.',
    'Combinaciones practicas de una sola parada hechas con la lista actual.',
  );
  String get recommendationsTitle =>
      choose('Recommended for now', 'Recomendado ahora');
  String get recommendationsSubtitle => choose(
    'Safe, feasible picks ordered by fit, quality, and tradeoffs.',
    'Opciones seguras y viables ordenadas por ajuste, calidad y concesiones.',
  );
  String get accessSetupTitle =>
      choose('Daily access\nsetup', 'Acceso diario\ny apoyo');
  String get accessSetupSubtitle => choose(
    'Ground recommendations in the places, benefits, and travel limits that are actually realistic today.',
    'Ajusta recomendaciones segun lugares, beneficios y limites de viaje que si son reales hoy.',
  );
  String get pantryTitle =>
      choose('What do you\nalready have?', 'Que tienes\nen casa?');
  String get pantrySubtitle => choose(
    'AccessPlate can stretch foods you already have at home instead of assuming every meal starts from zero.',
    'AccessPlate puede estirar lo que ya tienes en casa en vez de asumir que cada comida empieza desde cero.',
  );
}
