import 'dart:convert';

import 'package:libsignal/libsignal.dart';

import 'identity_key_service.dart';

class PreKeyService {
  final IdentityKeyService identityKeyService;

  PreKeyService(this.identityKeyService);

  /// Generate a Signed Pre-Key using the identity private key.
  Future<SignedPreKeyRecord> generateSignedPreKey({
    int id = 1,
  }) async {
    final identity =
        await identityKeyService.getOrCreateIdentityKeyPair();

    final signedPreKeyPrivate = PrivateKey.generate();
    final signedPreKeyPublic =
        signedPreKeyPrivate.getPublicKey();

    final identityPrivate = PrivateKey.deserialize(
      bytes: identity.privateKey.toList(),
    );

    final signature = identityPrivate.sign(
      message: signedPreKeyPublic.serialize().toList(),
    );

    return SignedPreKeyRecord(
      id: id,
      timestamp: BigInt.from(
        DateTime.now().millisecondsSinceEpoch,
      ),
      publicKey: signedPreKeyPublic,
      privateKey: signedPreKeyPrivate,
      signature: signature.toList(),
    );
  }

  /// Generate One-Time Pre-Keys.
  Future<List<PreKeyRecord>> generateOneTimePreKeys({
    int startId = 1,
    int count = 100,
  }) async {
    final List<PreKeyRecord> keys = [];

    for (int i = 0; i < count; i++) {
      final privateKey = PrivateKey.generate();
      final publicKey = privateKey.getPublicKey();

      keys.add(
        PreKeyRecord(
          id: startId + i,
          publicKey: publicKey,
          privateKey: privateKey,
        ),
      );
    }

    return keys;
  }

  /// Convert a Signed Pre-Key's public information to JSON.
  ///
  /// Field names match the backend's `SignedPrekeyInput` DTO exactly
  /// (`key_id` / `public_key` / `signature`) — fixed Week 4, Day 5.
  /// This used to emit `id`/`publicKey`/`signature`, which the
  /// backend's Gin binding silently ignored (unknown JSON fields
  /// aren't an error by default), so the real `key_id`/`public_key`
  /// fields were always missing and failed `binding:"required"`.
  Map<String, dynamic> signedPreKeyToJson(
    SignedPreKeyRecord key,
  ) {
    return {
      // Bug fix (Week 4, Day 5): `id` is a method on this class, same
      // as `publicKey()` and `signature()` right below — `key.id`
      // (no parens) was tearing off the method itself instead of
      // calling it, which crashed jsonEncode inside Dio with
      // "Converting object to an encodable object failed: Closure:
      // () => int from Function 'id'" the first time this was
      // actually exercised (Week 4, Day 5's auto-upload).
      'key_id': key.id(),
      'public_key': base64Encode(
        key.publicKey().toList(),
      ),
      'signature': base64Encode(
        key.signature().toList(),
      ),
    };
  }

  /// Convert a One-Time Pre-Key's public information to JSON.
  /// See `signedPreKeyToJson` above for why these are `key_id` /
  /// `public_key`, not `id` / `publicKey`.
  Map<String, dynamic> preKeyToJson(
    PreKeyRecord key,
  ) {
    return {
      'key_id': key.id(),
      'public_key': base64Encode(
        key.publicKey().toList(),
      ),
    };
  }

  /// Return the identity public key as Base64.
  Future<String> getIdentityPublicKey() async {
    final identity =
        await identityKeyService.getOrCreateIdentityKeyPair();

    return base64Encode(
      identity.publicKey.toList(),
    );
  }
}