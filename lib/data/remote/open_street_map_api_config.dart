class OpenStreetMapApiConfig {
  const OpenStreetMapApiConfig({
    required this.nominatimBaseUrl,
    required this.overpassBaseUrl,
    required this.userAgent,
  });

  factory OpenStreetMapApiConfig.fromEnvironment() {
    return const OpenStreetMapApiConfig(
      nominatimBaseUrl: String.fromEnvironment(
        'OSM_NOMINATIM_BASE_URL',
        defaultValue: 'https://nominatim.openstreetmap.org',
      ),
      overpassBaseUrl: String.fromEnvironment(
        'OSM_OVERPASS_BASE_URL',
        defaultValue: 'https://overpass-api.de/api/interpreter',
      ),
      userAgent: String.fromEnvironment(
        'OSM_HTTP_USER_AGENT',
        defaultValue: 'AccessPlate prototype demo',
      ),
    );
  }

  final String nominatimBaseUrl;
  final String overpassBaseUrl;
  final String userAgent;

  bool get isConfigured =>
      nominatimBaseUrl.trim().isNotEmpty &&
      overpassBaseUrl.trim().isNotEmpty &&
      userAgent.trim().isNotEmpty;
}
