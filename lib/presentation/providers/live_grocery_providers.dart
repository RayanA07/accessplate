import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/grocery.dart';
import '../../domain/value_objects/availability_context.dart';
import 'app_bootstrap.dart';
import 'profile_controller.dart';
import 'recommendations_provider.dart';

final liveGroceryMatchesProvider =
    FutureProvider<Map<int, GroceryProductLookup>>((ref) async {
      final profile = await ref.watch(profileControllerProvider.future);
      final feasibility = profile.constraints.feasibility;
      final store = feasibility.groceryStore;
      if (store == null ||
          !feasibility.availability.contains(AvailabilityContext.grocery)) {
        return const {};
      }

      final bootstrap = await ref.watch(appBootstrapProvider.future);
      if (!bootstrap.groceryCatalogRepository.isConfigured) {
        return const {};
      }

      final result = await ref.watch(recommendationsProvider.future);
      return bootstrap.lookupLiveGroceryProductsUseCase.execute(
        store: store,
        foods: result.recommendations.map((item) => item.food),
      );
    });
