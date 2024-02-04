import 'package:bacakomik_app/core/bloc/history_cubit/history_cubit.dart';
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
  final TransformationController _transformationController =
      TransformationController();
  late TapDownDetails _doubleTapDetails;
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

  void _goToChapterRead(BuildContext context, String slug) {
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
    _transformationController.dispose();
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
              title: Text(widget.comicDetails.title),
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

            context.read<HistoryCubit>().addHistory(
                  slug: widget.slug,
                  chapterNumber: _chNumber,
                  comicSlug: widget.comicSlug,
                  comicDetails: widget.comicDetails,
                );
          }
        },
        builder: (context, state) {
          if (state is ChapterReadLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is ChapterReadLoaded) {
            return Stack(
              children: [
                GestureDetector(
                  onTap: _hideAppBar,
                  onLongPress: () {
                    _showAppBar();
                  },
                  onDoubleTapDown: (d) => _doubleTapDetails = d,
                  onDoubleTap: () {
                    if (_transformationController.value != Matrix4.identity()) {
                      _transformationController.value = Matrix4.identity();
                    } else {
                      final position = _doubleTapDetails.localPosition;
                      // For a 3x zoom
                      // _transformationController.value = Matrix4.identity()
                      //   ..translate(-position.dx * 2, -position.dy * 2)
                      //   ..scale(3.0);
                      // Fox a 2x zoom
                      _transformationController.value = Matrix4.identity()
                        ..translate(-position.dx, -position.dy)
                        ..scale(2.0);
                    }
                  },
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: 1,
                    maxScale: 3,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      controller: _scrollController,
                      padding: const EdgeInsets.all(0),
                      itemCount: state.chapterRead.imageChapters.length,
                      itemBuilder: (context, index) {
                        final chapterImage =
                            state.chapterRead.imageChapters[index];
                        return SizedBox(
                          key: Key(index.toString()),
                          width: double.infinity,
                          child: ChapterImg(
                            chapterImage: chapterImage,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (_isAppBarShow)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 60,
                      color: AppColors.dark.withOpacity(0.8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          state.chapterRead.previousChapterSlug != null
                              ? IconButton(
                                  onPressed: () {
                                    _goToChapterRead(context,
                                        state.chapterRead.previousChapterSlug!);
                                  },
                                  icon: Icon(
                                    SolarIconsOutline.altArrowLeft,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                )
                              : const SizedBox(width: 50),
                          Text(
                            'Chapter $_chNumber',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                          state.chapterRead.nextChapterSlug != null
                              ? IconButton(
                                  onPressed: () {
                                    _goToChapterRead(context,
                                        state.chapterRead.nextChapterSlug!);
                                  },
                                  icon: Icon(
                                    SolarIconsOutline.altArrowRight,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                )
                              : const SizedBox(width: 50),
                        ],
                      ),
                    ),
                  ),
              ],
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
