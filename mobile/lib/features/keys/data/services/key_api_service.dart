import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';

class KeyApiService {
  final ApiClient _apiClient;

  KeyApiService(this._apiClient);

  Future<void> uploadPublicKeys({
    required String identityKey,
    required Map<String, dynamic> signedPreKey,
    required List<Map<String, dynamic>> oneTimePreKeys,
  }) async {
    await _apiClient.dio.post(
      '/users/keys',
      data: {
        'identityKey': identityKey,
        'signedPreKey': signedPreKey,
        'oneTimePreKeys': oneTimePreKeys,
      },
    );
  }
}