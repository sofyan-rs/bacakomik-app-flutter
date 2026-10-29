import 'package:bacakomik_app/core/utils/alt_titles.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/di/injection.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/source/extension_manager.dart';
import 'package:bacakomik_app/core/source/comic_key.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';
import 'package:bacakomik_app/features/bookmark/presentation/bloc/bookmark_cubit.dart';
import 'package:bacakomik_app/features/migration/presentation/bloc/match_cubit.dart';
import 'package:bacakomik_app/features/migration/presentation/pages/match_screen.dart';
import 'package:bacakomik_app/features/migration/presentation/widgets/source_choice_sheet.dart';
import 'package:bacakomik_app/features/migration/presentation/widgets/target_sources_sheet.dart';
import 'package:bacakomik_app/features/source/presentation/bloc/sources_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// Picks bookmarks and the target sources, in search order, for
/// [MatchScreen] in
/// [MatchMode.migrate]. Opened from Migration with every bookmark of one
/// source, or with [keys] preselected (a selection in Bookmarks, or one
/// comic from its page).
class SourceMigrationScreen extends StatefulWidget {
  const SourceMigrationScreen({super.key, this.keys});

  /// Bookmarks to migrate; null to pick a source first.
  final Set<String>? keys;

  static Future<void> open(BuildContext context, {Set<String>? keys}) =>
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SourceMigrationScreen(keys: keys)),
      );

  @override
  State<SourceMigrationScreen> createState() => _SourceMigrationScreenState();
}

class _SourceMigrationScreenState extends State<SourceMigrationScreen> {
  final _manager = getIt<ExtensionManager>();
  String? _from;

  /// Sources to migrate to, searched in this order.
  var _to = <String>[];

  /// Keys of the checked bookmarks.
  late final Set<String> _checked = {...?widget.keys};

  List<Bookmark> _candidates(List<Bookmark> bookmarks) {
    final keys = widget.keys;
    return [
      for (final b in bookmarks)
        if (keys != null
            ? keys.contains(b.slug)
            : ComicKey.sourceOf(b.slug) == _from)
          b,
    ];
  }

  Future<void> _pickFrom(List<Bookmark> bookmarks) async {
    final counts = <String, int>{};
    for (final b in bookmarks) {
      counts.update(ComicKey.sourceOf(b.slug), (n) => n + 1, ifAbsent: () => 1);
    }
    final picked = await showSourceChoiceSheet(
      context,
      title: AppText.migrateFrom,
      selected: _from,
      choices: [
        for (final MapEntry(key: id, value: count) in counts.entries)
          (
            id: id,
            name: _manager.nameOf(id),
            detail: AppText.count(count, AppText.comic, AppText.comics),
          ),
      ]..sort((a, b) => a.name.compareTo(b.name)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _from = picked;
      _to = [..._to]..remove(picked);
      _checked
        ..clear()
        ..addAll([
          for (final b in bookmarks)
            if (ComicKey.sourceOf(b.slug) == picked) b.slug,
        ]);
    });
  }

  Future<void> _pickTo() async {
    final sources = context.read<SourcesCubit>().state.installed;
    // Preselected comics all from one source: that source is no target.
    final keys = widget.keys;
    final only = keys == null
        ? null
        : {for (final k in keys) ComicKey.sourceOf(k)};
    final from = _from ?? (only?.length == 1 ? only!.single : null);
    final picked = await showTargetSourcesSheet(
      context,
      selected: _to,
      choices: [
        for (final s in sources)
          if (s.id != from) (id: s.id, name: s.name, detail: s.domain),
      ],
    );
    if (picked != null && mounted) setState(() => _to = picked);
  }

  /// Checked and with a target other than its own source.
  bool _movable(Bookmark b) =>
      _checked.contains(b.slug) &&
      _to.any((t) => t != ComicKey.sourceOf(b.slug));

  void _findMatches(List<Bookmark> candidates) {
    if (_to.isEmpty) return;
    MatchScreen.open(
      context,
      mode: MatchMode.migrate,
      targets: _to,
      items: [
        for (final b in candidates)
          if (_movable(b))
            MatchItem(
              title: b.comicDetails.title,
              altTitles: splitAltTitles(
                b.comicDetails.title,
                b.comicDetails.alternativeTitle,
              ),
              fromKey: b.slug,
            ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final bookmarks = context.watch<BookmarkCubit>().state;
    final candidates = _candidates(bookmarks);
    final sources = context.watch<SourcesCubit>().state;
    final toNames = [
      for (final id in _to)
        sources.installed.where((s) => s.id == id).firstOrNull?.name ??
            _manager.nameOf(id),
    ];
    final count = candidates.where(_movable).length;
    final allChecked = candidates.every((b) => _checked.contains(b.slug));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Outside the scroll view so the title stays put.
            const DotTopBar(title: AppText.migrateSource),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        DotSpace.s4,
                        0,
                        DotSpace.s4,
                        DotSpace.s4,
                      ),
                      child: ListGroup(
                        children: [
                          if (widget.keys == null)
                            ListRow(
                              icon: LucideIcons300.bookmark,
                              title: AppText.migrateFrom,
                              value: _from == null
                                  ? AppText.pickSource
                                  : _manager.nameOf(_from!),
                              showChevron: true,
                              onTap: bookmarks.isEmpty
                                  ? null
                                  : () => _pickFrom(bookmarks),
                            ),
                          ListRow(
                            icon: LucideIcons300.arrowRightLeft,
                            title: AppText.migrateTo,
                            // Several in order below, too long for a value.
                            subtitle: toNames.length > 1
                                ? toNames.join(' → ')
                                : null,
                            value: switch (toNames) {
                              [] => AppText.pickSource,
                              [final name] => name,
                              _ => AppText.count(
                                toNames.length,
                                AppText.sourceLower,
                                AppText.sourcesLower,
                              ),
                            },
                            showChevron: true,
                            onTap: _pickTo,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (bookmarks.isEmpty)
                    const SliverToBoxAdapter(
                      child: EmptyState(
                        icon: LucideIcons300.bookmark,
                        title: AppText.noBookmarksToMigrate,
                        message: AppText.noBookmarksToMigrateHint,
                      ),
                    )
                  else if (candidates.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          DotSpace.s4,
                          0,
                          DotSpace.s4,
                          DotSpace.s2,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${_checked.length} / ${candidates.length} '
                                        '${AppText.selected}'
                                    .toUpperCase(),
                                style: DotlineText.label.copyWith(
                                  color: c.inkFaint,
                                ),
                              ),
                            ),
                            Pressable(
                              semanticLabel: allChecked
                                  ? AppText.selectNone
                                  : AppText.selectAll,
                              onTap: () => setState(() {
                                if (allChecked) {
                                  _checked.clear();
                                } else {
                                  _checked.addAll(
                                    candidates.map((b) => b.slug),
                                  );
                                }
                              }),
                              child: Padding(
                                padding: const EdgeInsets.all(DotSpace.s2),
                                child: Text(
                                  allChecked
                                      ? AppText.selectNone
                                      : AppText.selectAll,
                                  style: DotlineText.body.copyWith(
                                    color: c.inkMuted,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverListGroup(
                      itemCount: candidates.length,
                      itemBuilder: (context, i) {
                        final b = candidates[i];
                        final checked = _checked.contains(b.slug);
                        void toggle() => setState(
                          () => checked
                              ? _checked.remove(b.slug)
                              : _checked.add(b.slug),
                        );
                        return ListRow(
                          leading: SizedBox(
                            width: 40,
                            child: ComicCover(
                              imageUrl: b.comicDetails.coverImg,
                            ),
                          ),
                          title: b.comicDetails.title,
                          subtitle: widget.keys == null
                              ? null
                              : context.sourceNameOf(b.slug),
                          onTap: toggle,
                          trailing: Checkbox(
                            value: checked,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            activeColor: c.ink,
                            checkColor: c.onInk,
                            onChanged: (_) => toggle(),
                          ),
                        );
                      },
                    ),
                  ],
                  const SliverToBoxAdapter(
                    child: SizedBox(height: DotSpace.s4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(DotSpace.s4),
          child: DotButton(
            label:
                '${AppText.findMatches} · '
                '${AppText.count(count, AppText.comic, AppText.comics)}',
            leading: LucideIcons300.search,
            onTap: _to.isEmpty || count == 0
                ? null
                : () => _findMatches(candidates),
          ),
        ),
      ),
    );
  }
}
