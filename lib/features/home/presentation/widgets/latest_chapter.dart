import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:bacakomik_app/features/home/presentation/widgets/latest_chapter_card.dart';
import 'package:bacakomik_app/features/latest/presentation/pages/latest_chapter_screen.dart';
import 'package:bacakomik_app/features/source/presentation/bloc/sources_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// "LATEST CHAPTERS" section of the home tab: one list on phones, up to
/// three side by side on wide screens (each at least [_minColumnWidth]).
class LatestChapter extends StatelessWidget {
  const LatestChapter({super.key, required this.state});

  final HomeLoaded state;

  static const _minColumnWidth = 360.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(
          label:
              context.watch<SourcesCubit>().state.features.latestLabel ??
              AppText.latest,
          actionLabel: AppText.seeAll,
          onAction: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LatestChapterScreen()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DotSpace.s4),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final rows = [
                for (final latest in state.home.latest)
                  LatestChapterCard(
                    title: latest.title,
                    cover: latest.coverImg,
                    chapter: latest.latestChapter,
                    type: latest.type,
                    isCompleted: latest.completed,
                    slug: latest.slug,
                  ),
              ];
              final columns = (constraints.maxWidth / _minColumnWidth)
                  .floor()
                  .clamp(1, 3);
              if (columns == 1 || rows.length < 2) {
                return ListGroup(children: rows);
              }
              // Even columns: drop the remainder, "see all" still has it.
              // Filled top to bottom, so each group reads as its own list.
              if (rows.length > columns) rows.length -= rows.length % columns;
              final perColumn = (rows.length / columns).ceil();
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: DotSpace.s3,
                children: [
                  for (var c = 0; c < columns; c++)
                    Expanded(
                      child: c * perColumn < rows.length
                          ? ListGroup(
                              children: rows.sublist(
                                c * perColumn,
                                ((c + 1) * perColumn).clamp(0, rows.length),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
