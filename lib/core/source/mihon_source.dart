import 'package:bacakomik_app/core/error/exceptions.dart';
import 'package:bacakomik_app/core/source/extension_meta.dart';
import 'package:bacakomik_app/core/source/extension_runtime.dart';
import 'package:bacakomik_app/core/source/mihon_host.dart';

/// A source of a Mihon extension. Kotlin's `Contract` answers the same
/// methods as a JS extension (`browse`, `series`, `chapters`, `chapter`,
/// `webUrl`), so everything above [SourceBackend] treats both alike.
class MihonSource implements LoadedSource {
  MihonSource(this.meta, this._host);

  @override
  final ExtensionMeta meta;
  final MihonHost _host;
  Future<SourceFeatures>? _features;
  var _disposed = false;

  /// The Mihon source id (`mihon-<id>` → `<id>`).
  String get _sourceId => meta.id.substring(ExtensionMeta.mihonPrefix.length);

  @override
  Future<Object?> call(String method, List<Object?> args) {
    if (_disposed) {
      return Future.error(ServerException('${meta.name} is not loaded'));
    }
    return _host.handle('call', {
      'source': _sourceId,
      'method': method,
      'args': args,
    });
  }

  @override
  Future<SourceFeatures> features() => _features ??=
      () async {
        final res = await call('features', const []);
        final map = res is Map ? res : const {};
        return SourceFeatures.fromJson(
          home: map['home'],
          groups: map['filters'],
        );
      }().catchError((Object e) {
        _features = null;
        throw e;
      });

  /// The source's settings (`ConfigurableSource`): `[{key, title, summary,
  /// enabled, type: switch|list|multiselect|text|info, entries, values,
  /// value}]`.
  Future<List<Map<String, Object?>>> preferences() async {
    final res = await _host.handle('preferences', {'source': _sourceId});
    return [
      for (final p in res is List ? res : const [])
        if (p is Map) p.cast<String, Object?>(),
    ];
  }

  Future<void> setPreference(String key, Object? value) async {
    await _host.handle('setPreference', {
      'source': _sourceId,
      'key': key,
      'value': value,
    });
    // Filters may depend on settings (a mirror, a language).
    _features = null;
  }

  @override
  void dispose() => _disposed = true;
}
