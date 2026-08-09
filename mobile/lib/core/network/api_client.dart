import 'package:dio/dio.dart';

import 'api_constants.dart';
import 'auth_interceptor.dart';

class ApiClient {
  late final Dio dio;

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Authentication interceptor
    dio.interceptors.add(AuthInterceptor());

    // Logging interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print('========== REQUEST ==========');
          print('${options.method}');
          print('${options.uri}');
          print('${options.headers}');
          print('REQUEST => ${options.method} ${options.path}');

          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('========== RESPONSE ==========');
          print('STATUS => ${response.statusCode}');
          print('DATA => ${response.data}');

          return handler.next(response);
        },
        onError: (e, handler) {
          print('========== ERROR ==========');
          print('ERROR TYPE => ${e.type}');
          print('ERROR => ${e.message}');
          print('ERROR URL => ${e.requestOptions.uri}');

          return handler.next(e);
        },
      ),
    );
  }
}