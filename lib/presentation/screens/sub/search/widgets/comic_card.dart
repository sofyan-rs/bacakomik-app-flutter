import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:bacakomik_app/core/assets/assets.gen.dart';
import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:bacakomik_app/presentation/screens/sub/comic_details/comic_details_screen.dart';
import 'package:bacakomik_app/presentation/widgets/chip/custom_chip.dart';

class ComicCard extends StatelessWidget {
  const ComicCard({
    super.key,
    required this.title,
    required this.cover,
    required this.chapter,
    required this.type,
    required this.rating,
    required this.slug,
  });

  final String title;
  final String cover;
  final String chapter;
  final String type;
  final String rating;
  final String slug;

  void _goToComicDetails(BuildContext context) {
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
    return Container(
      // width: 200,
      // height: 500,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSecondary,
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 3,
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 130,
                color: Theme.of(context).primaryColor.withOpacity(0.5),
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
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 7),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomChip(
                          text: 'Ch. $chapter',
                          backgroundColor: AppColors.primary,
                        ),
                        Row(
                          children: [
                            Assets.icons.bold.starBold.svg(
                              colorFilter: const ColorFilter.mode(
                                AppColors.rating,
                                BlendMode.srcIn,
                              ),
                              width: 12,
                              height: 12,
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
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            right: 10,
            top: 10,
            child: CustomChip(
              text: type,
              backgroundColor: type == 'Manga'
                  ? AppColors.mangaColor
                  : type == 'Manhwa'
                      ? AppColors.manhwaColor
                      : AppColors.manhuaColor,
            ),
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  _goToComicDetails(context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
