// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:ui' as ui;

import 'package:bacakomik_app/presentation/screens/sub/comic_details/comic_details_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bacakomik_app/core/bloc/history_cubit/history_cubit.dart';
import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/models/history_model.dart';
import 'package:bacakomik_app/presentation/widgets/chip/custom_chip.dart';

class LastReadComic extends StatefulWidget {
  const LastReadComic({
    Key? key,
    this.withoutPb = false,
  }) : super(key: key);

  final bool withoutPb;

  @override
  State<LastReadComic> createState() => _LastReadComicState();
}

class _LastReadComicState extends State<LastReadComic> {
  void _goToComicDetails(
      BuildContext context, String slug, String title, String cover) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ComicDetailsScreen(
          slug: slug,
          title: title,
          cover: cover,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryCubit, List<HistoryModel>>(
      builder: (context, state) {
        if (state.isNotEmpty) {
          HistoryModel latestHistory =
              context.watch<HistoryCubit>().latestHistory;

          return Padding(
            padding: widget.withoutPb
                ? const EdgeInsets.only(
                    left: 15,
                    right: 15,
                    top: 15,
                  )
                : const EdgeInsets.all(15),
            child: Container(
              width: double.infinity,
              height: 100,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CachedNetworkImage(
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      imageUrl: latestHistory.comicDetails.coverImg,
                    ),
                  ),
                  Positioned.fill(
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(
                          sigmaX: 3.0,
                          sigmaY: 3.0,
                        ),
                        child: Container(
                          color: AppColors.dark.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 15),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              clipBehavior: Clip.antiAlias,
                              width: 70,
                              height: 70,
                              child: CachedNetworkImage(
                                fit: BoxFit.cover,
                                imageUrl: latestHistory.comicDetails.coverImg,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  AppText.lastRead,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  latestHistory.comicDetails.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 5),
                                CustomChip(
                                  text:
                                      'Chapter ${latestHistory.chapterNumber}',
                                  backgroundColor: AppColors.primary,
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          _goToComicDetails(
                            context,
                            latestHistory.comicSlug,
                            latestHistory.comicDetails.title,
                            latestHistory.comicDetails.coverImg,
                          );
                        },
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }
}
