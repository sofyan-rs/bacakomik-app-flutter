import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/presentation/widgets/chip/custom_chip.dart';

class LastReadComic extends StatelessWidget {
  const LastReadComic({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              imageUrl:
                  'https://komikcast.lol/wp-content/uploads/2022/02/mfg8383342-e1645095214245.jpg',
            ),
          ),
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(
                  sigmaX: 2.0,
                  sigmaY: 2.0,
                ),
                child: Container(
                  color: AppColors.dark.withOpacity(0.2),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    width: 70,
                    height: 70,
                    child: CachedNetworkImage(
                      fit: BoxFit.cover,
                      imageUrl:
                          'https://komikcast.lol/wp-content/uploads/2022/02/mfg8383342-e1645095214245.jpg',
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
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppText.lastRead,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'My Fake Girlfriends are Using Me As a Shield',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 5),
                    CustomChip(
                      text: 'Chapter 45',
                      backgroundColor: AppColors.primary,
                    )
                  ],
                )
              ],
            ),
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {},
              ),
            ),
          )
        ],
      ),
    );
  }
}
