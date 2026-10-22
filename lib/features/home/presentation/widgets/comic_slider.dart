import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:bacakomik_app/features/home/presentation/widgets/comic_slider_card.dart';
import 'package:flutter/material.dart';

/// "SERI BARU" horizontal strip.
class ComicSlider extends StatelessWidget {
  const ComicSlider({super.key, required this.state});

  final HomeLoaded state;

  @override
  Widget build(BuildContext context) {
    final newSeries = state.home.newSeries;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel(label: AppText.newSeries),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: DotSpace.s4),
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
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
