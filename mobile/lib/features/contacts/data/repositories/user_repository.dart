import 'package:dio/dio.dart';
import 'package:mobile/core/network/api_client.dart';

class UserSearchResult {
  final String id;
  final String name;
  final String? about;
  final String? profilePhotoUrl;

  UserSearchResult({
    required this.id,
    required this.name,
    this.about,
    this.profilePhotoUrl,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id'] as String,
      name: json['name'] as String,
      about: json['about'] as String?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
    );
  }
}

class UserRepository {
  final ApiClient _apiClient;

  UserRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<UserSearchResult> searchUserByEmail(String email) async {
    try {
      final response = await _apiClient.dio.get(
        '/users/search',
        queryParameters: {
          'email': email,
        },
      );

      return UserSearchResult.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('USER_NOT_FOUND');
      }

      if (e.response?.statusCode == 400) {
        throw Exception('INVALID_SEARCH');
      }

      throw Exception('NETWORK_ERROR');
    }
  }
}