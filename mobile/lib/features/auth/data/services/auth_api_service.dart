import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../models/register_request.dart';
import '../models/register_response.dart';

class AuthApiService {
  final ApiClient _apiClient = ApiClient();

  Future<RegisterResponse> register(RegisterRequest request) async {
    final Response response = await _apiClient.dio.post(
      "/auth/register",
      data: request.toJson(),
    );

    return RegisterResponse.fromJson(response.data);
  }
}