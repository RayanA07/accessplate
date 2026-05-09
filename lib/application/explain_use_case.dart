import '../domain/entities/explanation.dart';
import '../domain/entities/recommendation.dart';

class ExplainUseCase {
  const ExplainUseCase();

  Explanation? execute(List<ScoredFood> recommendations, int foodId) {
    for (final recommendation in recommendations) {
      if (recommendation.food.id == foodId) {
        return recommendation.explanation;
      }
    }
    return null;
  }
}
