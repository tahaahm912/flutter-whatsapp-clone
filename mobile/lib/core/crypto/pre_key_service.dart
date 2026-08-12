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
  Map<String, dynamic> signedPreKeyToJson(
    SignedPreKeyRecord key,
  ) {
    return {
      'id': key.id,
      'publicKey': base64Encode(
        key.publicKey().toList(),
      ),
      'signature': base64Encode(
        key.signature().toList(),
      ),
    };
  }

  /// Convert a One-Time Pre-Key's public information to JSON.
  Map<String, dynamic> preKeyToJson(
    PreKeyRecord key,
  ) {
    return {
      'id': key.id,
      'publicKey': base64Encode(
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