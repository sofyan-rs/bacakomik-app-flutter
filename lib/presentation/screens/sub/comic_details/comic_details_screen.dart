// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

import 'package:bacakomik_app/core/bloc/comic_details_bloc/comic_details_bloc.dart';
import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:bacakomik_app/presentation/screens/sub/comic_details/widgets/comic_app_bar.dart';
import 'package:bacakomik_app/presentation/screens/sub/comic_details/widgets/comic_chapters.dart';
import 'package:bacakomik_app/presentation/screens/sub/comic_details/widgets/comic_cover.dart';

class ComicDetailsScreen extends StatefulWidget {
  const ComicDetailsScreen({
    super.key,
    required this.title,
    required this.slug,
    this.cover,
  });

  final String title;
  final String slug;
  final String? cover;

  @override
  State<ComicDetailsScreen> createState() => _ComicDetailsScreenState();
}

class _ComicDetailsScreenState extends State<ComicDetailsScreen> {
  bool isShowTitle = false;
  final ScrollController _scrollController = ScrollController();
  String? coverComic;
  List<SelectedChapter> _selectedChapters = [];

  void _onSelectedChapter(SelectedChapter chapter) {
    final isAlreadySelected =
        _selectedChapters.any((selected) => selected.slug == chapter.slug);

    if (isAlreadySelected) {
      setState(() {
        _selectedChapters
            .removeWhere((selected) => selected.slug == chapter.slug);
      });
    } else {
      setState(() {
        _selectedChapters.add(chapter);
      });
    }
  }

  bool _isInSelectedChapters(String slug) {
    return _selectedChapters.any((chapter) => chapter.slug == slug);
  }

  void _selectAll(List<SelectedChapter> chapters) {
    setState(() {
      _selectedChapters = chapters;
    });
  }

  void _unselectAll() {
    setState(() {
      _selectedChapters = [];
    });
  }

  @override
  void initState() {
    super.initState();
    context.read<ComicDetailsBloc>().add(GetComicDetails(widget.slug));
    widget.cover == null ? coverComic = null : coverComic = widget.cover;
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Future refreshData() async {
      context.read<ComicDetailsBloc>().add(GetComicDetails(widget.slug));
    }

    _scrollController.addListener(() {
      if (_scrollController.offset >= 180) {
        setState(() {
          isShowTitle = true;
        });
      } else {
        setState(() {
          isShowTitle = false;
        });
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      bottomNavigationBar: BlocConsumer<ComicDetailsBloc, ComicDetailsState>(
        listener: (context, state) {
          if (state is ComicDetailsLoaded) {
            setState(() {
              coverComic = state.comicDetails.coverImg;
            });
          }
        },
        builder: (context, state) {
          if (state is ComicDetailsLoaded) {
            return ComicAppBar(
              comicSlug: widget.slug,
              comicDetails: state.comicDetails,
              selectedChapters: _selectedChapters,
              selectAllChapter: _selectAll,
              unselectAllChapter: _unselectAll,
            );
          } else {
            return const SizedBox();
          }
        },
      ),
      body: RefreshIndicator(
        onRefresh: refreshData,
        color: AppColors.primary,
        displacement: 100,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              title: isShowTitle ? Text(widget.title) : null,
              leading: IconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: Icon(
                  SolarIconsOutline.arrowLeft,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              expandedHeight: 260,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                expandedTitleScale: 1,
                background: ComicCover(
                  cover: coverComic,
                  slug: widget.slug,
                ),
              ),
            ),
            BlocBuilder<ComicDetailsBloc, ComicDetailsState>(
              builder: (context, state) {
                if (state is ComicDetailsLoaded) {
                  return ComicChapters(
                    comicDetails: state.comicDetails,
                    comicSlug: widget.slug,
                    onSelectedChapter: _onSelectedChapter,
                    isInSelectedChapters: _isInSelectedChapters,
                    isHaveSelectedChapter: _selectedChapters.isNotEmpty,
                  );
                } else {
                  return const SliverToBoxAdapter(
                    child: SizedBox(),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class SelectedChapter {
  final String slug;
  final String chapterNumber;

  SelectedChapter({
    required this.slug,
    required this.chapterNumber,
  });
}
