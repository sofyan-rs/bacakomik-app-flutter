import 'dart:convert';
import 'dart:typed_data';

import 'package:bacakomik_app/core/di/register_module.dart';
import 'package:bacakomik_app/features/sync/data/datasources/google_auth_data_source.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

/// Thrown when no Drive access token is available.
class SignedOutException implements Exception {
  const SignedOutException();

  @override
  String toString() => 'Not signed in to Google';
}

/// One file in the app's private Drive folder (`appDataFolder`), which the
/// user cannot see or edit in Drive.
abstract interface class DriveDataSource {
  /// Null when the file does not exist yet.
  Future<Uint8List?> read();

  Future<void> write(Uint8List content);
}

@LazySingleton(as: DriveDataSource)
class DriveDataSourceImpl implements DriveDataSource {
  DriveDataSourceImpl(@Named(filesDio) this._dio, this._auth);

  static const fileName = 'bacakomik-sync.json.gz';
  static const _api = 'https://www.googleapis.com/drive/v3/files';
  static const _uploadApi = 'https://www.googleapis.com/upload/drive/v3/files';
  static const _boundary = 'bacakomik-sync-boundary';

  final Dio _dio;
  final GoogleAuthDataSource _auth;

  /// Cached Drive file id; reset when the file is gone.
  String? _fileId;

  @override
  Future<Uint8List?> read() async {
    final id = await _findFileId();
    if (id == null) return null;
    try {
      final response = await _authorized(
        (options) => _dio.get<List<int>>(
          '$_api/$id',
          queryParameters: {'alt': 'media'},
          options: options.copyWith(responseType: ResponseType.bytes),
        ),
      );
      return Uint8List.fromList(response.data ?? const []);
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) rethrow;
      _fileId = null;
      return null;
    }
  }

  @override
  Future<void> write(Uint8List content) async {
    final id = await _findFileId();
    if (id != null) {
      await _authorized(
        (options) => _dio.patch<void>(
          '$_uploadApi/$id',
          queryParameters: {'uploadType': 'media'},
          data: Stream.value(content),
          options: options.copyWith(
            contentType: 'application/gzip',
            headers: {
              ...?options.headers,
              Headers.contentLengthHeader: content.length,
            },
          ),
        ),
      );
      return;
    }

    final metadata = jsonEncode({
      'name': fileName,
      'parents': ['appDataFolder'],
    });
    final body = BytesBuilder(copy: false)
      ..add(
        utf8.encode(
          '--$_boundary\r\n'
          'Content-Type: application/json; charset=UTF-8\r\n\r\n'
          '$metadata\r\n'
          '--$_boundary\r\n'
          'Content-Type: application/gzip\r\n\r\n',
        ),
      )
      ..add(content)
      ..add(utf8.encode('\r\n--$_boundary--'));
    final bytes = body.takeBytes();
    final response = await _authorized(
      (options) => _dio.post<Map<String, dynamic>>(
        _uploadApi,
        queryParameters: {'uploadType': 'multipart', 'fields': 'id'},
        data: Stream.value(bytes),
        options: options.copyWith(
          contentType: 'multipart/related; boundary=$_boundary',
          responseType: ResponseType.json,
          headers: {
            ...?options.headers,
            Headers.contentLengthHeader: bytes.length,
          },
        ),
      ),
    );
    _fileId = response.data?['id'] as String?;
  }

  Future<String?> _findFileId() async {
    if (_fileId != null) return _fileId;
    final response = await _authorized(
      (options) => _dio.get<Map<String, dynamic>>(
        _api,
        queryParameters: {
          'spaces': 'appDataFolder',
          'q': "name = '$fileName' and trashed = false",
          'fields': 'files(id)',
          'pageSize': 1,
        },
        options: options.copyWith(responseType: ResponseType.json),
      ),
    );
    final files = response.data?['files'] as List? ?? const [];
    if (files.isEmpty) return null;
    return _fileId = (files.first as Map<String, dynamic>)['id'] as String;
  }

  /// Runs [request] with a bearer token. A rejected token is cleared and the
  /// request retried once with a fresh one.
  Future<Response<T>> _authorized<T>(
    Future<Response<T>> Function(Options options) request,
  ) async {
    for (var attempt = 0; ; attempt++) {
      final token = await _auth.accessToken();
      if (token == null) throw const SignedOutException();
      try {
        return await request(
          Options(headers: {'Authorization': 'Bearer $token'}),
        );
      } on DioException catch (e) {
        if (e.response?.statusCode != 401 || attempt > 0) rethrow;
        await _auth.clearAccessToken(token);
      }
    }
  }
}
