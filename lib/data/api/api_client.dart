import 'package:dio/dio.dart';
import 'package:bacakomik_app/core/constants/variables.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppVariables.baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 30),
                responseType: ResponseType.json,
              ),
            );

  static final ApiClient instance = ApiClient();

  final Dio _dio;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await _dio.get(
        path,
        queryParameters: query
          ?..removeWhere((key, value) => value == null || value == ''),
      );
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map && data['error'] != null
          ? data['error'].toString()
          : e.message ?? 'Network error';
      throw ApiException(message, statusCode: e.response?.statusCode);
    }
  }
}
