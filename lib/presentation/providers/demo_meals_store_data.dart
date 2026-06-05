import '../../domain/entities/store_search.dart';
import '../../domain/value_objects/availability_context.dart';

const demoMealsLocationLabel = '3758 W Madison St, Chicago, IL 60624';
const demoMealsStoresMatchedLine = '6 nearby stores matched.';

const demoMealsLocation = SearchLocation(
  kind: SearchLocationKind.address,
  label: demoMealsLocationLabel,
  latitude: 41.8800,
  longitude: -87.7190,
  verification: DataVerification.live,
  postalCode: '60624',
  query: demoMealsLocationLabel,
  detail: 'Static demo location for the meals screen',
);

const demoMealsMcDonalds = NearbyStore(
  placeId: 'demo-fast-food-mcdonalds',
  name: 'McDonald\'s',
  address: demoMealsLocationLabel,
  latitude: 41.8800,
  longitude: -87.7190,
  categories: {AvailabilityContext.fastFood},
  primaryCategory: AvailabilityContext.fastFood,
  discoveryVerification: DataVerification.live,
  travelMetric: TravelMetric(
    source: TravelMetricSource.liveRoute,
    distanceMiles: 0.2,
  ),
);

const demoMealsDollarGeneral = NearbyStore(
  placeId: 'demo-dollar-general',
  name: 'Dollar General',
  address: demoMealsLocationLabel,
  latitude: 41.8800,
  longitude: -87.7190,
  categories: {AvailabilityContext.dollarStore},
  primaryCategory: AvailabilityContext.dollarStore,
  discoveryVerification: DataVerification.live,
  travelMetric: TravelMetric(
    source: TravelMetricSource.liveRoute,
    distanceMiles: 0.4,
  ),
);

const demoMealsFamilyDollar = NearbyStore(
  placeId: 'demo-family-dollar',
  name: 'Family Dollar',
  address: demoMealsLocationLabel,
  latitude: 41.8800,
  longitude: -87.7190,
  categories: {AvailabilityContext.dollarStore},
  primaryCategory: AvailabilityContext.dollarStore,
  discoveryVerification: DataVerification.live,
  travelMetric: TravelMetric(
    source: TravelMetricSource.liveRoute,
    distanceMiles: 0.5,
  ),
);

const demoMealsAldi = NearbyStore(
  placeId: 'demo-aldi',
  name: 'Aldi',
  address: demoMealsLocationLabel,
  latitude: 41.8800,
  longitude: -87.7190,
  categories: {AvailabilityContext.grocery},
  primaryCategory: AvailabilityContext.grocery,
  discoveryVerification: DataVerification.live,
  travelMetric: TravelMetric(
    source: TravelMetricSource.liveRoute,
    distanceMiles: 0.7,
  ),
);

const demoMealsPopeyes = NearbyStore(
  placeId: 'demo-fast-food-popeyes',
  name: 'Popeyes',
  address: demoMealsLocationLabel,
  latitude: 41.8800,
  longitude: -87.7190,
  categories: {AvailabilityContext.fastFood},
  primaryCategory: AvailabilityContext.fastFood,
  discoveryVerification: DataVerification.live,
  travelMetric: TravelMetric(
    source: TravelMetricSource.liveRoute,
    distanceMiles: 0.3,
  ),
);

const demoMealsSevenEleven = NearbyStore(
  placeId: 'demo-7-eleven',
  name: '7-Eleven',
  address: demoMealsLocationLabel,
  latitude: 41.8800,
  longitude: -87.7190,
  categories: {AvailabilityContext.convenience},
  primaryCategory: AvailabilityContext.convenience,
  discoveryVerification: DataVerification.live,
  travelMetric: TravelMetric(
    source: TravelMetricSource.liveRoute,
    distanceMiles: 0.1,
  ),
);

const demoMealsNearbyStores = <NearbyStore>[
  demoMealsMcDonalds,
  demoMealsDollarGeneral,
  demoMealsFamilyDollar,
  demoMealsAldi,
  demoMealsPopeyes,
  demoMealsSevenEleven,
];

List<NearbyStore> demoMealsStoresForContext(AvailabilityContext context) {
  switch (context) {
    case AvailabilityContext.fastFood:
      return const [demoMealsMcDonalds, demoMealsPopeyes];
    case AvailabilityContext.dollarStore:
      return const [demoMealsDollarGeneral, demoMealsFamilyDollar];
    case AvailabilityContext.grocery:
    case AvailabilityContext.foodPantry:
      return const [demoMealsAldi];
    case AvailabilityContext.convenience:
      return const [demoMealsSevenEleven];
  }
}
