import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
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
      // JWT authentication will be added here later
      // when we implement secure token storage.
      print('Authenticated endpoint detected');
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