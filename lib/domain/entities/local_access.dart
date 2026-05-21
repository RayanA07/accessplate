import '../value_objects/availability_context.dart';

enum LocalAccessMatchType { exact, prefix, fallback }

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
      sameDayConfidence:
          (json['sameDayConfidence'] as num?)?.toDouble() ?? 0.0,
      note: json['note'] as String?,
    );
  }
}

class LocalAccessProfile {
  const LocalAccessProfile({
    required this.profileId,
    required this.label,
    required this.communityLabel,
    required this.lowAccessArea,
    required this.sources,
    this.notes,
  });

  final String profileId;
  final String label;
  final String communityLabel;
  final bool lowAccessArea;
  final Map<AvailabilityContext, SourceAccessSnapshot> sources;
  final String? notes;

  SourceAccessSnapshot? sourceFor(AvailabilityContext context) {
    return sources[context];
  }

  factory LocalAccessProfile.fromJson(Map<String, dynamic> json) {
    final sourceMap = Map<String, dynamic>.from(
      json['sources'] as Map? ?? const {},
    );
    return LocalAccessProfile(
      profileId: json['profileId'] as String? ?? 'unknown',
      label: json['label'] as String? ?? 'Local access snapshot',
      communityLabel: json['communityLabel'] as String? ?? 'Nearby area',
      lowAccessArea: json['lowAccessArea'] as bool? ?? false,
      notes: json['notes'] as String?,
      sources: {
        for (final entry in sourceMap.entries)
          AvailabilityContext.fromCode(entry.key): SourceAccessSnapshot.fromJson(
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
