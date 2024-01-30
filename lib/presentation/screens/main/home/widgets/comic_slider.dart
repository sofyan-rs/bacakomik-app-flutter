import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bacakomik_app/core/bloc/home_bloc/home_bloc.dart';
import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/presentation/screens/main/home/widgets/comic_slider_card.dart';
import 'package:solar_icons/solar_icons.dart';

class ComicSlider extends StatelessWidget {
  const ComicSlider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(
              left: 15,
              right: 15,
              top: 20,
            ),
            child: Row(
              children: [
                Icon(
                  SolarIconsBold.fireMinimalistic,
                  color: AppColors.primary,
                ),
                SizedBox(width: 8),
                Text(
                  AppText.popular,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          BlocBuilder<HomeBloc, HomeState>(
            builder: (context, state) {
              if (state is HomeInitial || state is HomeLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(15),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (state is HomeLoaded) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        for (final popular in state.home.popular)
                          ComicSliderCard(
                            title: popular.title,
                            cover: popular.coverImg,
                            chapter: popular.latestChapter,
                            type: popular.type,
                            rating: popular.rating,
                            slug: popular.slug,
                          ),
                      ],
                    ),
                  ),
                );
              }

              if (state is HomeError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Text(state.message),
                  ),
                );
              }

              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(15),
                  child: Text(AppText.error),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
