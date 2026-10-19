import 'package:bacakomik_app/core/error/exceptions.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class ApiClient {
  ApiClient(this._dio);

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
      throw ServerException(message, statusCode: e.response?.statusCode);
    }
  }
}
