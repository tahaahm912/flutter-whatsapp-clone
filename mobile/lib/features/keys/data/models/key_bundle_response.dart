/// Parsed response for `GET /users/:userId/keys` — one [DeviceKeyBundle]
/// per active device the user has finished uploading keys for. See
/// backend/internal/keys/dto.go `KeyBundleResponse` for the source shape.
///
/// Week 6, Day 2: this is what `SessionService.establishSession` feeds into
/// libsignal's `PreKeyBundle` to run X3DH/PQXDH with a specific device.
class UserKeyBundle {
  final String userId;
  final List<DeviceKeyBundle> devices;

  UserKeyBundle({required this.userId, required this.devices});

  factory UserKeyBundle.fromJson(Map<String, dynamic> json) {
    return UserKeyBundle(
      userId: json['user_id'] as String,
      devices: (json['devices'] as List<dynamic>? ?? [])
          .map((d) => DeviceKeyBundle.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Everything the backend has for one specific device of a user.
class DeviceKeyBundle {
  final String deviceId;
  final DeviceIdentityKey identityKey;
  final DeviceSignedPrekey signedPrekey;
  final DeviceOneTimePrekey? oneTimePrekey;

  /// Not present in today's backend response — see
  /// `SignalSessionException.missingKyberPreKey` for why that blocks a real
  /// session. Parsed defensively so nothing here needs to change the day
  /// the backend adds it.
  final DeviceKyberPrekey? kyberPrekey;

  DeviceKeyBundle({
    required this.deviceId,
    required this.identityKey,
    required this.signedPrekey,
    this.oneTimePrekey,
    this.kyberPrekey,
  });

  factory DeviceKeyBundle.fromJson(Map<String, dynamic> json) {
    return DeviceKeyBundle(
      deviceId: json['device_id'] as String,
      identityKey: DeviceIdentityKey.fromJson(
        json['identity_key'] as Map<String, dynamic>,
      ),
      signedPrekey: DeviceSignedPrekey.fromJson(
        json['signed_prekey'] as Map<String, dynamic>,
      ),
      oneTimePrekey: json['one_time_prekey'] == null
          ? null
          : DeviceOneTimePrekey.fromJson(
              json['one_time_prekey'] as Map<String, dynamic>,
            ),
      // Speculative key — today's backend never sends this field.
      kyberPrekey: json['kyber_prekey'] == null
          ? null
          : DeviceKyberPrekey.fromJson(
              json['kyber_prekey'] as Map<String, dynamic>,
            ),
    );
  }
}

class DeviceIdentityKey {
  final String publicKey;
  final int registrationId;

  DeviceIdentityKey({required this.publicKey, required this.registrationId});

  factory DeviceIdentityKey.fromJson(Map<String, dynamic> json) {
    return DeviceIdentityKey(
      publicKey: json['public_key'] as String,
      registrationId: json['registration_id'] as int,
    );
  }
}

class DeviceSignedPrekey {
  final int keyId;
  final String publicKey;
  final String signature;

  DeviceSignedPrekey({
    required this.keyId,
    required this.publicKey,
    required this.signature,
  });

  factory DeviceSignedPrekey.fromJson(Map<String, dynamic> json) {
    return DeviceSignedPrekey(
      keyId: json['key_id'] as int,
      publicKey: json['public_key'] as String,
      signature: json['signature'] as String,
    );
  }
}

class DeviceOneTimePrekey {
  final int keyId;
  final String publicKey;

  DeviceOneTimePrekey({required this.keyId, required this.publicKey});

  factory DeviceOneTimePrekey.fromJson(Map<String, dynamic> json) {
    return DeviceOneTimePrekey(
      keyId: json['key_id'] as int,
      publicKey: json['public_key'] as String,
    );
  }
}

/// Forward-compatible only — the backend doesn't send this yet. See
/// `SignalSessionException.missingKyberPreKey`.
class DeviceKyberPrekey {
  final int keyId;
  final String publicKey;
  final String signature;

  DeviceKyberPrekey({
    required this.keyId,
    required this.publicKey,
    required this.signature,
  });

  factory DeviceKyberPrekey.fromJson(Map<String, dynamic> json) {
    return DeviceKyberPrekey(
      keyId: json['key_id'] as int,
      publicKey: json['public_key'] as String,
      signature: json['signature'] as String,
    );
  }
}