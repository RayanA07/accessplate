import '../value_objects/availability_context.dart';
import '../value_objects/transportation_mode.dart';

enum LocalAccessMatchType { exact, prefix, fallback }

enum CommunityAccessType {
  denseUrban('dense_urban'),
  innerNeighborhood('inner_neighborhood'),
  autoSpread('auto_spread'),
  suburban('suburban'),
  ruralTown('rural_town');

  const CommunityAccessType(this.code);

  final String code;

  static CommunityAccessType fromCode(String? code) {
    return CommunityAccessType.values.firstWhere(
      (value) => value.code == code,
      orElse: () => CommunityAccessType.innerNeighborhood,
    );
  }
}

class SourceAccessSnapshot {
  const SourceAccessSnapshot({
    required this.nearbyOptions,
    required this.typicalTravelMinutes,
    required this.sameDayConfidence,
    this.note,
  });

  final int nearbyOptions;
  final int typicalTravelMinutes;
  final double sameDayConfidence;
  final String? note;

  factory SourceAccessSnapshot.fromJson(Map<String, dynamic> json) {
    return SourceAccessSnapshot(
      nearbyOptions: (json['nearbyOptions'] as num?)?.toInt() ?? 0,
      typicalTravelMinutes:
          (json['typicalTravelMinutes'] as num?)?.toInt() ?? 0,
      sameDayConfidence: (json['sameDayConfidence'] as num?)?.toDouble() ?? 0.0,
      note: json['note'] as String?,
    );
  }
}

class LocalAccessProfile {
  const LocalAccessProfile({
    required this.profileId,
    required this.label,
    required this.communityLabel,
    this.stateCode,
    required this.lowAccessArea,
    required this.communityType,
    required this.walkSupport,
    required this.transitSupport,
    required this.groceryGapSeverity,
    required this.sources,
    this.notes,
  });

  final String profileId;
  final String label;
  final String communityLabel;
  final String? stateCode;
  final bool lowAccessArea;
  final CommunityAccessType communityType;
  final double walkSupport;
  final double transitSupport;
  final double groceryGapSeverity;
  final Map<AvailabilityContext, SourceAccessSnapshot> sources;
  final String? notes;

  double get sourceCoverageRatio =>
      (sources.length / AvailabilityContext.values.length)
          .clamp(0.0, 1.0)
          .toDouble();

  SourceAccessSnapshot? sourceFor(AvailabilityContext context) {
    return sources[context];
  }

  double transportSupportFor(TransportationMode mode) {
    return switch (mode) {
      TransportationMode.limited =>
        (walkSupport * 0.82).clamp(0.0, 1.0).toDouble(),
      TransportationMode.walk => walkSupport.clamp(0.0, 1.0).toDouble(),
      TransportationMode.transit => transitSupport.clamp(0.0, 1.0).toDouble(),
      TransportationMode.car => 0.95,
    };
  }

  double sourceFitFor(AvailabilityContext source, TransportationMode mode) {
    var fit = transportSupportFor(mode);

    switch (source) {
      case AvailabilityContext.foodPantry:
        fit += lowAccessArea ? 0.10 : 0.04;
      case AvailabilityContext.dollarStore:
        fit += lowAccessArea ? 0.08 : 0.03;
      case AvailabilityContext.convenience:
        fit +=
            communityType == CommunityAccessType.denseUrban ||
                communityType == CommunityAccessType.innerNeighborhood
            ? 0.12
            : 0.05;
      case AvailabilityContext.fastFood:
        fit += communityType == CommunityAccessType.autoSpread ? 0.05 : 0.01;
      case AvailabilityContext.grocery:
        fit -= groceryGapSeverity * 0.42;
        if (mode == TransportationMode.car) {
          fit += 0.18;
        } else if (mode == TransportationMode.transit) {
          fit += transitSupport * 0.10;
        } else if (mode.lowMobility) {
          fit -= groceryGapSeverity * 0.16;
        }
    }

    if (communityType == CommunityAccessType.autoSpread &&
        mode.lowMobility &&
        source == AvailabilityContext.grocery) {
      fit -= 0.12;
    }

    if (communityType == CommunityAccessType.ruralTown &&
        source == AvailabilityContext.foodPantry &&
        mode.lowMobility) {
      fit -= 0.08;
    }

    return fit.clamp(0.12, 1.15).toDouble();
  }

  factory LocalAccessProfile.fromJson(Map<String, dynamic> json) {
    final sourceMap = Map<String, dynamic>.from(
      json['sources'] as Map? ?? const {},
    );
    final lowAccessArea = json['lowAccessArea'] as bool? ?? false;
    return LocalAccessProfile(
      profileId: json['profileId'] as String? ?? 'unknown',
      label: json['label'] as String? ?? 'Local access snapshot',
      communityLabel: json['communityLabel'] as String? ?? 'Nearby area',
      stateCode: json['stateCode'] as String?,
      lowAccessArea: lowAccessArea,
      communityType: CommunityAccessType.fromCode(
        json['communityType'] as String?,
      ),
      walkSupport:
          (json['walkSupport'] as num?)?.toDouble() ??
          (lowAccessArea ? 0.72 : 0.78),
      transitSupport:
          (json['transitSupport'] as num?)?.toDouble() ??
          (lowAccessArea ? 0.64 : 0.72),
      groceryGapSeverity:
          (json['groceryGapSeverity'] as num?)?.toDouble() ??
          (lowAccessArea ? 0.72 : 0.38),
      notes: json['notes'] as String?,
      sources: {
        for (final entry in sourceMap.entries)
          AvailabilityContext.fromCode(
            entry.key,
          ): SourceAccessSnapshot.fromJson(
            Map<String, dynamic>.from(entry.value as Map),
          ),
      },
    );
  }
}

class LocalAccessProfileResolution {
  const LocalAccessProfileResolution({
    required this.profile,
    required this.matchType,
    this.query,
  });

  final LocalAccessProfile profile;
  final LocalAccessMatchType matchType;
  final String? query;

  double get modeledConfidence {
    final base = switch (matchType) {
      LocalAccessMatchType.exact => 0.96,
      LocalAccessMatchType.prefix => 0.78,
      LocalAccessMatchType.fallback => 0.56,
    };
    final coverageBoost = (profile.sourceCoverageRatio - 0.6) * 0.14;
    final severeGapPenalty =
        matchType == LocalAccessMatchType.exact ||
            profile.groceryGapSeverity < 0.75
        ? 0.0
        : 0.04;
    return (base + coverageBoost - severeGapPenalty).clamp(0.45, 0.98)
        .toDouble();
  }

  bool get approximateModel => matchType != LocalAccessMatchType.exact;
  bool get lowerConfidenceModel => modeledConfidence < 0.7;
}

class LocalAccessCatalog {
  const LocalAccessCatalog({
    required this.exactZipProfiles,
    required this.prefixProfiles,
    required this.fallbackProfile,
  });

  final Map<String, LocalAccessProfile> exactZipProfiles;
  final Map<String, LocalAccessProfile> prefixProfiles;
  final LocalAccessProfile fallbackProfile;

  LocalAccessProfileResolution resolve(String? postalCode) {
    final normalized = _normalizePostalCode(postalCode);
    if (normalized != null) {
      final exact = exactZipProfiles[normalized];
      if (exact != null) {
        return LocalAccessProfileResolution(
          profile: exact,
          matchType: LocalAccessMatchType.exact,
          query: normalized,
        );
      }

      final prefix = prefixProfiles[normalized.substring(0, 3)];
      if (prefix != null) {
        return LocalAccessProfileResolution(
          profile: prefix,
          matchType: LocalAccessMatchType.prefix,
          query: normalized,
        );
      }
    }

    return LocalAccessProfileResolution(
      profile: fallbackProfile,
      matchType: LocalAccessMatchType.fallback,
      query: normalized,
    );
  }

  factory LocalAccessCatalog.fromJson(Map<String, dynamic> json) {
    final fallbackProfile = LocalAccessProfile.fromJson(
      Map<String, dynamic>.from(json['default'] as Map? ?? const {}),
    );
    final exact = <String, LocalAccessProfile>{};
    for (final row in (json['exact'] as List<dynamic>? ?? const [])) {
      final map = Map<String, dynamic>.from(row as Map);
      final postalCode = _normalizePostalCode(map['postalCode'] as String?);
      if (postalCode == null) {
        continue;
      }
      exact[postalCode] = LocalAccessProfile.fromJson(map);
    }

    final prefixes = <String, LocalAccessProfile>{};
    for (final row in (json['prefixes'] as List<dynamic>? ?? const [])) {
      final map = Map<String, dynamic>.from(row as Map);
      final prefix = _normalizePrefix(map['prefix'] as String?);
      if (prefix == null) {
        continue;
      }
      prefixes[prefix] = LocalAccessProfile.fromJson(map);
    }

    return LocalAccessCatalog(
      exactZipProfiles: exact,
      prefixProfiles: prefixes,
      fallbackProfile: fallbackProfile,
    );
  }

  static String? _normalizePostalCode(String? value) {
    if (value == null) {
      return null;
    }
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 5 ? digits.substring(0, 5) : null;
  }

  static String? _normalizePrefix(String? value) {
    if (value == null) {
      return null;
    }
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 3 ? digits.substring(0, 3) : null;
  }
}
