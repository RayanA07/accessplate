class GroceryApiConfig {
  const GroceryApiConfig({
    required this.clientId,
    required this.clientSecret,
    required this.scopes,
    required this.apiBaseUrl,
    required this.tokenUrl,
  });

  factory GroceryApiConfig.fromEnvironment() {
    return const GroceryApiConfig(
      clientId: String.fromEnvironment('KROGER_CLIENT_ID'),
      clientSecret: String.fromEnvironment('KROGER_CLIENT_SECRET'),
      scopes: String.fromEnvironment('KROGER_SCOPES'),
      apiBaseUrl: String.fromEnvironment(
        'KROGER_API_BASE_URL',
        defaultValue: 'https://api.kroger.com/v1',
      ),
      tokenUrl: String.fromEnvironment(
        'KROGER_TOKEN_URL',
        defaultValue: 'https://api.kroger.com/v1/connect/oauth2/token',
      ),
    );
  }

  final String clientId;
  final String clientSecret;
  final String scopes;
  final String apiBaseUrl;
  final String tokenUrl;

  bool get isConfigured => clientId.isNotEmpty && clientSecret.isNotEmpty;
}
