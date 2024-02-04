import 'package:auto_height_grid_view/auto_height_grid_view.dart';
import 'package:bacakomik_app/core/bloc/favorite_cubit/favorite_cubit.dart';
import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/models/favorite_model.dart';
import 'package:bacakomik_app/presentation/screens/main/favorites/widgets/favorite_comic_card.dart';
import 'package:bacakomik_app/presentation/widgets/placeholder/search_not_found.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _searchInputController = TextEditingController();
  bool _isSearchFavorite = false;
  final List<String> _selectedFavorites = [];

  void _onSelectedFavorite(String slug) {
    final isAlreadySelected = _selectedFavorites.contains(slug);

    if (isAlreadySelected) {
      _selectedFavorites.remove(slug);
    } else {
      _selectedFavorites.add(slug);
    }

    setState(() {});
  }

  bool _isInSelectedFavorites(String slug) {
    return _selectedFavorites.contains(slug);
  }

  void _clearSelectedFavorites() {
    showModalBottomSheet(
      useSafeArea: true,
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return SizedBox(
          height: 200,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: const Text(
                  AppText.deleteFavorite,
                  style: TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    const Text(
                      AppText.deleteFavoriteDescription,
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            AppText.cancel,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            context
                                .read<FavoriteCubit>()
                                .removeFavoriteList(_selectedFavorites);
                            _selectedFavorites.clear();
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            AppText.delete,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    _searchInputController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _searchInputController.addListener(() {
      setState(() {
        context.read<FavoriteCubit>().searchFavorite(
              _searchInputController.text,
            );
      });
    });

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: _isSearchFavorite
            ? TextField(
                controller: _searchInputController,
                cursorColor: AppColors.primary,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    SolarIconsOutline.magnifier,
                    color: AppColors.primary,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      SolarIconsOutline.closeCircle,
                      color: Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.5),
                      size: 20,
                    ),
                    onPressed: () {
                      _searchInputController.clear();
                      setState(() {
                        _isSearchFavorite = false;
                      });
                    },
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                  hintText: AppText.searchHint,
                  hintStyle: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.9)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(7),
                    ),
                    borderSide: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.1),
                    ),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(7),
                    ),
                    borderSide: BorderSide(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              )
            : Row(
                children: [
                  Icon(
                    _selectedFavorites.isNotEmpty
                        ? SolarIconsBold.checklistMinimalistic
                        : SolarIconsBold.bookmarkSquareMinimalistic,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(_selectedFavorites.isNotEmpty
                      ? '${_selectedFavorites.length} ${AppText.selected}'
                      : AppText.favoriteList),
                ],
              ),
        actions: [
          if (!_isSearchFavorite)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                onPressed: () {
                  setState(() {
                    _isSearchFavorite = !_isSearchFavorite;
                  });
                },
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
          if (_selectedFavorites.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                onPressed: _clearSelectedFavorites,
                icon: const Icon(
                  SolarIconsOutline.trashBinMinimalistic,
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
          final searchFavorites = context.watch<FavoriteCubit>().searchFavorite(
                _searchInputController.text,
              );

          if (favorites.isEmpty && !_isSearchFavorite) {
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
          }

          if (searchFavorites.isEmpty && _isSearchFavorite) {
            return const SearchNotFound();
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              await context.read<FavoriteCubit>().updateFavoriteList();
            },
            child: AutoHeightGridView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(15),
              itemCount: searchFavorites.length,
              crossAxisCount: MediaQuery.of(context).size.width > 640 ? 4 : 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              shrinkWrap: true,
              builder: (context, index) {
                final comicDetails = searchFavorites[index].comicDetails;
                final comicSlug = searchFavorites[index].slug;

                return FavoriteComicCard(
                  title: comicDetails.title,
                  cover: comicDetails.coverImg,
                  type: comicDetails.type,
                  slug: comicSlug,
                  chapterCount: comicDetails.chapters.length,
                  isSelected: _isInSelectedFavorites(comicSlug),
                  isHaveSelectedComic: _selectedFavorites.isNotEmpty,
                  onSelected: _onSelectedFavorite,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
