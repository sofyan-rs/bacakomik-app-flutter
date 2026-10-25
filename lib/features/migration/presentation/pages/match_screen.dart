import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/di/injection.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/source/extension_manager.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/bookmark/presentation/bloc/bookmark_cubit.dart';
import 'package:bacakomik_app/features/category/presentation/bloc/category_cubit.dart';
import 'package:bacakomik_app/features/history/presentation/bloc/history_cubit.dart';
import 'package:bacakomik_app/features/migration/presentation/bloc/match_cubit.dart';
import 'package:bacakomik_app/features/migration/presentation/widgets/match_search_sheet.dart';
import 'package:bacakomik_app/features/source/presentation/widgets/missing_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Looks up [items] by title in [target], lets the user fix the matches,
/// then migrates or imports them ([MatchMode]).
class MatchScreen extends StatelessWidget {
  const MatchScreen({
    super.key,
    required this.mode,
    required this.target,
    required this.items,
  });

  final MatchMode mode;
  final String target;
  final List<MatchItem> items;

  static Future<void> open(
    BuildContext context, {
    required MatchMode mode,
    required String target,
    required List<MatchItem> items,
  }) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => MatchScreen(mode: mode, target: target, items: items),
    ),
  );

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<MatchCubit>(),
    child: _MatchView(mode: mode, target: target, items: items),
  );
}

class _MatchView extends StatefulWidget {
  const _MatchView({
    required this.mode,
    required this.target,
    required this.items,
  });

  final MatchMode mode;
  final String target;
  final List<MatchItem> items;

  @override
  State<_MatchView> createState() => _MatchViewState();
}

class _MatchViewState extends State<_MatchView> {
  final _manager = getIt<ExtensionManager>();
  late var _installed = _manager.meta(widget.target) != null;
  var _started = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _installed = _manager.meta(widget.target) != null;
    if (!_installed || _started) return;
    _started = true;
    context.read<MatchCubit>().start(
      mode: widget.mode,
      target: widget.target,
      items: widget.items,
    );
  }

  Future<void> _fix(int index, MatchItem item) async {
    final cubit = context.read<MatchCubit>();
    final picked = await showMatchSearchSheet(
      context,
      cubit: cubit,
      title: item.title,
    );
    if (picked == null) return;
    switch (picked) {
      case MatchPick(:final comic?):
        cubit.pick(index, comic);
      case MatchPick():
        cubit.skip(index);
    }
  }

  /// The library changed: reload what shows it.
  void _onFinished(BuildContext context) {
    context.read<BookmarkCubit>().load();
    context.read<HistoryCubit>().load();
    context.read<CategoryCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final target = _manager.nameOf(widget.target);
    final title = widget.mode == MatchMode.migrate
        ? AppText.migrateSource
        : AppText.importComix;
    if (!_installed) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              DotTopBar(title: title),
              Expanded(
                child: MissingSource(
                  sourceId: widget.target,
                  onInstalled: () => setState(_start),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return BlocConsumer<MatchCubit, MatchState>(
      listenWhen: (a, b) =>
          a.phase != b.phase && b.phase == MatchPhase.finished,
      listener: (context, _) => _onFinished(context),
      builder: (context, state) {
        final c = Dotline.of(context);
        return PopScope(
          canPop: state.phase != MatchPhase.applying,
          child: Scaffold(
            body: SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: DotTopBar(
                      title: title,
                      subtitle: '${AppText.migrateTo} $target',
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        DotSpace.s4,
                        0,
                        DotSpace.s4,
                        DotSpace.s4,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _summary(state),
                            style: DotlineText.label.copyWith(color: c.ink),
                          ),
                          if (state.phase == MatchPhase.searching) ...[
                            const SizedBox(height: DotSpace.s2),
                            DotMeter(
                              value: state.searched,
                              total: state.items.length,
                            ),
                            const SizedBox(height: DotSpace.s2),
                            Text(
                              AppText.searchingSlowly,
                              style: DotlineText.bodyS.copyWith(
                                color: c.inkFaint,
                              ),
                            ),
                          ],
                          if (state.phase == MatchPhase.finished &&
                              widget.mode == MatchMode.import) ...[
                            const SizedBox(height: DotSpace.s2),
                            Text(
                              AppText.importLoadHint,
                              style: DotlineText.bodyS.copyWith(
                                color: c.inkFaint,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SliverListGroup(
                    itemCount: state.items.length,
                    itemBuilder: (context, i) => _MatchRow(
                      item: state.items[i],
                      onTap:
                          state.phase == MatchPhase.applying ||
                              state.phase == MatchPhase.finished
                          ? null
                          : () => _fix(i, state.items[i]),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: DotSpace.s4),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(DotSpace.s4),
                child: _action(context, state),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _action(BuildContext context, MatchState state) {
    final migrate = widget.mode == MatchMode.migrate;
    return switch (state.phase) {
      MatchPhase.finished => DotButton(
        label: AppText.done,
        onTap: () => Navigator.of(context).pop(),
      ),
      MatchPhase.applying => DotButton(
        label: migrate ? AppText.migrating : AppText.importing,
        onTap: null,
      ),
      _ => DotButton(
        label:
            '${migrate ? AppText.migrateCount : AppText.importCount} '
            '${AppText.count(state.readyCount, AppText.comic, AppText.comics)}',
        // Applying while searching would leave out comics found later.
        onTap: state.readyCount == 0 || state.phase == MatchPhase.searching
            ? null
            : () => context.read<MatchCubit>().apply(),
      ),
    };
  }

  String _summary(MatchState state) {
    final total = state.items.length;
    return switch (state.phase) {
      MatchPhase.searching =>
        '${AppText.matchSearching} ${state.searched} / $total',
      MatchPhase.review || MatchPhase.applying =>
        '${state.readyCount} / $total ${AppText.matchesFound}',
      MatchPhase.finished => switch (state.result) {
        final result? =>
          '${AppText.importDone} · ${result.added} ${AppText.added}'
              '${result.existing > 0 ? ' · ${result.existing} ${AppText.alreadyInLibrary}' : ''}'
              '${result.sameTitle > 0 ? ' · ${result.sameTitle} ${AppText.sameTitleElsewhere}' : ''}',
        null =>
          '${AppText.migrationDone} · ${state.count(MatchStatus.done)} / $total'
              '${state.count(MatchStatus.error) > 0 ? ' · ${state.count(MatchStatus.error)} ${AppText.failed}' : ''}',
      },
    };
  }
}

class _MatchRow extends StatelessWidget {
  const _MatchRow({required this.item, required this.onTap});

  final MatchItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final match = item.match;
    final (status, color) = switch (item.status) {
      MatchStatus.waiting => (AppText.matchWaiting, c.inkFaint),
      MatchStatus.searching => (AppText.matchSearching, c.inkFaint),
      MatchStatus.found => (match?.title ?? '', c.inkMuted),
      MatchStatus.notFound => (AppText.matchNotFound, c.accentText),
      MatchStatus.failed => (AppText.matchFailed, c.accentText),
      MatchStatus.skipped => (AppText.matchSkipped, c.inkFaint),
      MatchStatus.done => (
        item.fromKey != null ? AppText.matchMigrated : match?.title ?? '',
        c.positive,
      ),
      MatchStatus.error => (
        '${AppText.matchMigrateFailed}: ${item.message ?? ''}',
        c.accentText,
      ),
    };
    return ListRow(
      leading: SizedBox(
        width: 40,
        child: ComicCover(imageUrl: match?.coverImg ?? ''),
      ),
      title: item.title,
      subtitleWidget: Text(
        [
          status,
          if (item.lastRead case final chapter?) '${AppText.readTo} $chapter',
        ].join(' · '),
        style: DotlineText.bodyS.copyWith(color: color),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onTap,
      showChevron: onTap != null,
    );
  }
}
