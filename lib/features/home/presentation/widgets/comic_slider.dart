import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:bacakomik_app/features/home/presentation/widgets/comic_slider_card.dart';
import 'package:flutter/material.dart';

/// "HOT KOMIK" horizontal strip, ranked 01, 02, ...
class ComicSlider extends StatelessWidget {
  const ComicSlider({super.key, required this.state});

  final HomeLoaded state;

  @override
  Widget build(BuildContext context) {
    final popular = state.home.popular;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel(label: AppText.popular),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: DotSpace.s4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < popular.length; i++) ...[
                if (i > 0) const SizedBox(width: DotSpace.s3),
                ComicSliderCard(
                  rank: i + 1,
                  title: popular[i].title,
                  cover: popular[i].coverImg,
                  chapter: popular[i].latestChapter,
                  type: popular[i].type,
                  slug: popular[i].slug,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
