import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../models/register_request.dart';
import '../models/register_response.dart';
import '../models/verify_otp_request.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';

class AuthApiService {
  final ApiClient _apiClient = ApiClient();

  Future<RegisterResponse> register(RegisterRequest request) async {
    final Response response = await _apiClient.dio.post(
      "/auth/register",
      data: request.toJson(),
    );

    return RegisterResponse.fromJson(response.data);
  }

  Future<void> verifyOtp(VerifyOtpRequest request) async {
    await _apiClient.dio.post(
      "/auth/verify-otp",
      data: request.toJson(),
    );
  }

  Future<LoginResponse> login(LoginRequest request) async {
    final Response response = await _apiClient.dio.post(
      "/auth/login",
      data: request.toJson(),
    );

    return LoginResponse.fromJson(response.data);
  }  
}