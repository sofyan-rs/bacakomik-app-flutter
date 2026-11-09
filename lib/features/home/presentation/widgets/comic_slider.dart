import 'package:yoru/core/constants/texts.dart';
import 'package:yoru/core/presentation/widgets/dotline/dotline.dart';
import 'package:yoru/core/theme/dotline_tokens.dart';
import 'package:yoru/features/home/presentation/bloc/home_bloc.dart';
import 'package:yoru/features/home/presentation/widgets/comic_slider_card.dart';
import 'package:yoru/features/source/presentation/bloc/sources_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// "NEW SERIES" horizontal strip.
class ComicSlider extends StatelessWidget {
  const ComicSlider({super.key, required this.state, this.inset = 0});

  final HomeLoaded state;

  /// Space on each side of the home column. The label stays inside it; the
  /// strip starts in line with the column but scrolls out to the window
  /// edges, so a card cut off at the edge reads as "more this way".
  final double inset;

  @override
  Widget build(BuildContext context) {
    final newSeries = state.home.newSeries;
    final cardWidth = MediaQuery.sizeOf(context).width >= DotSize.splitMinWidth
        ? ComicSliderCard.wideWidth
        : ComicSliderCard.phoneWidth;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: inset),
          child: SectionLabel(
            label:
                context.watch<SourcesCubit>().state.features.featuredLabel ??
                AppText.newSeries,
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          // Room above and below for a cover grown by hover, which the
          // strip would otherwise clip.
          padding: EdgeInsets.fromLTRB(
            inset + DotSpace.s4,
            DotSpace.s2,
            DotSpace.s4,
            DotSpace.s2,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < newSeries.length; i++) ...[
                if (i > 0) const SizedBox(width: DotSpace.s3),
                ComicSliderCard(
                  title: newSeries[i].title,
                  cover: newSeries[i].coverImg,
                  chapter: newSeries[i].latestChapter,
                  type: newSeries[i].type,
                  slug: newSeries[i].slug,
                  width: cardWidth,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
