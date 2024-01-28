import 'package:bacakomik_app/core/assets/assets.gen.dart';
import 'package:bacakomik_app/core/router/models/comic_details_extra_model.dart';
import 'package:bacakomik_app/presentation/widgets/chip/custom_chip.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:bacakomik_app/core/router/app_router.dart';

class ComicSliderCard extends StatelessWidget {
  const ComicSliderCard({
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
    context.goNamed(
      '${RouteConstants.root}/${RouteConstants.comicDetails}',
      pathParameters: {
        'slug': slug,
      },
      extra: ComicDetailsExtraModel(title, cover),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: 200,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 140,
                  color: Theme.of(context).primaryColor.withOpacity(0.5),
                  child: CachedNetworkImage(
                    fit: BoxFit.cover,
                    imageUrl: cover,
                    // progressIndicatorBuilder: (context, url, downloadProgress) {
                    //   return Center(
                    //     child: CircularProgressIndicator(
                    //       value: downloadProgress.progress,
                    //     ),
                    //   );
                    // },
                    errorWidget: (context, url, error) {
                      return const Center(
                        child: Text(
                          'Oops',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
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
                            backgroundColor: Theme.of(context).primaryColor,
                          ),
                          Row(
                            children: [
                              Assets.icons.starBold.svg(
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
      ),
    );
  }
}
