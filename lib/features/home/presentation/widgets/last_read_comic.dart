import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/comic_detail/presentation/pages/comic_details_screen.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_progress.dart';
import 'package:bacakomik_app/features/history/presentation/bloc/history_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// "LANJUT BACA" card for the most recently read comic. Hidden when the
/// history is empty.
class LastReadComic extends StatelessWidget {
  const LastReadComic({super.key});

  @override
  Widget build(BuildContext context) {
    final latest = context.watch<HistoryCubit>().index.latest;
    if (latest == null) return const SizedBox.shrink();

    final c = Dotline.of(context);
    final details = latest.comicDetails;
    final progress = ReadProgress.of(details, latest.chapterNumber);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel(label: AppText.continueReading),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DotSpace.s4),
          child: Pressable(
            semanticLabel: '${AppText.continueReading} ${details.title}',
            onTap: () => ComicDetailsScreen.open(
              context,
              slug: latest.comicSlug,
              title: details.title,
              cover: details.coverImg,
            ),
            child: Container(
              padding: const EdgeInsets.all(DotSpace.s4),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(DotRadius.l),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 84,
                    child: ComicCover(imageUrl: details.coverImg),
                  ),
                  const SizedBox(width: DotSpace.s4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          [
                            if (details.type != '-') details.type,
                            details.status,
                          ].join(' · ').toUpperCase(),
                          style: DotlineText.label.copyWith(color: c.inkFaint),
                        ),
                        const SizedBox(height: DotSpace.s2),
                        Text(
                          details.title,
                          style: DotlineText.headline.copyWith(color: c.ink),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: DotSpace.s3),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              'CH. ',
                              style: DotlineText.data.copyWith(
                                color: c.inkFaint,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                progress.chapterNumber,
                                style: DotlineText.stat.copyWith(
                                  fontSize: 28,
                                  color: c.ink,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              ' / ${progress.latestNumber}',
                              style: DotlineText.data.copyWith(
                                color: c.inkFaint,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: DotSpace.s2),
                        DotMeter(
                          value: progress.position,
                          total: progress.total,
                          dots: 22,
                          gap: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
