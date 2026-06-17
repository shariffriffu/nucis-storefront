import 'package:dio/dio.dart';

class DioClient {
  static final DioClient instance = DioClient._init();
  late final Dio _dio;
  bool _isDemoMode = true;

  DioClient._init() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
  }

  void configure({required bool demoMode, required String baseUrl}) {
    _isDemoMode = demoMode;
    _dio.options.baseUrl = baseUrl;
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters, Options? options}) async {
    if (_isDemoMode) {
      return _mockGetResponse<T>(path);
    }
    return await _dio.get<T>(path, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> post<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    if (_isDemoMode) {
      return _mockPostResponse<T>(path, data);
    }
    return await _dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> _mockGetResponse<T>(String path) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    if (path.contains('/status')) {
      return Response(
        requestOptions: RequestOptions(path: path),
        data: {'status': 'healthy', 'version': '1.0.0'} as T,
        statusCode: 200,
      );
    }
    
    throw DioException(
      requestOptions: RequestOptions(path: path),
      error: 'Mock REST Endpoint not found',
      type: DioExceptionType.badResponse,
    );
  }

  Future<Response<T>> _mockPostResponse<T>(String path, dynamic data) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (path.contains('/auth/login')) {
      final email = data['email'] ?? '';
      final password = data['password'] ?? '';
      
      if (email.contains('@') && password.length >= 6) {
        return Response(
          requestOptions: RequestOptions(path: path),
          data: {
            'token': 'demo_token_jwt_99887766554433',
            'user': {
              'email': email,
              'name': 'AlgoBot Administrator',
            }
          } as T,
          statusCode: 200,
        );
      } else {
        return Response(
          requestOptions: RequestOptions(path: path),
          data: {'message': 'Invalid credentials. Email must be valid, Password min 6 characters.'} as T,
          statusCode: 400,
        );
      }
    }

    throw DioException(
      requestOptions: RequestOptions(path: path),
      error: 'Mock REST Endpoint not found',
      type: DioExceptionType.badResponse,
    );
  }
}
