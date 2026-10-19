import 'package:auto_height_grid_view/auto_height_grid_view.dart';
import 'package:bacakomik_app/core/bloc/bookmark_cubit/bookmark_cubit.dart';
import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/models/bookmark_model.dart';
import 'package:bacakomik_app/presentation/screens/main/bookmarks/widgets/bookmark_comic_card.dart';
import 'package:bacakomik_app/presentation/widgets/placeholder/search_not_found.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final _searchInputController = TextEditingController();
  bool _isSearchBookmark = false;
  final List<String> _selectedBookmarks = [];

  void _onSelectedBookmark(String slug) {
    final isAlreadySelected = _selectedBookmarks.contains(slug);

    if (isAlreadySelected) {
      _selectedBookmarks.remove(slug);
    } else {
      _selectedBookmarks.add(slug);
    }

    setState(() {});
  }

  bool _isInSelectedBookmarks(String slug) {
    return _selectedBookmarks.contains(slug);
  }

  void _clearSelectedBookmarks() {
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
                          .onSurface
                          .withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: const Text(
                  AppText.deleteBookmark,
                  style: TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    const Text(
                      AppText.deleteBookmarkDescription,
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
                                .read<BookmarkCubit>()
                                .removeBookmarkList(_selectedBookmarks);
                            _selectedBookmarks.clear();
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
    final bookmarkCount = context.select<BookmarkCubit, int>(
      (cubit) => cubit.state.length,
    );

    _searchInputController.addListener(() {
      setState(() {
        context.read<BookmarkCubit>().searchBookmark(
              _searchInputController.text,
            );
      });
    });

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: _isSearchBookmark
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
                          .onSurface
                          .withValues(alpha: 0.5),
                      size: 20,
                    ),
                    onPressed: () {
                      _searchInputController.clear();
                      setState(() {
                        _isSearchBookmark = false;
                      });
                    },
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                  hintText: AppText.searchHint,
                  hintStyle: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.9)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(7),
                    ),
                    borderSide: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.1),
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
                    _selectedBookmarks.isNotEmpty
                        ? SolarIconsBold.checklistMinimalistic
                        : SolarIconsBold.bookmarkSquareMinimalistic,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(_selectedBookmarks.isNotEmpty
                      ? '${_selectedBookmarks.length} ${AppText.selected}'
                      : AppText.bookmarkList),
                  if (bookmarkCount > 0 && _selectedBookmarks.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 2, horizontal: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.1),
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        bookmarkCount.toString(),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                ],
              ),
        actions: [
          if (!_isSearchBookmark)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                onPressed: () {
                  setState(() {
                    _isSearchBookmark = !_isSearchBookmark;
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
          if (_selectedBookmarks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                onPressed: _clearSelectedBookmarks,
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
      body: BlocBuilder<BookmarkCubit, List<BookmarkModel>>(
        builder: (context, state) {
          final bookmarks = state;
          final searchBookmarks = context.watch<BookmarkCubit>().searchBookmark(
                _searchInputController.text,
              );

          if (bookmarks.isEmpty && !_isSearchBookmark) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    SolarIconsOutline.bookmarkSquareMinimalistic,
                    color: AppColors.primary.withValues(alpha: 0.5),
                    size: 80,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppText.bookmarkEmpty,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            );
          }

          if (searchBookmarks.isEmpty && _isSearchBookmark) {
            return const SearchNotFound();
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              await context.read<BookmarkCubit>().updateBookmarkList();
            },
            child: AutoHeightGridView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(15),
              itemCount: searchBookmarks.length,
              crossAxisCount: MediaQuery.of(context).size.width > 640 ? 4 : 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              shrinkWrap: true,
              builder: (context, index) {
                final comicDetails = searchBookmarks[index].comicDetails;
                final comicSlug = searchBookmarks[index].slug;

                return BookmarkComicCard(
                  title: comicDetails.title,
                  cover: comicDetails.coverImg,
                  type: comicDetails.type,
                  slug: comicSlug,
                  chapterCount: comicDetails.chapters.length,
                  isSelected: _isInSelectedBookmarks(comicSlug),
                  isHaveSelectedComic: _selectedBookmarks.isNotEmpty,
                  onSelected: _onSelectedBookmark,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
