class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final String message;
  final LoginUser user;

  const LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.message,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];

    return LoginResponse(
      accessToken: json['access_token']?.toString() ?? '',
      refreshToken: json['refresh_token']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      user: userJson is Map
          ? LoginUser.fromJson(
              Map<String, dynamic>.from(userJson),
            )
          : const LoginUser(
              id: '',
              name: '',
            ),
    );
  }
}

class LoginUser {
  final String id;
  final String name;
  final String? phoneNumber;
  final String? email;

  const LoginUser({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.email,
  });

  factory LoginUser.fromJson(Map<String, dynamic> json) {
    return LoginUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString(),
      email: json['email']?.toString(),
    );
  }
}