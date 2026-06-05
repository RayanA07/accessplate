/// Normalized merchant/brand identity used to separate a meal's *source brand*
/// (e.g. a Taco Bell menu item) from whatever happens to be the nearest place
/// in a category (e.g. Marco's Pizza).
///
/// A chain-specific fast-food meal can only ever be verified against a nearby
/// store with the same [key]; it must never be associated with a different
/// brand. This catalog is the single source of truth for brand keys, the
/// human-readable display name, and the normalized terms used to recognize a
/// brand from free-form OpenStreetMap `name`/`brand`/`operator` tags or from a
/// bundled meal name.
enum MerchantVenueType { fastFood, grocery }

class MerchantBrand {
  const MerchantBrand({
    required this.key,
    required this.displayName,
    required this.matchTerms,
    this.venueType = MerchantVenueType.fastFood,
  });

  /// Stable lowercase identifier, e.g. `taco_bell`.
  final String key;

  /// Human-readable label, e.g. `Taco Bell`.
  final String displayName;

  /// Already-normalized terms (lowercase, punctuation collapsed to single
  /// spaces) used to recognize this brand from text. Include common spelling
  /// variants, e.g. `mcdonald s` and `mcdonalds`.
  final List<String> matchTerms;

  final MerchantVenueType venueType;
}

class MerchantBrandCatalog {
  const MerchantBrandCatalog(this.brands);

  final List<MerchantBrand> brands;

  /// Collapses punctuation/whitespace so `"McDonald's #123"` and `"McDonalds"`
  /// both normalize toward the same comparable form.
  static String normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  MerchantBrand? brandForKey(String? key) {
    if (key == null || key.isEmpty) {
      return null;
    }
    for (final brand in brands) {
      if (brand.key == key) {
        return brand;
      }
    }
    return null;
  }

  /// Resolves a brand key from free-form text.
  ///
  /// When [requirePrefix] is true the text must *start* with a brand term — used
  /// for bundled meal names like `"Taco Bell Power Menu Bowl"` where the brand
  /// always leads. When false, a whole-word match anywhere is accepted — used
  /// for store `name`/`brand` tags like `"Taco Bell #4821"`.
  ///
  /// The longest matching term wins so a more specific brand is preferred. A
  /// `null` result means "no confident brand match" — callers must treat that
  /// as unverified rather than guessing.
  String? matchKey(String? text, {bool requirePrefix = false}) {
    if (text == null) {
      return null;
    }
    final normalized = normalize(text);
    if (normalized.isEmpty) {
      return null;
    }

    String? bestKey;
    var bestLength = 0;
    for (final brand in brands) {
      for (final term in brand.matchTerms) {
        if (term.isEmpty || term.length <= bestLength) {
          continue;
        }
        final matched = requirePrefix
            ? (normalized == term || normalized.startsWith('$term '))
            : _wordContains(normalized, term);
        if (matched) {
          bestKey = brand.key;
          bestLength = term.length;
        }
      }
    }
    return bestKey;
  }

  static bool _wordContains(String haystack, String needle) {
    if (haystack == needle) {
      return true;
    }
    if (haystack.startsWith('$needle ')) {
      return true;
    }
    if (haystack.endsWith(' $needle')) {
      return true;
    }
    return haystack.contains(' $needle ');
  }

  /// Bundled chains. The first ten cover every brand present in
  /// `assets/reference/fast_food_menus.json`; the rest let nearby-store
  /// discovery recognize other common chains so they are never mistaken for a
  /// brand-specific meal's required merchant.
  static const MerchantBrandCatalog defaults = MerchantBrandCatalog(<MerchantBrand>[
    MerchantBrand(
      key: 'mcdonalds',
      displayName: "McDonald's",
      matchTerms: ['mcdonald s', 'mcdonalds'],
    ),
    MerchantBrand(
      key: 'starbucks',
      displayName: 'Starbucks',
      matchTerms: ['starbucks'],
    ),
    MerchantBrand(
      key: 'chick_fil_a',
      displayName: 'Chick-fil-A',
      matchTerms: ['chick fil a'],
    ),
    MerchantBrand(
      key: 'taco_bell',
      displayName: 'Taco Bell',
      matchTerms: ['taco bell'],
    ),
    MerchantBrand(
      key: 'wendys',
      displayName: "Wendy's",
      matchTerms: ['wendy s', 'wendys'],
    ),
    MerchantBrand(
      key: 'dunkin',
      displayName: "Dunkin'",
      matchTerms: ['dunkin', 'dunkin donuts'],
    ),
    MerchantBrand(
      key: 'chipotle',
      displayName: 'Chipotle',
      matchTerms: ['chipotle'],
    ),
    MerchantBrand(
      key: 'burger_king',
      displayName: 'Burger King',
      matchTerms: ['burger king'],
    ),
    MerchantBrand(
      key: 'subway',
      displayName: 'Subway',
      matchTerms: ['subway'],
    ),
    MerchantBrand(
      key: 'dominos',
      displayName: "Domino's",
      matchTerms: ['domino s', 'dominos', 'domino s pizza'],
    ),
    // Additional chains recognized for nearby stores only (no bundled meals).
    MerchantBrand(key: 'kfc', displayName: 'KFC', matchTerms: ['kfc', 'kentucky fried chicken']),
    MerchantBrand(key: 'popeyes', displayName: 'Popeyes', matchTerms: ['popeyes']),
    MerchantBrand(key: 'pizza_hut', displayName: 'Pizza Hut', matchTerms: ['pizza hut']),
    MerchantBrand(key: 'marcos_pizza', displayName: "Marco's Pizza", matchTerms: ['marco s pizza', 'marcos pizza']),
    MerchantBrand(key: 'papa_johns', displayName: "Papa John's", matchTerms: ['papa john s', 'papa johns']),
    MerchantBrand(key: 'arbys', displayName: "Arby's", matchTerms: ['arby s', 'arbys']),
    MerchantBrand(key: 'sonic', displayName: 'Sonic', matchTerms: ['sonic drive in', 'sonic']),
    MerchantBrand(key: 'panera', displayName: 'Panera Bread', matchTerms: ['panera']),
    MerchantBrand(key: 'five_guys', displayName: 'Five Guys', matchTerms: ['five guys']),
    MerchantBrand(key: 'panda_express', displayName: 'Panda Express', matchTerms: ['panda express']),
    MerchantBrand(key: 'jack_in_the_box', displayName: 'Jack in the Box', matchTerms: ['jack in the box']),
    MerchantBrand(key: 'whataburger', displayName: 'Whataburger', matchTerms: ['whataburger']),
    MerchantBrand(key: 'in_n_out', displayName: 'In-N-Out', matchTerms: ['in n out']),
    MerchantBrand(key: 'dairy_queen', displayName: 'Dairy Queen', matchTerms: ['dairy queen']),
  ]);
}
