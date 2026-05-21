enum GroceryRetailer {
  kroger('kroger', 'Kroger');

  const GroceryRetailer(this.code, this.label);

  final String code;
  final String label;

  static GroceryRetailer fromCode(String code) {
    return values.firstWhere(
      (value) => value.code == code,
      orElse: () => GroceryRetailer.kroger,
    );
  }
}

class GroceryStore {
  const GroceryStore({
    required this.retailer,
    required this.locationId,
    required this.name,
    required this.addressLine1,
    required this.city,
    required this.state,
    required this.postalCode,
    this.phone,
    this.distanceMiles,
  });

  final GroceryRetailer retailer;
  final String locationId;
  final String name;
  final String addressLine1;
  final String city;
  final String state;
  final String postalCode;
  final String? phone;
  final double? distanceMiles;

  String get addressLabel {
    final suffix = '$city, $state $postalCode'.trim();
    if (addressLine1.isEmpty) {
      return suffix;
    }
    return '$addressLine1, $suffix';
  }

  String get shortLabel => '$name, $city';

  Map<String, dynamic> toJson() {
    return {
      'retailer': retailer.code,
      'locationId': locationId,
      'name': name,
      'addressLine1': addressLine1,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'phone': phone,
      'distanceMiles': distanceMiles,
    };
  }

  factory GroceryStore.fromJson(Map<String, dynamic> json) {
    return GroceryStore(
      retailer: GroceryRetailer.fromCode(
        json['retailer'] as String? ?? GroceryRetailer.kroger.code,
      ),
      locationId: json['locationId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      addressLine1: json['addressLine1'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      postalCode: json['postalCode'] as String? ?? '',
      phone: json['phone'] as String?,
      distanceMiles: (json['distanceMiles'] as num?)?.toDouble(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is GroceryStore &&
        other.retailer == retailer &&
        other.locationId == locationId;
  }

  @override
  int get hashCode => Object.hash(retailer, locationId);
}

class GroceryProduct {
  const GroceryProduct({
    required this.retailer,
    required this.productId,
    required this.description,
    required this.brand,
    this.size,
    this.regularPrice,
    this.promoPrice,
    this.aisle,
    this.imageUrl,
    this.availableInStore = true,
  });

  final GroceryRetailer retailer;
  final String productId;
  final String description;
  final String brand;
  final String? size;
  final double? regularPrice;
  final double? promoPrice;
  final String? aisle;
  final String? imageUrl;
  final bool availableInStore;

  double? get effectivePrice => promoPrice ?? regularPrice;

  String get brandLabel => brand.isEmpty ? 'Unspecified brand' : brand;
}

class GrocerySearchPlan {
  const GrocerySearchPlan({
    required this.term,
    required this.displayLabel,
    required this.rationale,
    required this.exactMatch,
  });

  final String term;
  final String displayLabel;
  final String rationale;
  final bool exactMatch;
}

class GroceryProductLookup {
  const GroceryProductLookup({
    required this.foodId,
    required this.foodName,
    required this.store,
    required this.plan,
    required this.products,
  });

  final int foodId;
  final String foodName;
  final GroceryStore store;
  final GrocerySearchPlan plan;
  final List<GroceryProduct> products;

  double? get cheapestPrice {
    final priced = products
        .map((product) => product.effectivePrice)
        .whereType<double>()
        .toList(growable: false);
    if (priced.isEmpty) {
      return null;
    }
    priced.sort();
    return priced.first;
  }
}

class GroceryCatalogException implements Exception {
  const GroceryCatalogException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() {
    if (statusCode == null) {
      return message;
    }
    return '$message (status $statusCode)';
  }
}
