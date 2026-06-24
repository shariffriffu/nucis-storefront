import 'package:dio/dio.dart';

class DioClient {
  static final DioClient instance = DioClient._init();
  late final Dio _dio;

  DioClient._init() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
  }

  void configure({required String baseUrl}) {
    _dio.options.baseUrl = baseUrl;
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters, Options? options}) async {
    return await _dio.get<T>(path, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> post<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    return await _dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);
  }
}
