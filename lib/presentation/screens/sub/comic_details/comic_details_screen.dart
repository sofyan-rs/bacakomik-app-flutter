import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bacakomik_app/core/bloc/comic_details_bloc/comic_details_bloc.dart';
import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:bacakomik_app/presentation/screens/sub/comic_details/widgets/comic_app_bar.dart';
import 'package:bacakomik_app/presentation/screens/sub/comic_details/widgets/comic_chapters.dart';
import 'package:bacakomik_app/presentation/screens/sub/comic_details/widgets/comic_cover.dart';
import 'package:solar_icons/solar_icons.dart';

class ComicDetailsScreen extends StatefulWidget {
  const ComicDetailsScreen({
    super.key,
    required this.title,
    required this.slug,
    required this.cover,
  });

  final String title;
  final String slug;
  final String cover;

  @override
  State<ComicDetailsScreen> createState() => _ComicDetailsScreenState();
}

class _ComicDetailsScreenState extends State<ComicDetailsScreen> {
  bool isShowTitle = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<ComicDetailsBloc>().add(GetComicDetails(widget.slug));
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
      if (_scrollController.offset >= 100) {
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
      bottomNavigationBar: BlocBuilder<ComicDetailsBloc, ComicDetailsState>(
        builder: (context, state) {
          if (state is ComicDetailsLoaded) {
            return ComicAppBar(
              comicSlug: widget.slug,
              comicDetails: state.comicDetails,
            );
          } else {
            return const SizedBox();
          }
        },
      ),
      body: RefreshIndicator(
        onRefresh: refreshData,
        backgroundColor: AppColors.dark,
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
                  cover: widget.cover,
                  slug: widget.slug,
                ),
              ),
            ),
            BlocBuilder<ComicDetailsBloc, ComicDetailsState>(
              builder: (context, state) {
                if (state is ComicDetailsLoaded) {
                  return ComicChapters(
                    comicDetails: state.comicDetails,
                    slug: widget.slug,
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
