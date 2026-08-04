import 'package:dio/dio.dart';
import 'api_constants.dart';
import 'auth_interceptor.dart';

class ApiClient {
  late final Dio dio;

  ApiClient(){
    dio = Dio(
     BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
     ),
    );

    dio.interceptors.add(AuthInterceptor());

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler){
          print("REQUEST => ${options.method} ${options.path}");
          return handler.next(options);
        },
        onResponse: (response, handler){
          print("RESPONSE => ${response.statusCode} ");
          return handler.next(response);
        },
        onError: (e, handler){
          print("ERROR => ${e.message}");
          return handler.next(e);
        },
      ),
    );
  }
}