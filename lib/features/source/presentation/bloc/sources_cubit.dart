import 'package:bacakomik_app/core/source/comic_key.dart';
import 'package:bacakomik_app/core/source/extension_manager.dart';
import 'package:bacakomik_app/core/source/extension_meta.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Installed sources and the one Home and Explore show.
class SourcesState {
  const SourcesState({
    this.installed = const [],
    this.known = const [],
    this.activeId,
    this.features = const SourceFeatures(),
    this.loadError,
    this.ready = false,
    this.updateCount = 0,
  });

  /// Sources to pick from: enabled languages only.
  final List<ExtensionMeta> installed;

  /// Every source of the installed extensions, also languages turned off,
  /// to name and badge their comics.
  final List<ExtensionMeta> known;
  final String? activeId;

  /// Filter options and Home sorts of the active source.
  final SourceFeatures features;

  /// Set when the active source's script failed to load.
  final String? loadError;

  /// False until the active source was loaded once.
  final bool ready;

  /// Extensions with an update in the repos (badge on More > Extensions).
  final int updateCount;

  ExtensionMeta? get active =>
      installed.where((e) => e.id == activeId).firstOrNull;
}

extension SourceNames on BuildContext {
  /// Name of the source of a [ComicKey]; its id when not installed, or
  /// when no [SourcesCubit] is above (widget tests).
  String sourceNameOf(String key) =>
      sourceOf(key)?.name ?? ComicKey.sourceOf(key);

  /// Installed extension a [ComicKey] belongs to; null when not installed,
  /// or when no [SourcesCubit] is above (widget tests).
  ExtensionMeta? sourceOf(String key) {
    final id = ComicKey.sourceOf(key);
    final known = read<SourcesCubit?>()?.state.known ?? const [];
    return known.where((e) => e.id == id).firstOrNull;
  }

  /// `VoraToon · ID`: name and language of the source of a [ComicKey].
  /// Just the id when not installed.
  String sourceLabelOf(String key) => switch (sourceOf(key)) {
    final meta? => '${meta.baseName} · ${meta.lang.toUpperCase()}',
    null => ComicKey.sourceOf(key),
  };
}

/// Mirrors [ExtensionManager]: re-emits whenever an extension is installed,
/// updated or removed, or another source is picked.
@injectable
class SourcesCubit extends Cubit<SourcesState> {
  SourcesCubit(this._manager) : super(const SourcesState()) {
    _manager.addListener(_sync);
    _sync();
  }

  final ExtensionManager _manager;

  Future<void> select(String sourceId) => _manager.setActiveSource(sourceId);

  /// Bumped per [_sync]; a slower earlier one (a Mihon source loading its
  /// filters) must not emit over a newer pick.
  var _syncs = 0;

  Future<void> _sync() async {
    final sync = ++_syncs;
    final activeId = _manager.activeSource;
    var features = const SourceFeatures();
    String? error;
    if (activeId != null) {
      try {
        features = await (await _manager.backend(activeId)).features();
      } catch (e) {
        debugPrint('SourcesCubit: $e');
        error = '$e';
      }
    }
    if (isClosed || sync != _syncs) return;
    emit(
      SourcesState(
        installed: _manager.installed,
        known: _manager.knownSources,
        activeId: activeId,
        features: features,
        loadError: error,
        ready: true,
        updateCount: _manager.updateCount,
      ),
    );
  }

  @override
  Future<void> close() {
    _manager.removeListener(_sync);
    return super.close();
  }
}
