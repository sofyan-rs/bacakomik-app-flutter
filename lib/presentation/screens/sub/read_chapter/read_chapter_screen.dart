import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bacakomik_app/core/bloc/chapter_read_bloc/chapter_read_bloc.dart';
import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/models/comic_details_model/comic_details_model.dart';
import 'package:bacakomik_app/presentation/screens/sub/read_chapter/widgets/chapter_image.dart';
import 'package:solar_icons/solar_icons.dart';

class ReadChapterScreen extends StatefulWidget {
  const ReadChapterScreen({
    Key? key,
    required this.slug,
    required this.comicSlug,
    required this.comicDetails,
  }) : super(key: key);

  final String slug;
  final String comicSlug;
  final ComicDetailsModel comicDetails;

  @override
  State<ReadChapterScreen> createState() => _ReadChapterScreenState();
}

class _ReadChapterScreenState extends State<ReadChapterScreen> {
  bool _isAppBarShow = true;
  final ScrollController _scrollController = ScrollController();
  String _chNumber = '';

  void _hideAppBar() {
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isAppBarShow = false;
      });
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
    });
  }

  void _showAppBar() {
    setState(() {
      _isAppBarShow = true;
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    });
  }

  void _showBottomSheetNavigation(
      String? nextChapterSlug, String? prevChapterSlug) {
    String nextCh = (int.parse(_chNumber) + 1).toString();
    String prevCh = (int.parse(_chNumber) - 1).toString();

    showModalBottomSheet(
      elevation: 0,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return Container(
          height: 60,
          color: AppColors.dark.withOpacity(0.8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (prevChapterSlug != null)
                IconButton(
                  onPressed: () {
                    _goToChapterRead(context, prevCh, prevChapterSlug);
                  },
                  icon: Icon(
                    SolarIconsOutline.altArrowLeft,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              if (nextChapterSlug != null)
                IconButton(
                  onPressed: () {
                    _goToChapterRead(context, nextCh, nextChapterSlug);
                  },
                  icon: Icon(
                    SolarIconsOutline.altArrowRight,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _goToChapterRead(BuildContext context, String chapter, String slug) {
    Navigator.of(context).pop();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ReadChapterScreen(
          slug: slug,
          comicSlug: widget.comicSlug,
          comicDetails: widget.comicDetails,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    context.read<ChapterReadBloc>().add(GetChapterRead(widget.slug));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _isAppBarShow
          ? AppBar(
              title: _chNumber != '' ? Text('Chapter $_chNumber') : null,
              leading: IconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: Icon(
                  SolarIconsOutline.arrowLeft,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
            )
          : null,
      body: BlocConsumer<ChapterReadBloc, ChapterReadState>(
        listener: (context, state) {
          if (state is ChapterReadLoaded) {
            setState(() {
              _chNumber = state.chapterRead.chapterNumber;
            });
            _hideAppBar();
            _scrollController.addListener(() {
              if (_scrollController.position.pixels ==
                  _scrollController.position.maxScrollExtent) {
                // _showAppBar();
                _showBottomSheetNavigation(
                  state.chapterRead.nextChapterSlug,
                  state.chapterRead.previousChapterSlug,
                );
              }
            });
          }
        },
        builder: (context, state) {
          if (state is ChapterReadLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is ChapterReadLoaded) {
            return GestureDetector(
              onTap: _hideAppBar,
              onLongPress: () {
                _showAppBar();
              },
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                controller: _scrollController,
                padding: const EdgeInsets.all(0),
                itemCount: state.chapterRead.imageChapters.length,
                itemBuilder: (context, index) {
                  final chapterImage = state.chapterRead.imageChapters[index];
                  return SizedBox(
                    key: Key(index.toString()),
                    width: double.infinity,
                    child: ChapterImg(
                      chapterImage: chapterImage,
                    ),
                  );
                },
              ),
            );
          }

          if (state is ChapterReadError) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(state.message),
              ),
            );
          }

          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: Text(AppText.error),
            ),
          );
        },
      ),
    );
  }
}
