import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../domain/entities/grocery.dart';
import '../../domain/repositories/grocery_catalog_repository.dart';
import 'grocery_api_config.dart';

class KrogerCatalogRepository implements GroceryCatalogRepository {
  KrogerCatalogRepository({
    required GroceryApiConfig config,
    http.Client? httpClient,
    DateTime Function()? clock,
  }) : _config = config,
       _httpClient = httpClient ?? http.Client(),
       _clock = clock ?? DateTime.now;

  final GroceryApiConfig _config;
  final http.Client _httpClient;
  final DateTime Function() _clock;

  _AccessToken? _cachedToken;

  @override
  GroceryRetailer get retailer => GroceryRetailer.kroger;

  @override
  bool get isConfigured => _config.isConfigured;

  @override
  Future<List<GroceryStore>> searchStores({
    required String postalCode,
    int limit = 8,
    int radiusMiles = 20,
  }) async {
    _requireConfiguration();
    final payload = await _getJson(
      '/locations',
      queryParameters: {
        'filter.zipCode.near': postalCode,
        'filter.limit': '$limit',
        'filter.radiusInMiles': '$radiusMiles',
      },
    );
    final rows = (payload['data'] as List<dynamic>? ?? const []);
    return rows.map(_mapStore).toList(growable: false);
  }

  @override
  Future<List<GroceryProduct>> searchProducts({
    required GroceryStore store,
    required String term,
    int limit = 12,
  }) async {
    _requireConfiguration();
    final payload = await _getJson(
      '/products',
      queryParameters: {
        'filter.term': term,
        'filter.locationId': store.locationId,
        'filter.limit': '$limit',
      },
    );
    final rows = (payload['data'] as List<dynamic>? ?? const []);
    return rows.map(_mapProduct).toList(growable: false);
  }

  Future<Map<String, dynamic>> _getJson(
    String path, {
    required Map<String, String> queryParameters,
  }) async {
    final accessToken = await _getAccessToken();
    final baseUri = Uri.parse(_config.apiBaseUrl);
    final uri = baseUri.replace(
      path: '${baseUri.path}$path',
      queryParameters: queryParameters,
    );
    final response = await _httpClient.get(
      uri,
      headers: {
        HttpHeaders.authorizationHeader: 'Bearer $accessToken',
        HttpHeaders.acceptHeader: 'application/json',
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GroceryCatalogException(
        'Kroger catalog request failed',
        statusCode: response.statusCode,
      );
    }

    return Map<String, dynamic>.from(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<String> _getAccessToken() async {
    final now = _clock().toUtc();
    final cachedToken = _cachedToken;
    if (cachedToken != null &&
        now.isBefore(
          cachedToken.expiresAt.subtract(const Duration(minutes: 1)),
        )) {
      return cachedToken.value;
    }

    final credentials = base64Encode(
      utf8.encode('${_config.clientId}:${_config.clientSecret}'),
    );
    final body = <String, String>{'grant_type': 'client_credentials'};
    if (_config.scopes.trim().isNotEmpty) {
      body['scope'] = _config.scopes.trim();
    }

    final response = await _httpClient.post(
      Uri.parse(_config.tokenUrl),
      headers: {
        HttpHeaders.authorizationHeader: 'Basic $credentials',
        HttpHeaders.acceptHeader: 'application/json',
        HttpHeaders.contentTypeHeader: 'application/x-www-form-urlencoded',
      },
      body: body,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GroceryCatalogException(
        'Kroger authentication failed',
        statusCode: response.statusCode,
      );
    }

    final payload = Map<String, dynamic>.from(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
    final accessToken = payload['access_token'] as String?;
    final expiresInSeconds = (payload['expires_in'] as num?)?.toInt() ?? 0;
    if (accessToken == null || accessToken.isEmpty) {
      throw const GroceryCatalogException(
        'Kroger authentication returned no access token',
      );
    }

    _cachedToken = _AccessToken(
      value: accessToken,
      expiresAt: now.add(Duration(seconds: expiresInSeconds)),
    );
    return accessToken;
  }

  GroceryStore _mapStore(dynamic row) {
    final map = Map<String, dynamic>.from(row as Map);
    final address = Map<String, dynamic>.from(
      map['address'] as Map? ?? const {},
    );
    return GroceryStore(
      retailer: GroceryRetailer.kroger,
      locationId: map['locationId'] as String? ?? '',
      name: map['name'] as String? ?? 'Kroger',
      addressLine1: address['addressLine1'] as String? ?? '',
      city: address['city'] as String? ?? '',
      state: address['state'] as String? ?? '',
      postalCode: address['zipCode'] as String? ?? '',
      phone: map['phone'] as String?,
      distanceMiles: (map['distance'] as num?)?.toDouble(),
    );
  }

  GroceryProduct _mapProduct(dynamic row) {
    final map = Map<String, dynamic>.from(row as Map);
    final items = (map['items'] as List<dynamic>? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
    final pricedItems = items.where(
      (item) =>
          item['price'] is Map &&
          ((item['price'] as Map)['regular'] != null ||
              (item['price'] as Map)['promo'] != null),
    );
    final bestItem = pricedItems.isNotEmpty
        ? pricedItems.reduce((best, current) {
            final bestPrice = _effectivePrice(best);
            final currentPrice = _effectivePrice(current);
            if (bestPrice == null) {
              return current;
            }
            if (currentPrice == null) {
              return best;
            }
            return currentPrice < bestPrice ? current : best;
          })
        : items.isEmpty
        ? null
        : items.first;
    final aisleLocations = (map['aisleLocations'] as List<dynamic>? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
    final images = (map['images'] as List<dynamic>? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
    final price = bestItem?['price'] is Map
        ? Map<String, dynamic>.from(bestItem!['price'] as Map)
        : const <String, dynamic>{};

    return GroceryProduct(
      retailer: GroceryRetailer.kroger,
      productId: map['productId'] as String? ?? map['upc'] as String? ?? '',
      description: map['description'] as String? ?? '',
      brand: map['brand'] as String? ?? '',
      size: bestItem?['size'] as String?,
      regularPrice: (price['regular'] as num?)?.toDouble(),
      promoPrice: (price['promo'] as num?)?.toDouble(),
      aisle: _formatAisle(aisleLocations),
      imageUrl: _imageUrl(images),
      availableInStore: _availableInStore(bestItem),
    );
  }

  double? _effectivePrice(Map<String, dynamic> item) {
    final price = item['price'] is Map
        ? Map<String, dynamic>.from(item['price'] as Map)
        : const <String, dynamic>{};
    return (price['promo'] as num?)?.toDouble() ??
        (price['regular'] as num?)?.toDouble();
  }

  bool _availableInStore(Map<String, dynamic>? item) {
    if (item == null) {
      return true;
    }
    final fulfillment = item['fulfillment'] is Map
        ? Map<String, dynamic>.from(item['fulfillment'] as Map)
        : const <String, dynamic>{};
    final inStore = fulfillment['inStore'] as bool?;
    return inStore ?? true;
  }

  String? _formatAisle(List<Map<String, dynamic>> aisles) {
    if (aisles.isEmpty) {
      return null;
    }
    final aisle = aisles.first;
    final description = aisle['description'] as String?;
    final number = aisle['number']?.toString();
    if (description != null && description.isNotEmpty) {
      return number == null || number.isEmpty
          ? description
          : '$description ($number)';
    }
    return number;
  }

  String? _imageUrl(List<Map<String, dynamic>> images) {
    for (final image in images) {
      final sizes = (image['sizes'] as List<dynamic>? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(growable: false);
      for (final size in sizes) {
        final url = size['url'] as String?;
        if (url != null && url.isNotEmpty) {
          return url;
        }
      }
    }
    return null;
  }

  void _requireConfiguration() {
    if (!isConfigured) {
      throw const GroceryCatalogException(
        'Kroger credentials are not configured for this build',
      );
    }
  }
}

class _AccessToken {
  const _AccessToken({required this.value, required this.expiresAt});

  final String value;
  final DateTime expiresAt;
}
