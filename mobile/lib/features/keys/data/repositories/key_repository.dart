import 'package:mobile/core/crypto/identity_key_service.dart';
import 'package:mobile/core/crypto/pre_key_service.dart';
import 'package:mobile/core/network/api_client.dart';

import '../services/key_api_service.dart';

class KeyRepository {
  final IdentityKeyService _identityKeyService;
  final PreKeyService _preKeyService;
  final KeyApiService _keyApiService;

  KeyRepository({
    required IdentityKeyService identityKeyService,
    required PreKeyService preKeyService,
    required KeyApiService keyApiService,
  })  : _identityKeyService = identityKeyService,
        _preKeyService = preKeyService,
        _keyApiService = keyApiService;

  Future<void> uploadPublicKeys() async {
    final identityKey =
        await _identityKeyService.getOrCreateIdentityKeyPair();

    final identityPublicKey =
        _identityKeyService.getPublicKey(identityKey);

    final signedPreKey =
        await _preKeyService.generateSignedPreKey(id: 1);

    final oneTimePreKeys =
        await _preKeyService.generateOneTimePreKeys(
      startId: 1,
      count: 100,
    );

    final signedPreKeyJson =
        _preKeyService.signedPreKeyToJson(signedPreKey);

    final oneTimePreKeysJson = oneTimePreKeys
        .map(
          (key) => _preKeyService.preKeyToJson(key),
        )
        .toList();

    await _keyApiService.uploadPublicKeys(
      identityKey: identityPublicKey,
      signedPreKey: signedPreKeyJson,
      oneTimePreKeys: oneTimePreKeysJson,
    );
  }
}