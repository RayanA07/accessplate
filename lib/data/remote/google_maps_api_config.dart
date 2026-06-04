class GoogleMapsApiConfig {
  const GoogleMapsApiConfig({
    required this.apiKey,
    required this.geocodingBaseUrl,
    required this.placesBaseUrl,
    required this.routesBaseUrl,
  });

  factory GoogleMapsApiConfig.fromEnvironment() {
    return const GoogleMapsApiConfig(
      apiKey: String.fromEnvironment('GOOGLE_MAPS_API_KEY'),
      geocodingBaseUrl: String.fromEnvironment(
        'GOOGLE_GEOCODING_BASE_URL',
        defaultValue: 'https://geocode.googleapis.com/v4',
      ),
      placesBaseUrl: String.fromEnvironment(
        'GOOGLE_PLACES_BASE_URL',
        defaultValue: 'https://places.googleapis.com/v1',
      ),
      routesBaseUrl: String.fromEnvironment(
        'GOOGLE_ROUTES_BASE_URL',
        defaultValue: 'https://routes.googleapis.com',
      ),
    );
  }

  final String apiKey;
  final String geocodingBaseUrl;
  final String placesBaseUrl;
  final String routesBaseUrl;

  bool get isConfigured => apiKey.trim().isNotEmpty;
}
