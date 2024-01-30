import 'package:auto_height_grid_view/auto_height_grid_view.dart';
import 'package:bacakomik_app/core/bloc/favorite_cubit/favorite_cubit.dart';
import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/models/favorite_model.dart';
import 'package:bacakomik_app/presentation/screens/main/favorites/widgets/favorite_comic_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: const Row(
          children: [
            Icon(
              SolarIconsBold.bookmarkSquareMinimalistic,
              color: AppColors.primary,
            ),
            SizedBox(width: 10),
            Text(AppText.favoriteList),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(
                SolarIconsOutline.magnifier,
                color: Colors.white,
                size: 23,
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
                padding: const EdgeInsets.all(12),
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<FavoriteCubit, List<FavoriteModel>>(
        builder: (context, state) {
          final favorites = state;

          if (favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    SolarIconsOutline.bookmarkSquareMinimalistic,
                    color: AppColors.primary.withOpacity(0.5),
                    size: 80,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppText.favoriteEmpty,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return AutoHeightGridView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(15),
              itemCount: favorites.length,
              crossAxisCount: MediaQuery.of(context).size.width > 640 ? 4 : 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              shrinkWrap: true,
              builder: (context, index) {
                final comicDetails = favorites[index].comicDetails;
                final comicSlug = favorites[index].slug;

                return FavoriteComicCard(
                  title: comicDetails.title,
                  cover: comicDetails.coverImg,
                  type: comicDetails.type,
                  slug: comicSlug,
                );
              },
            );
          }
        },
      ),
    );
  }
}
