import 'package:bacakomik_app/presentation/widgets/placeholder/err_no_internet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bacakomik_app/core/bloc/home_bloc/home_bloc.dart';
import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/presentation/screens/main/home/widgets/latest_chapter_card.dart';
import 'package:bacakomik_app/presentation/screens/sub/latest_chapter/latest_chapter_screen.dart';
import 'package:solar_icons/solar_icons.dart';

class LatestChapter extends StatelessWidget {
  const LatestChapter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 20,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      SolarIconsBold.notebook1,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      AppText.latest,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    AppText.seeAll,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const LatestChapterScreen(),
                      ),
                    );
                  },
                )
              ],
            ),
          ),
          const SizedBox(height: 15),
          BlocBuilder<HomeBloc, HomeState>(
            builder: (context, state) {
              if (state is HomeInitial || state is HomeLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (state is HomeLoaded) {
                return Column(
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
                );
              }

              if (state is HomeError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(state.message),
                  ),
                );
              }

              if (state is NoInternet) {
                return const ErrNoInternet();
              }

              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(AppText.error),
                ),
              );
            },
          )
        ],
      ),
    );
  }
}
