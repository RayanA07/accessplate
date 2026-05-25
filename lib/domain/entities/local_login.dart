import 'dart:convert';

import 'package:crypto/crypto.dart';

class LocalLogin {
  const LocalLogin({
    this.displayName = '',
    this.pinSalt = '',
    this.pinHash = '',
    this.createdAtIso,
  });

  final String displayName;
  final String pinSalt;
  final String pinHash;
  final String? createdAtIso;

  bool get isConfigured =>
      displayName.trim().isNotEmpty &&
      pinSalt.trim().isNotEmpty &&
      pinHash.trim().isNotEmpty;

  LocalLogin copyWith({
    String? displayName,
    String? pinSalt,
    String? pinHash,
    String? createdAtIso,
  }) {
    return LocalLogin(
      displayName: displayName ?? this.displayName,
      pinSalt: pinSalt ?? this.pinSalt,
      pinHash: pinHash ?? this.pinHash,
      createdAtIso: createdAtIso ?? this.createdAtIso,
    );
  }

  factory LocalLogin.create({
    required String displayName,
    required String pin,
    DateTime? now,
  }) {
    final trimmedName = displayName.trim();
    final createdAt = (now ?? DateTime.now()).toUtc();
    final saltSeed = '$trimmedName:${createdAt.toIso8601String()}';
    final salt = base64Url.encode(utf8.encode(saltSeed));
    return LocalLogin(
      displayName: trimmedName,
      pinSalt: salt,
      pinHash: _hashPin(salt: salt, pin: pin),
      createdAtIso: createdAt.toIso8601String(),
    );
  }

  bool verifyPin(String pin) {
    if (!isConfigured) {
      return false;
    }
    return _hashPin(salt: pinSalt, pin: pin) == pinHash;
  }

  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'pinSalt': pinSalt,
      'pinHash': pinHash,
      'createdAtIso': createdAtIso,
    };
  }

  factory LocalLogin.fromJson(Map<String, dynamic> json) {
    return LocalLogin(
      displayName: json['displayName'] as String? ?? '',
      pinSalt: json['pinSalt'] as String? ?? '',
      pinHash: json['pinHash'] as String? ?? '',
      createdAtIso: json['createdAtIso'] as String?,
    );
  }

  static String _hashPin({required String salt, required String pin}) {
    return sha256.convert(utf8.encode('$salt:$pin')).toString();
  }
}
