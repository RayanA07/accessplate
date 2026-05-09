import '../domain/engine/decision_engine.dart';
import '../domain/entities/recommendation.dart';
import '../domain/entities/user_profile.dart';

class RecommendUseCase {
  RecommendUseCase(this._engine);

  final DecisionEngine _engine;

  Future<RecommendationResult> execute(UserProfile profile) {
    return _engine.recommend(
      user: profile.constraints,
      weights: profile.scoringWeights,
    );
  }
}
