import 'package:bacakomik_app/core/bloc/home_bloc/home_bloc.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:bacakomik_app/core/assets/assets.gen.dart';
import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:bacakomik_app/core/router/app_router.dart';
import 'package:bacakomik_app/presentation/screens/main/home/widgets/latest_chapter_card.dart';

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
                Row(
                  children: [
                    Assets.icons.notebookOutline.svg(
                      colorFilter: const ColorFilter.mode(
                        AppColors.primary,
                        BlendMode.srcIn,
                      ),
                      width: 20,
                      height: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
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
                    context.goNamed(RouteConstants.latestChapter);
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
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
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

              if (state is HomeRefetching) {
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
