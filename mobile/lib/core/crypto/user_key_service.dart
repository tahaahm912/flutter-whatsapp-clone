import 'package:dio/dio.dart';

import 'pre_key_service.dart';

class UserKeyService {
  final Dio dio;
  final PreKeyService preKeyService;

  UserKeyService({
    required this.dio,
    required this.preKeyService,
  });

  /// Upload this device's public Signal Protocol keys.
  ///
  /// Private keys remain on the device.
  Future<void> uploadPublicKeys() async {
    final identityKey =
        await preKeyService.getIdentityPublicKey();

    final signedPreKey =
        await preKeyService.generateSignedPreKey();

    final oneTimePreKeys =
        await preKeyService.generateOneTimePreKeys(
      startId: 1,
      count: 100,
    );

    final payload = {
      'identityKey': identityKey,
      'signedPreKey':
          preKeyService.signedPreKeyToJson(
        signedPreKey,
      ),
      'oneTimePreKeys': oneTimePreKeys
          .map(
            (key) => preKeyService.preKeyToJson(key),
          )
          .toList(),
    };

    await dio.post(
      '/users/keys',
      data: payload,
    );
  }
}