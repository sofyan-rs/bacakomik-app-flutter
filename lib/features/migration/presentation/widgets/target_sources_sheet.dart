import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/migration/presentation/widgets/source_choice_sheet.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// Picks the sources to migrate to, in the order they are searched: a comic
/// not found in the first is looked up in the second, and so on. Picked
/// sources are dragged to reorder. Pops the ids, or null when dismissed.
Future<List<String>?> showTargetSourcesSheet(
  BuildContext context, {
  required List<SourceChoice> choices,
  required List<String> selected,
}) => showDotSheet<List<String>>(
  context: context,
  builder: (_) => _TargetSourcesSheet(choices: choices, selected: selected),
);

class _TargetSourcesSheet extends StatefulWidget {
  const _TargetSourcesSheet({required this.choices, required this.selected});

  final List<SourceChoice> choices;
  final List<String> selected;

  @override
  State<_TargetSourcesSheet> createState() => _TargetSourcesSheetState();
}

class _TargetSourcesSheetState extends State<_TargetSourcesSheet> {
  late final _picked = [
    for (final id in widget.selected)
      ?widget.choices.where((c) => c.id == id).firstOrNull,
  ];

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final others = [
      for (final choice in widget.choices)
        if (!_picked.any((p) => p.id == choice.id)) choice,
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppText.migrateTo,
          style: DotlineText.title.copyWith(color: c.ink),
        ),
        const SizedBox(height: DotSpace.s1),
        Text(
          AppText.migrateToOrderHint,
          style: DotlineText.bodyS.copyWith(color: c.inkFaint),
        ),
        const SizedBox(height: DotSpace.s4),
        if (widget.choices.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: DotSpace.s5),
            child: Text(
              AppText.noOtherSource,
              style: DotlineText.body.copyWith(color: c.inkMuted),
              textAlign: TextAlign.center,
            ),
          ),
        Flexible(
          child: CustomScrollView(
            shrinkWrap: true,
            slivers: [
              SliverReorderableList(
                itemCount: _picked.length,
                onReorderItem: (from, to) =>
                    setState(() => _picked.insert(to, _picked.removeAt(from))),
                itemBuilder: (context, i) {
                  final choice = _picked[i];
                  return Padding(
                    key: ValueKey(choice.id),
                    padding: const EdgeInsets.only(bottom: DotSpace.s2),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(DotRadius.m),
                      child: ColoredBox(
                        color: c.bg,
                        child: ListRow(
                          leading: ReorderableDragStartListener(
                            index: i,
                            child: Icon(
                              LucideIcons300.gripVertical,
                              color: c.inkFaint,
                            ),
                          ),
                          title: '${i + 1}. ${choice.name}',
                          subtitle: choice.detail,
                          trailing: RoundIconButton(
                            icon: LucideIcons300.x,
                            semanticLabel: AppText.removeSource,
                            size: 36,
                            iconSize: DotSize.iconSmall,
                            background: Colors.transparent,
                            onTap: () => setState(() => _picked.removeAt(i)),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (others.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: _picked.isEmpty ? 0 : DotSpace.s2,
                    ),
                    child: ListGroup(
                      background: c.bg,
                      children: [
                        for (final choice in others)
                          ListRow(
                            icon: LucideIcons300.plus,
                            title: choice.name,
                            subtitle: choice.detail,
                            onTap: () => setState(() => _picked.add(choice)),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: DotSpace.s4),
        DotButton(
          label: AppText.done,
          onTap: _picked.isEmpty
              ? null
              : () =>
                    Navigator.of(context).pop([for (final p in _picked) p.id]),
        ),
      ],
    );
  }
}
