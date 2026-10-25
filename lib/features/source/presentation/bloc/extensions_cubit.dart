import 'package:bacakomik_app/core/source/extension_manager.dart';
import 'package:bacakomik_app/core/source/extension_meta.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// A repo of the catalog, or the error it failed with.
class RepoEntry {
  const RepoEntry({required this.url, this.name, this.error});

  final String url;
  final String? name;
  final String? error;
}

class ExtensionsState {
  const ExtensionsState({
    this.installed = const [],
    this.available = const [],
    this.repos = const [],
    this.loading = false,
    this.busy = const {},
  });

  final List<ExtensionMeta> installed;

  /// Newest version of every extension the repos offer, by name.
  final List<ExtensionMeta> available;
  final List<RepoEntry> repos;

  /// Fetching the repos.
  final bool loading;

  /// Ids being installed or removed.
  final Set<String> busy;

  /// Repo version of [id] when it is newer than the installed one.
  ExtensionMeta? updateFor(String id) {
    final current = installed.where((e) => e.id == id).firstOrNull;
    final offered = available.where((e) => e.id == id).firstOrNull;
    if (current == null || offered == null) return null;
    return offered.isNewerThan(current) ? offered : null;
  }

  int get updateCount =>
      installed.where((e) => updateFor(e.id)?.supported ?? false).length;

  /// Offered extensions that are not installed.
  List<ExtensionMeta> get notInstalled => [
    for (final e in available)
      if (!installed.any((i) => i.id == e.id)) e,
  ];

  /// Languages of [notInstalled], for the language filter.
  List<String> get languages =>
      {for (final e in notInstalled) e.lang}.toList()..sort();

  ExtensionsState copyWith({
    List<ExtensionMeta>? installed,
    List<ExtensionMeta>? available,
    List<RepoEntry>? repos,
    bool? loading,
    Set<String>? busy,
  }) => ExtensionsState(
    installed: installed ?? this.installed,
    available: available ?? this.available,
    repos: repos ?? this.repos,
    loading: loading ?? this.loading,
    busy: busy ?? this.busy,
  );
}

@injectable
class ExtensionsCubit extends Cubit<ExtensionsState> {
  ExtensionsCubit(this._manager)
    : super(ExtensionsState(installed: _manager.extensions)) {
    _manager.addListener(_onInstalledChanged);
  }

  final ExtensionManager _manager;

  void _onInstalledChanged() {
    if (!isClosed) emit(state.copyWith(installed: _manager.extensions));
  }

  Future<void> refresh() async {
    emit(state.copyWith(loading: true));
    final catalog = await _manager.catalog();
    final newest = <String, ExtensionMeta>{};
    for (final entry in catalog) {
      for (final e in entry.repo?.extensions ?? const <ExtensionMeta>[]) {
        // The first repo listing an id wins unless another has a newer
        // version.
        final seen = newest[e.id];
        if (seen == null || e.isNewerThan(seen)) newest[e.id] = e;
      }
    }
    if (isClosed) return;
    emit(
      state.copyWith(
        loading: false,
        installed: _manager.extensions,
        available: newest.values.toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          ),
        repos: [
          for (final entry in catalog)
            RepoEntry(
              url: entry.url,
              name: entry.repo?.name,
              error: entry.error,
            ),
        ],
      ),
    );
  }

  /// Installs or updates [meta]. Returns an error message, or null.
  Future<String?> install(ExtensionMeta meta) =>
      _busy(meta.id, () => _manager.install(meta));

  Future<String?> uninstall(String id) =>
      _busy(id, () => _manager.uninstall(id));

  /// Returns an error message, or null when the repo was added.
  Future<String?> addRepo(String url) async {
    try {
      await _manager.addRepo(url);
    } catch (e) {
      return '$e';
    }
    await refresh();
    return null;
  }

  Future<void> removeRepo(String url) async {
    await _manager.removeRepo(url);
    await refresh();
  }

  Future<String?> _busy(String id, Future<void> Function() action) async {
    emit(state.copyWith(busy: {...state.busy, id}));
    String? error;
    try {
      await action();
    } catch (e) {
      error = '$e';
    }
    if (!isClosed) {
      emit(
        state.copyWith(
          installed: _manager.extensions,
          busy: {...state.busy}..remove(id),
        ),
      );
    }
    return error;
  }

  @override
  Future<void> close() {
    _manager.removeListener(_onInstalledChanged);
    return super.close();
  }
}
