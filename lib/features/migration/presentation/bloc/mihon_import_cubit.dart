import 'package:bacakomik_app/core/source/extension_manager.dart';
import 'package:bacakomik_app/core/source/extension_meta.dart';
import 'package:bacakomik_app/features/migration/domain/entities/library_import.dart';
import 'package:bacakomik_app/features/migration/domain/entities/mihon_backup.dart';
import 'package:bacakomik_app/features/migration/domain/entities/mihon_import_plan.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/features/migration/domain/usecases/pick_files.dart';
import 'package:bacakomik_app/features/migration/domain/usecases/import_library.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

enum MihonImportPhase { idle, reading, loaded, importing, finished }

class MihonImportState {
  const MihonImportState({
    this.phase = MihonImportPhase.idle,
    this.groups = const [],
    this.selected = const {},
    this.installing = const {},
    this.result,
    this.error,
  });

  final MihonImportPhase phase;
  final List<MihonSourceGroup> groups;

  /// [MihonSourceGroup.id]s of the picked groups.
  final Set<String> selected;

  /// Extension ids being installed.
  final Set<String> installing;
  final ImportResult? result;
  final String? error;

  List<MihonSourceGroup> get supported =>
      groups.where((g) => g.supported).toList();

  List<MihonSourceGroup> get unsupported =>
      groups.where((g) => !g.supported).toList();

  int get selectedCount => supported
      .where((g) => selected.contains(g.id))
      .fold(0, (n, g) => n + g.entries.length);

  MihonImportState copyWith({
    MihonImportPhase? phase,
    List<MihonSourceGroup>? groups,
    Set<String>? selected,
    Set<String>? installing,
    ImportResult? result,
    String? error,
  }) => MihonImportState(
    phase: phase ?? this.phase,
    groups: groups ?? this.groups,
    selected: selected ?? this.selected,
    installing: installing ?? this.installing,
    result: result ?? this.result,
    error: error,
  );
}

/// Import from a Mihon/Tachiyomi backup: pick the file, see which sources
/// match (installing missing ones on the way), then bookmark the comics of
/// the picked sources with [ImportLibrary]. No source requests are made.
@injectable
class MihonImportCubit extends Cubit<MihonImportState> {
  MihonImportCubit(this._pickBackup, this._import, this._manager)
    : super(const MihonImportState());

  final PickMihonBackup _pickBackup;
  final ImportLibrary _import;
  final ExtensionManager _manager;
  MihonBackup? _backup;

  Future<void> pickFile() async {
    emit(state.copyWith(phase: MihonImportPhase.reading));
    final picked = await _pickBackup(const NoParams());
    if (isClosed) return;
    await picked.fold(
      (failure) async => emit(
        state.copyWith(
          phase: _backup == null
              ? MihonImportPhase.idle
              : MihonImportPhase.loaded,
          error: failure.message,
        ),
      ),
      (backup) async {
        if (backup == null) {
          emit(
            state.copyWith(
              phase: _backup == null
                  ? MihonImportPhase.idle
                  : MihonImportPhase.loaded,
            ),
          );
          return;
        }
        _backup = backup;
        // Fresh repo metadata knows the newest urlPatterns; offline, the
        // installed extensions are used alone.
        try {
          await _manager.catalog();
        } catch (_) {}
        if (isClosed) return;
        final groups = _plan();
        emit(
          MihonImportState(
            phase: MihonImportPhase.loaded,
            groups: groups,
            selected: {
              for (final g in groups)
                if (g.supported) g.id,
            },
          ),
        );
      },
    );
  }

  List<MihonSourceGroup> _plan() => planMihonImport(
    _backup!,
    [..._manager.extensions, ..._manager.offered],
    installed: {for (final e in _manager.extensions) e.id},
  );

  void toggle(String id) {
    final selected = {...state.selected};
    if (!selected.remove(id)) selected.add(id);
    emit(state.copyWith(selected: selected));
  }

  /// Whether the source of [group] is installed (its language enabled or
  /// not).
  bool isInstalled(MihonSourceGroup group) =>
      group.source != null && _manager.meta(group.source!.id) != null;

  /// Installs the extension of [group] from the repos and turns on its
  /// language.
  Future<void> install(MihonSourceGroup group) async {
    final source = group.source;
    if (source == null) return;
    final offered = _manager.offered
        .where((e) => e.sourceFor(source.id) != null)
        .firstOrNull;
    if (offered == null) {
      emit(state.copyWith(error: '${source.name}: not in your repos'));
      return;
    }
    emit(state.copyWith(installing: {...state.installing, offered.id}));
    String? error;
    try {
      await _manager.install(offered);
      await _enableLanguage(offered, source);
    } catch (e) {
      error = '$e';
    }
    if (isClosed) return;
    emit(
      state.copyWith(
        installing: {...state.installing}..remove(offered.id),
        error: error,
      ),
    );
  }

  Future<void> _enableLanguage(ExtensionMeta extension, ExtensionMeta source) {
    if (source.parentId == null) return Future.value();
    return _manager.setLanguages(
      extension.id,
      {..._manager.languagesOf(extension.id), source.lang}.toList(),
    );
  }

  Future<void> import() async {
    final groups = state.supported
        .where((g) => state.selected.contains(g.id))
        .toList();
    if (groups.isEmpty) return;
    emit(state.copyWith(phase: MihonImportPhase.importing));
    final result = await _import([for (final g in groups) ...g.entries]);
    if (isClosed) return;
    // A comic of a language that is installed but turned off still opens;
    // turn it on so it shows in the source picker too.
    for (final g in groups) {
      final source = g.source!;
      if (source.parentId case final extensionId?
          when _manager.meta(source.id) != null &&
              !_manager.languagesOf(extensionId).contains(source.lang)) {
        await _manager.setLanguages(
          extensionId,
          {..._manager.languagesOf(extensionId), source.lang}.toList(),
        );
      }
    }
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(phase: MihonImportPhase.loaded, error: failure.message),
      ),
      (result) => emit(
        state.copyWith(phase: MihonImportPhase.finished, result: result),
      ),
    );
  }
}
