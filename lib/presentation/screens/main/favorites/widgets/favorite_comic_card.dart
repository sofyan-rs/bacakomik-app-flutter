import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:bacakomik_app/presentation/screens/sub/comic_details/comic_details_screen.dart';
import 'package:bacakomik_app/presentation/widgets/chip/custom_chip.dart';

class FavoriteComicCard extends StatelessWidget {
  const FavoriteComicCard({
    super.key,
    required this.title,
    required this.cover,
    required this.type,
    required this.slug,
    required this.isSelected,
    required this.isHaveSelectedComic,
    required this.onSelected,
  });

  final String title;
  final String cover;
  final String type;
  final String slug;
  final bool isSelected;
  final bool isHaveSelectedComic;
  final void Function(String) onSelected;

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
        border: isSelected
            ? Border.all(
                color: AppColors.primary,
                width: 3,
              )
            : null,
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
              Stack(
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
                ],
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
                  ],
                ),
              ),
            ],
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  isHaveSelectedComic
                      ? onSelected(slug)
                      : _goToComicDetails(context);
                },
                onLongPress: () {
                  onSelected(slug);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
