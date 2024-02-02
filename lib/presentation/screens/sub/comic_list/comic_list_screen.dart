import 'package:bacakomik_app/core/bloc/comic_list_bloc/comic_list_bloc.dart';
import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/models/comic_list_model.dart';
import 'package:bacakomik_app/presentation/screens/sub/comic_details/comic_details_screen.dart';
import 'package:bacakomik_app/presentation/widgets/placeholder/err_no_internet.dart';
import 'package:bacakomik_app/presentation/widgets/placeholder/search_not_found.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:grouped_list/grouped_list.dart';

class ComicListScreen extends StatefulWidget {
  const ComicListScreen({super.key});

  @override
  State<ComicListScreen> createState() => _ComicListScreenState();
}

class _ComicListScreenState extends State<ComicListScreen> {
  final _searchInputController = TextEditingController();
  bool _isSearchComic = false;
  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    context.read<ComicListBloc>().add(GetComicList());
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
        context.read<ComicListBloc>().searchComic(_searchInputController.text);
      });
    });

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: _isSearchComic
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
                        _isSearchComic = false;
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
            : const Row(
                children: [
                  Icon(
                    SolarIconsBold.sortByAlphabet,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 10),
                  Text(AppText.comicList),
                ],
              ),
        actions: [
          if (!_isSearchComic && _isDataLoaded)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                onPressed: () {
                  setState(() {
                    _isSearchComic = !_isSearchComic;
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
        ],
        leading: !_isSearchComic
            ? IconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: Icon(
                  SolarIconsOutline.arrowLeft,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              )
            : Container(),
        leadingWidth: _isSearchComic ? 0 : 56.0,
      ),
      body: BlocConsumer<ComicListBloc, ComicListState>(
        listener: (context, state) {
          if (state is ComicListLoaded) {
            setState(() {
              _isDataLoaded = true;
            });
          }
        },
        builder: (context, state) {
          if (state is ComicListLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is ComicListLoaded) {
            final searchComic = context
                .watch<ComicListBloc>()
                .searchComic(_searchInputController.text);

            if (searchComic.isNotEmpty) {
              return GroupedListView<ComicListModel, String>(
                elements: searchComic,
                groupBy: (comic) => comic.group,
                groupSeparatorBuilder: (String groupByValue) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  width: double.infinity,
                  color: AppColors.primary,
                  child: Text(
                    groupByValue.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                itemBuilder: (context, comic) {
                  return Column(
                    children: [
                      ListTile(
                        title: Text(comic.title),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ComicDetailsScreen(
                                slug: comic.slug,
                                title: comic.title,
                              ),
                            ),
                          );
                        },
                        trailing: Icon(
                          SolarIconsOutline.altArrowRight,
                          color: Theme.of(context)
                              .colorScheme
                              .onBackground
                              .withOpacity(0.2),
                          size: 20,
                        ),
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        // indent: 25,
                        // endIndent: 25,
                        color: Colors.grey.withOpacity(0.1),
                      ),
                    ],
                  );
                },
                itemComparator: (item1, item2) =>
                    item1.title.compareTo(item2.title),
                useStickyGroupSeparators: true,
                floatingHeader: true,
                order: GroupedListOrder.ASC,
              );
            } else {
              return const SearchNotFound();
            }
          }

          if (state is NoInternet) {
            return const ErrNoInternet();
          }

          return const Center(
            child: Text(AppText.error),
          );
        },
      ),
    );
  }
}
