import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/source/extension_meta.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/explore/domain/entities/explore_filter.dart';
import 'package:bacakomik_app/features/explore/presentation/bloc/filter_cubit.dart';
import 'package:bacakomik_app/features/source/presentation/bloc/sources_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// Whether [group] has a value other than its default in [filter].
bool _isSet(ExploreFilter filter, FilterGroup group) {
  final value = filter.values[group.key];
  return value != null && !listEquals(value, group.defaults);
}

/// Filters shown on the Explore filter button: every group set away from
/// its default, multi groups by their picked count. The quick group is not
/// counted because its picker is already on screen.
int activeFilterCount(ExploreFilter filter, SourceFeatures source) => [
  for (final group in source.groups)
    if (!group.quick && _isSet(filter, group))
      group.multi ? filter.values[group.key]!.length : 1,
].fold(0, (a, b) => a + b);

/// "LATEST UPDATE · ONGOING · 2 GENRE" line above the Explore grid: the
/// first group (usually the sort) always, the rest when set.
String filterSummary(ExploreFilter filter, SourceFeatures source) {
  final parts = <String>[];
  for (final (i, group) in source.groups.indexed) {
    if (group.quick || (i > 0 && !_isSet(filter, group))) continue;
    final value = source.valueOf(filter.values, group.key);
    if (group.multi) {
      if (value.isNotEmpty) parts.add('${value.length} ${group.label}');
    } else if (value.isNotEmpty) {
      parts.add(group.labelOf(value.first));
    }
  }
  return parts.join(' · ').toUpperCase();
}

/// Opens the filter sheet. Calls [onApply] after the filter is saved.
Future<void> showFilterSheet(
  BuildContext context, {
  required VoidCallback onApply,
}) {
  final cubit = context.read<FilterCubit>();
  final sources = context.read<SourcesCubit>();
  return showDotSheet(
    context: context,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: cubit),
        BlocProvider.value(value: sources),
      ],
      child: FilterComic(onApply: onApply),
    ),
  );
}

/// Filter sheet content: one section per filter group of the source,
/// single-select or multi-select. Changes apply only on "Show results".
class FilterComic extends StatefulWidget {
  const FilterComic({super.key, required this.onApply});

  final VoidCallback onApply;

  @override
  State<FilterComic> createState() => _FilterComicState();
}

class _FilterComicState extends State<FilterComic> {
  late FilterValues _values = {...context.read<FilterCubit>().state.values};

  void _apply() {
    context.read<FilterCubit>().setValues(_values);
    widget.onApply();
    Navigator.of(context).pop();
  }

  void _tap(FilterGroup group, String value) {
    setState(() {
      if (!group.multi) {
        _values = {
          ..._values,
          group.key: [value],
        };
        return;
      }
      final current = [...?_values[group.key]];
      current.contains(value) ? current.remove(value) : current.add(value);
      _values = {..._values, group.key: current};
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final source = context.watch<SourcesCubit>().state.features;

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
              onTap: () => setState(() => _values = {}),
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
                if (source.groups.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: DotSpace.s5),
                    child: Text(
                      AppText.noFilters,
                      style: DotlineText.body.copyWith(color: c.inkMuted),
                    ),
                  ),
                for (final group in source.groups)
                  if (group.options.isNotEmpty)
                    _Section(
                      group: group,
                      selected: source.valueOf(_values, group.key),
                      onTap: (value) => _tap(group, value),
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
    required this.group,
    required this.selected,
    required this.onTap,
  });

  final FilterGroup group;
  final List<String> selected;
  final void Function(String value) onTap;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final label = group.multi && selected.isNotEmpty
        ? '${group.label} · ${selected.length} ${AppText.selected}'
        : group.label;
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
              for (final option in group.options)
                DotChip(
                  label: option.label,
                  selected: selected.contains(option.value),
                  onTap: () => onTap(option.value),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
