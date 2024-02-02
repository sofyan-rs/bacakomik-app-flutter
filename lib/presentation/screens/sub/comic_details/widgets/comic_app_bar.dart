// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:bacakomik_app/core/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

import 'package:bacakomik_app/core/bloc/favorite_cubit/favorite_cubit.dart';
import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/models/comic_details_model/comic_details_model.dart';
import 'package:bacakomik_app/core/models/favorite_model.dart';

class ComicAppBar extends StatefulWidget {
  const ComicAppBar({
    Key? key,
    required this.comicSlug,
    required this.comicDetails,
  }) : super(key: key);

  final String comicSlug;
  final ComicDetailsModel comicDetails;

  @override
  State<ComicAppBar> createState() => _ComicAppBarState();
}

class _ComicAppBarState extends State<ComicAppBar> {
  @override
  Widget build(BuildContext context) {
    bool isInFavorites =
        context.watch<FavoriteCubit>().isFavorite(widget.comicSlug);

    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          BlocBuilder<FavoriteCubit, List<FavoriteModel>>(
            builder: (context, state) {
              return IconButton(
                onPressed: () {
                  if (!isInFavorites) {
                    setState(() {
                      context
                          .read<FavoriteCubit>()
                          .addFavorite(widget.comicDetails, widget.comicSlug);
                    });
                    showSnackBar(
                      context: context,
                      message: AppText.addedToFavorite,
                      icon: Icon(
                        SolarIconsBold.bookmarkSquare,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    );
                  } else {
                    setState(() {
                      context
                          .read<FavoriteCubit>()
                          .removeFavorite(widget.comicSlug);
                    });
                    showSnackBar(
                      context: context,
                      message: AppText.removedFromFavorite,
                      icon: Icon(
                        SolarIconsOutline.heart,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    );
                  }
                },
                icon: Icon(
                  isInFavorites
                      ? SolarIconsBold.heart
                      : SolarIconsOutline.heart,
                  color: AppColors.primary,
                ),
                style: TextButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                  padding: const EdgeInsets.all(14),
                ),
              );
            },
          ),
          const SizedBox(width: 20),
          Expanded(
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.all(14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              child: const Text(
                AppText.readNow,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
