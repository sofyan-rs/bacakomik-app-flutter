import 'package:bacakomik_app/core/constants/filters.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/explore/domain/entities/explore_filter.dart';
import 'package:bacakomik_app/features/explore/presentation/bloc/filter_cubit.dart';
import 'package:bacakomik_app/features/explore/presentation/bloc/genres_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// Filters shown on the Jelajah filter button: status, sort and genres.
/// Type is not counted because the segmented control already shows it.
int activeFilterCount(ExploreFilter filter) =>
    (filter.status != 'all' ? 1 : 0) +
    (filter.sortBy != const ExploreFilter().sortBy ? 1 : 0) +
    filter.genres.length;

/// "URUT: TERBARU · ONGOING" line above the Jelajah grid.
String filterSummary(ExploreFilter filter) {
  String name(List<FilterOption> options, String id) =>
      options.firstWhere((o) => o.id == id, orElse: () => options.first).name;

  return [
    '${AppText.sortShort}: ${name(Filters.sortbyList, filter.sortBy)}',
    if (filter.status != 'all') name(Filters.statusList, filter.status),
    if (filter.genres.isNotEmpty) '${filter.genres.length} ${AppText.genre}',
  ].join(' · ').toUpperCase();
}

/// Opens the filter sheet. Calls [onApply] after the filter is saved.
Future<void> showFilterSheet(
  BuildContext context, {
  required VoidCallback onApply,
}) {
  final cubit = context.read<FilterCubit>();
  final genres = context.read<GenresCubit>();
  return showDotSheet(
    context: context,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: cubit),
        BlocProvider.value(value: genres),
      ],
      child: FilterComic(onApply: onApply),
    ),
  );
}

/// Filter sheet content: single-select type, status and sort, multi-select
/// genres. Changes apply only on "Tampilkan hasil".
class FilterComic extends StatefulWidget {
  const FilterComic({super.key, required this.onApply});

  final VoidCallback onApply;

  @override
  State<FilterComic> createState() => _FilterComicState();
}

class _FilterComicState extends State<FilterComic> {
  late ExploreFilter _filter = context.read<FilterCubit>().state;

  void _apply() {
    context.read<FilterCubit>().setFilter(
      type: _filter.type,
      status: _filter.status,
      sortBy: _filter.sortBy,
      genres: _filter.genres,
    );
    widget.onApply();
    Navigator.of(context).pop();
  }

  void _toggleGenre(String id) {
    final genres = [..._filter.genres];
    genres.contains(id) ? genres.remove(id) : genres.add(id);
    setState(() => _filter = _filter.copyWith(genres: genres));
  }

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final genreCount = _filter.genres.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                AppText.filter,
                style: DotlineText.title.copyWith(color: c.ink),
              ),
            ),
            GestureDetector(
              // Reset clears the filters, not the search text.
              onTap: () => setState(
                () => _filter = ExploreFilter(query: _filter.query),
              ),
              child: Padding(
                padding: const EdgeInsets.all(DotSpace.s3),
                child: Text(
                  AppText.reset,
                  style: DotlineText.body.copyWith(color: c.inkMuted),
                ),
              ),
            ),
            RoundIconButton(
              icon: LucideIcons300.x,
              semanticLabel: AppText.close,
              background: Colors.transparent,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: DotSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Section(
                  label: AppText.type,
                  options: Filters.typeList,
                  isSelected: (id) => _filter.type == id,
                  onTap: (id) =>
                      setState(() => _filter = _filter.copyWith(type: id)),
                ),
                _Section(
                  label: AppText.status,
                  options: Filters.statusList,
                  isSelected: (id) => _filter.status == id,
                  onTap: (id) =>
                      setState(() => _filter = _filter.copyWith(status: id)),
                ),
                _Section(
                  label: AppText.sortShortLong,
                  options: Filters.sortbyList,
                  isSelected: (id) => _filter.sortBy == id,
                  onTap: (id) =>
                      setState(() => _filter = _filter.copyWith(sortBy: id)),
                ),
                _Section(
                  label: genreCount == 0
                      ? AppText.genre
                      : '${AppText.genre} · $genreCount ${AppText.selected}',
                  options: context.watch<GenresCubit>().state,
                  isSelected: _filter.genres.contains,
                  onTap: _toggleGenre,
                ),
              ],
            ),
          ),
        ),
        const Divider(),
        const SizedBox(height: DotSpace.s4),
        DotButton(label: AppText.showResults, onTap: _apply),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.label,
    required this.options,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final List<FilterOption> options;
  final bool Function(String id) isSelected;
  final void Function(String id) onTap;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: DotSpace.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: DotlineText.label.copyWith(color: c.inkFaint),
          ),
          const SizedBox(height: DotSpace.s3),
          Wrap(
            spacing: DotSpace.s2,
            runSpacing: DotSpace.s2,
            children: [
              for (final option in options)
                DotChip(
                  label: option.name,
                  selected: isSelected(option.id),
                  onTap: () => onTap(option.id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
