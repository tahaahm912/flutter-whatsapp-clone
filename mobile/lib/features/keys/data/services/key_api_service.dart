import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';

class KeyApiService {
  final ApiClient _apiClient;

  KeyApiService(this._apiClient);

  /// Uploads this device's public Signal Protocol key material.
  ///
  /// Field names sent here match the backend's `UploadKeysRequest`
  /// DTO exactly — fixed Week 4, Day 5. This used to send
  /// `identityKey`/`signedPreKey`/`oneTimePreKeys` (camelCase, and
  /// missing `registration_id` entirely), all of which the backend's
  /// Gin binding silently dropped as unrecognized fields, so every
  /// upload failed `400` on the missing required `registration_id`
  /// even once the payload's inner values were otherwise correct.
  Future<void> uploadPublicKeys({
    required String identityKey,
    required int registrationId,
    required Map<String, dynamic> signedPreKey,
    required List<Map<String, dynamic>> oneTimePreKeys,
  }) async {
    await _apiClient.dio.post(
      '/users/keys',
      data: {
        'identity_public_key': identityKey,
        'registration_id': registrationId,
        'signed_prekey': signedPreKey,
        'one_time_prekeys': oneTimePreKeys,
      },
    );
  }
}