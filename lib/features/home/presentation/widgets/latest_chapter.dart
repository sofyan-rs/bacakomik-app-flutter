import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:bacakomik_app/features/home/presentation/widgets/latest_chapter_card.dart';
import 'package:bacakomik_app/features/latest/presentation/pages/latest_chapter_screen.dart';
import 'package:bacakomik_app/features/source/presentation/bloc/sources_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// "LATEST CHAPTERS" section of the home tab.
class LatestChapter extends StatelessWidget {
  const LatestChapter({super.key, required this.state});

  final HomeLoaded state;

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
          child: ListGroup(
            children: [
              for (final latest in state.home.latest)
                LatestChapterCard(
                  title: latest.title,
                  cover: latest.coverImg,
                  chapter: latest.latestChapter,
                  type: latest.type,
                  isCompleted: latest.completed,
                  slug: latest.slug,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
