import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../models/key_bundle_response.dart';

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

  /// Fetches [userId]'s public Signal Protocol key bundle — one
  /// [DeviceKeyBundle] per active device that has finished uploading keys.
  ///
  /// Week 6, Day 2: this is the "each other's public keys" half of session
  /// establishment — `SessionService.establishSession` calls this to get
  /// the remote party's keys before running X3DH/PQXDH.
  Future<UserKeyBundle> fetchUserKeyBundle(String userId) async {
    try {
      final response = await _apiClient.dio.get('/users/$userId/keys');

      return UserKeyBundle.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final data = e.response?.data;
      final code = data is Map ? data['code'] as String? : null;

      if (code == 'USER_NOT_FOUND') {
        throw Exception('USER_NOT_FOUND');
      }

      if (code == 'NO_KEYS_AVAILABLE') {
        throw Exception('NO_KEYS_AVAILABLE');
      }

      throw Exception('NETWORK_ERROR');
    }
  }
}