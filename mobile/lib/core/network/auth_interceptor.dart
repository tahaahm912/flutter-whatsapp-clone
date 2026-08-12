import 'package:dio/dio.dart';

import '../storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorage _storage;

  AuthInterceptor({SecureStorage? storage})
      : _storage = storage ?? SecureStorage();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    print('========== AUTH INTERCEPTOR ==========');
    print('REQUEST => ${options.method} ${options.uri}');

    // Public endpoints do not require authentication.
    final publicEndpoints = [
      '/health',
      '/auth/register',
      '/auth/verify-otp',
      '/auth/resend-otp',
      '/auth/login',
    ];

    final isPublicEndpoint = publicEndpoints.any(
      (endpoint) => options.path == endpoint,
    );

    if (!isPublicEndpoint) {
      // Bug fix (Week 4, Day 5): this used to be a no-op comment and
      // never actually attached a token, which meant every protected
      // endpoint (including the new POST /users/keys auto-upload)
      // failed with 401 AUTH_HEADER_MALFORMED. Now reads the real
      // access token saved by SecureStorage after login.
      final token = await _storage.getAccessToken();

      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
        print('Authenticated endpoint detected - token attached');
      } else {
        print('Authenticated endpoint detected - no token in storage');
      }
    } else {
      print('Public endpoint - no Authorization header added');
    }

    handler.next(options);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    print('========== AUTH RESPONSE ==========');
    print('STATUS => ${response.statusCode}');

    handler.next(response);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    print('========== AUTH ERROR ==========');
    print('ERROR => ${err.message}');
    print('URL => ${err.requestOptions.uri}');

    handler.next(err);
  }
}