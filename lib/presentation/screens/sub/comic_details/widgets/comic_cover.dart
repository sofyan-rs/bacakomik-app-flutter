import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bacakomik_app/core/bloc/comic_details_bloc/comic_details_bloc.dart';
import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/presentation/widgets/chip/custom_chip.dart';
import 'package:solar_icons/solar_icons.dart';

class ComicCover extends StatelessWidget {
  const ComicCover({
    Key? key,
    required this.cover,
    required this.slug,
  }) : super(key: key);

  final String cover;
  final String slug;

  void _showCoverImage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          // elevation: 0,
          insetPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              SizedBox(
                width: 400,
                child: CachedNetworkImage(
                  fit: BoxFit.cover,
                  imageUrl: cover,
                  // errorWidget: (context, url, error) {
                  //   return const Center(
                  //     child: Text(
                  //       'Oops',
                  //       style: TextStyle(
                  //         color: Colors.white,
                  //       ),
                  //     ),
                  //   );
                  // },
                ),
              ),
              const SizedBox(height: 10),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  color: Colors.white,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                    padding: const EdgeInsets.all(10),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(
                    SolarIconsOutline.download,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SizedBox(
            width: double.infinity,
            height: 380,
            child: CachedNetworkImage(
              fit: BoxFit.cover,
              imageUrl: cover,
              // errorWidget: (context, url, error) {
              //   return const Center(
              //     child: Text(
              //       'Oops',
              //       style: TextStyle(
              //         color: Colors.white,
              //       ),
              //     ),
              //   );
              // },
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.background.withOpacity(0.2),
                  Theme.of(context).colorScheme.background,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        BlocBuilder<ComicDetailsBloc, ComicDetailsState>(
          builder: (context, state) {
            if (state is ComicDetailsInitial || state is ComicDetailsLoading) {
              return const Positioned(
                top: 150,
                left: 0,
                right: 0,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (state is ComicDetailsLoaded) {
              final comicDetails = state.comicDetails;

              final title = comicDetails.title;
              final type = comicDetails.type;
              final cover = comicDetails.coverImg;
              final status = comicDetails.status;
              final author = comicDetails.author;
              final rating = comicDetails.rating;

              return Positioned(
                top: 120,
                left: 30,
                right: 20,
                child: Row(
                  children: [
                    Container(
                      height: 140,
                      width: 100,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Stack(
                        children: [
                          Container(
                            height: 140,
                            width: 100,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: CachedNetworkImage(
                              fit: BoxFit.cover,
                              imageUrl: cover,
                              // errorWidget: (context, url, error) {
                              //   return const Center(
                              //     child: Text(
                              //       'Oops',
                              //       style: TextStyle(
                              //         color: Colors.white,
                              //       ),
                              //     ),
                              //   );
                              // },
                            ),
                          ),
                          Positioned.fill(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  _showCoverImage(context);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    SizedBox(
                      width: MediaQuery.of(context).size.width - 180,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CustomChip(
                                    text: type,
                                    backgroundColor: type == 'Manga'
                                        ? AppColors.mangaColor
                                        : type == 'Manhwa'
                                            ? AppColors.manhwaColor
                                            : AppColors.manhuaColor,
                                  ),
                                  const SizedBox(width: 5),
                                  CustomChip(
                                    text: status,
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .secondaryContainer,
                                    textColor: Theme.of(context)
                                        .colorScheme
                                        .onSecondaryContainer,
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    SolarIconsBold.start1,
                                    color: AppColors.rating,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    rating,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                color:
                                    Theme.of(context).colorScheme.onBackground,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            author,
                            style: const TextStyle(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            if (state is ComicDetailsError) {
              return Positioned(
                top: 150,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(state.message),
                ),
              );
            }

            return const Positioned(
              top: 150,
              left: 0,
              right: 0,
              child: Center(
                child: Text(AppText.error),
              ),
            );
          },
        ),
      ],
    );
  }
}
