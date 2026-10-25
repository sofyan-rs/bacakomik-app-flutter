import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/history/presentation/bloc/history_cubit.dart';
import 'package:bacakomik_app/features/history/presentation/widgets/history_comic_card.dart';
import 'package:bacakomik_app/features/history/presentation/widgets/history_groups.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// History tab: last read chapter per comic, grouped by day.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  Future<void> _confirmClearAll(BuildContext context) async {
    final cubit = context.read<HistoryCubit>();
    final confirmed = await showDotSheet<bool>(
      context: context,
      builder: (context) {
        final c = Dotline.of(context);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ActionSheetHeader(
              icon: LucideIcons300.trash2,
              title: AppText.clearHistory,
            ),
            const SizedBox(height: DotSpace.s4),
            Text(
              AppText.clearHistoryConfirmation,
              style: DotlineText.body.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: DotSpace.s5),
            DotButton.destructive(
              label: AppText.clearHistory,
              onTap: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: DotSpace.s3),
            DotButton.outline(
              label: AppText.cancel,
              onTap: () => Navigator.of(context).pop(false),
            ),
          ],
        );
      },
    );
    if (confirmed == true) await cubit.clearHistory();
  }

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final latest = context.watch<HistoryCubit>().latestHistories;
    final days = HistoryDay.group(latest, DateTime.now());
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SlidableAutoCloseBehavior(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: ScreenHeader(
                  title: AppText.historyTab,
                  subtitle: latest.isEmpty
                      ? null
                      : '${AppText.count(latest.length, AppText.comic, AppText.comics)} · '
                            '${AppText.swipeToDelete}',
                  actions: [
                    if (latest.isNotEmpty)
                      RoundIconButton(
                        icon: LucideIcons300.trash2,
                        semanticLabel: AppText.clearHistory,
                        iconSize: DotSize.iconSmall,
                        onTap: () => _confirmClearAll(context),
                      ),
                  ],
                ),
              ),
              if (latest.isEmpty)
                const SliverToBoxAdapter(
                  child: EmptyState(
                    icon: LucideIcons300.history,
                    title: AppText.historyEmpty,
                    message: AppText.historyEmptyHint,
                  ),
                ),
              for (final day in days) ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    DotSpace.s4,
                    0,
                    DotSpace.s4,
                    DotSpace.s3,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      day.label.toUpperCase(),
                      style: DotlineText.label.copyWith(color: c.inkFaint),
                    ),
                  ),
                ),
                SliverListGroup(
                  itemCount: day.items.length,
                  itemBuilder: (context, index) =>
                      HistoryComicCard(item: day.items[index]),
                ),
                const SliverPadding(
                  padding: EdgeInsets.only(bottom: DotSpace.s5),
                ),
              ],
              SliverPadding(padding: EdgeInsets.only(bottom: bottomInset)),
            ],
          ),
        ),
      ),
    );
  }
}
