import 'package:mobile/features/auth/data/services/auth_api_service.dart';

import 'package:mobile/features/auth/data/models/register_request.dart';
import 'package:mobile/features/auth/data/models/register_response.dart';

class AuthRepository {
  final AuthApiService _apiService;

  AuthRepository(this._apiService);

  Future<RegisterResponse> register(RegisterRequest request) async {
    return await _apiService.register(request);
  }
} 