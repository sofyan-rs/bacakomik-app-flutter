import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/settings/domain/entities/app_settings.dart';
import 'package:bacakomik_app/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// "Reader settings": direction, page size, keep awake, page gap,
/// progress bar, infinite scroll, auto-scroll speed. Saved
/// right away through [SettingsCubit].
class ReaderSettingsSheet extends StatelessWidget {
  const ReaderSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final settings = context.watch<SettingsCubit>().state;
    final cubit = context.read<SettingsCubit>();

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(top: DotSpace.s5, bottom: DotSpace.s3),
      child: Text(
        text.toUpperCase(),
        style: DotlineText.label.copyWith(color: c.inkFaint),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppText.readerSettings,
          style: DotlineText.title.copyWith(color: c.ink),
        ),
        label(AppText.readingDirection),
        SegmentedControl<ReadingDirection>(
          background: c.bg,
          selected: settings.readingDirection,
          onChanged: (d) =>
              cubit.update((s) => s.copyWith(readingDirection: d)),
          segments: const [
            Segment(
              value: ReadingDirection.vertical,
              label: AppText.directionVertical,
            ),
            Segment(
              value: ReadingDirection.rightToLeft,
              label: AppText.directionRtl,
            ),
            Segment(
              value: ReadingDirection.leftToRight,
              label: AppText.directionLtr,
            ),
          ],
        ),
        label(AppText.pageSize),
        SegmentedControl<PageFit>(
          background: c.bg,
          selected: settings.pageFit,
          onChanged: (f) => cubit.update((s) => s.copyWith(pageFit: f)),
          segments: const [
            Segment(value: PageFit.width, label: AppText.fitWidth),
            Segment(value: PageFit.height, label: AppText.fitHeight),
          ],
        ),
        const SizedBox(height: DotSpace.s5),
        ListGroup(
          background: c.bg,
          children: [
            ListRow(
              title: AppText.keepScreenOn,
              subtitle: AppText.keepScreenOnHint,
              trailing: DotSwitch(
                value: settings.keepScreenOn,
                semanticLabel: AppText.keepScreenOn,
                onChanged: (v) =>
                    cubit.update((s) => s.copyWith(keepScreenOn: v)),
              ),
              onTap: () => cubit.update(
                (s) => s.copyWith(keepScreenOn: !s.keepScreenOn),
              ),
            ),
            ListRow(
              title: AppText.pageGap,
              subtitle: AppText.pageGapHint,
              trailing: DotSwitch(
                value: settings.pageGap,
                semanticLabel: AppText.pageGap,
                onChanged: (v) => cubit.update((s) => s.copyWith(pageGap: v)),
              ),
              onTap: () => cubit.update((s) => s.copyWith(pageGap: !s.pageGap)),
            ),
            ListRow(
              title: AppText.progressBar,
              subtitle: AppText.progressBarHint,
              trailing: DotSwitch(
                value: settings.progressBar,
                semanticLabel: AppText.progressBar,
                onChanged: (v) =>
                    cubit.update((s) => s.copyWith(progressBar: v)),
              ),
              onTap: () =>
                  cubit.update((s) => s.copyWith(progressBar: !s.progressBar)),
            ),
            ListRow(
              title: AppText.infiniteScroll,
              subtitle: AppText.infiniteScrollHint,
              trailing: DotSwitch(
                value: settings.infiniteScroll,
                semanticLabel: AppText.infiniteScroll,
                onChanged: (v) =>
                    cubit.update((s) => s.copyWith(infiniteScroll: v)),
              ),
              onTap: () => cubit.update(
                (s) => s.copyWith(infiniteScroll: !s.infiniteScroll),
              ),
            ),
            ListRow(
              title: AppText.autoScrollSpeed,
              subtitle: AppText.autoScrollHint,
              trailing: _SpeedStepper(
                value: settings.autoScrollSpeed,
                onChanged: (v) =>
                    cubit.update((s) => s.copyWith(autoScrollSpeed: v)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// `-  3  +` for the auto-scroll speed level.
class _SpeedStepper extends StatelessWidget {
  const _SpeedStepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RoundIconButton(
          icon: LucideIcons300.minus,
          semanticLabel: AppText.slower,
          size: 36,
          iconSize: DotSize.iconSmall,
          onTap: value > autoScrollMin ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 32,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: DotlineText.data.copyWith(color: c.ink),
          ),
        ),
        RoundIconButton(
          icon: LucideIcons300.plus,
          semanticLabel: AppText.faster,
          size: 36,
          iconSize: DotSize.iconSmall,
          onTap: value < autoScrollMax ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}
