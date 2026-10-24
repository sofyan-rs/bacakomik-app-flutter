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
    this.activeId,
    this.features = const SourceFeatures(),
    this.loadError,
    this.ready = false,
  });

  final List<ExtensionMeta> installed;
  final String? activeId;

  /// Filter options and Home sorts of the active source.
  final SourceFeatures features;

  /// Set when the active source's script failed to load.
  final String? loadError;

  /// False until the active source was loaded once.
  final bool ready;

  ExtensionMeta? get active =>
      installed.where((e) => e.id == activeId).firstOrNull;
}

extension SourceNames on BuildContext {
  /// Name of the source of a [ComicKey]; its id when not installed, or
  /// when no [SourcesCubit] is above (widget tests).
  String sourceNameOf(String key) {
    final id = ComicKey.sourceOf(key);
    final installed = read<SourcesCubit?>()?.state.installed ?? const [];
    return installed.where((e) => e.id == id).firstOrNull?.name ?? id;
  }
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

  Future<void> _sync() async {
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
    if (isClosed) return;
    emit(
      SourcesState(
        installed: _manager.installed,
        activeId: activeId,
        features: features,
        loadError: error,
        ready: true,
      ),
    );
  }

  @override
  Future<void> close() {
    _manager.removeListener(_sync);
    return super.close();
  }
}
