import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/recommendation.dart';
import 'app_bootstrap.dart';
import 'profile_controller.dart';

final recommendationsProvider = FutureProvider<RecommendationResult>((
  ref,
) async {
  final bootstrap = await ref.watch(appBootstrapProvider.future);
  final profile = await ref.watch(profileControllerProvider.future);
  return bootstrap.recommendUseCase.execute(profile);
});
