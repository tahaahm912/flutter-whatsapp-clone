import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) {

    print("========== REQUEST ==========");
    print(options.method);
    print(options.uri);
    print(options.headers);

    options.headers["Authorization"] = "Bearer ";

    handler.next(options);
  }

  @override
  void onResponse(
      Response response,
      ResponseInterceptorHandler handler,
      ) {

    print("========== RESPONSE ==========");
    print(response.statusCode);
    print(response.data);

    handler.next(response);
  }

  @override
  void onError(
      DioException err,
      ErrorInterceptorHandler handler,
      ) {

    print("========== ERROR ==========");
    print(err.message);

    handler.next(err);
  }
}