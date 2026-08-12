import 'package:dio/dio.dart';

import 'pre_key_service.dart';

class UserKeyService {
  final Dio dio;
  final PreKeyService preKeyService;

  UserKeyService({
    required this.dio,
    required this.preKeyService,
  });

  /// Generate and upload this device's public Signal Protocol keys.
  ///
  /// Private keys remain on the device.
  Future<Map<String, dynamic>> uploadPublicKeys() async {
    // Identity public key
    final identityKey =
        await preKeyService.getIdentityPublicKey();

    // Signed pre-key
    final signedPreKey =
        await preKeyService.generateSignedPreKey(
      id: 1,
    );

    // One-time pre-keys
    final oneTimePreKeys =
        await preKeyService.generateOneTimePreKeys(
      startId: 1,
      count: 100,
    );

    final signedPreKeyJson =
        preKeyService.signedPreKeyToJson(
      signedPreKey,
    );

    final payload = {
      'identity_public_key': identityKey,

      // Backend requires this.
      'registration_id': 1,

      'signed_prekey': {
        'key_id': signedPreKeyJson['id'],
        'public_key': signedPreKeyJson['publicKey'],
        'signature': signedPreKeyJson['signature'],
      },

      'one_time_prekeys': oneTimePreKeys.map((key) {
        final json = preKeyService.preKeyToJson(key);

        return {
          'key_id': json['id'],
          'public_key': json['publicKey'],
        };
      }).toList(),
    };

    print('Uploading public Signal keys...');

    final response = await dio.post(
      '/users/keys',
      data: payload,
    );

    print('Key upload status: ${response.statusCode}');
    print('Key upload response: ${response.data}');

    return Map<String, dynamic>.from(
      response.data,
    );
  }
}