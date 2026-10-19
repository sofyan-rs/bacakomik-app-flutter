import 'package:bacakomik_app/features/history/presentation/bloc/history_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bacakomik_app/features/reader/presentation/bloc/reader_bloc.dart';
import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:bacakomik_app/core/di/injection.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/features/reader/presentation/widgets/chapter_image.dart';
import 'package:solar_icons/solar_icons.dart';

class ReadChapterScreen extends StatelessWidget {
  const ReadChapterScreen({
    super.key,
    required this.slug,
    required this.comicSlug,
    required this.comicDetails,
  });

  final String slug;
  final String comicSlug;
  final ComicDetails comicDetails;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ReaderBloc>(),
      child: _ReadChapterView(
        slug: slug,
        comicSlug: comicSlug,
        comicDetails: comicDetails,
      ),
    );
  }
}

class _ReadChapterView extends StatefulWidget {
  const _ReadChapterView({
    required this.slug,
    required this.comicSlug,
    required this.comicDetails,
  });

  final String slug;
  final String comicSlug;
  final ComicDetails comicDetails;

  @override
  State<_ReadChapterView> createState() => _ReadChapterViewState();
}

class _ReadChapterViewState extends State<_ReadChapterView> {
  bool _isAppBarShow = true;
  final ScrollController _scrollController = ScrollController();
  final TransformationController _transformationController =
      TransformationController();
  late TapDownDetails _doubleTapDetails;
  String _chNumber = '';

  void _hideAppBar() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
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
    context.read<ReaderBloc>().add(ChapterRequested(widget.slug));
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
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            )
          : null,
      body: BlocConsumer<ReaderBloc, ReaderState>(
        listener: (context, state) {
          if (state is ReaderLoaded) {
            setState(() {
              _chNumber = state.chapter.chapterNumber;
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
          if (state is ReaderLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is ReaderLoaded) {
            return Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    _isAppBarShow ? _hideAppBar() : _showAppBar();
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
                        ..translateByDouble(-position.dx, -position.dy, 0, 1)
                        ..scaleByDouble(2.0, 2.0, 2.0, 1);
                    }
                  },
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: 1,
                    maxScale: 3,
                    child: ListView.builder(
                      shrinkWrap: true,
                      primary: false,
                      physics: const AlwaysScrollableScrollPhysics(),
                      controller: _scrollController,
                      padding: const EdgeInsets.all(0),
                      itemCount: state.chapter.images.length,
                      itemBuilder: (context, index) {
                        final chapterImage =
                            state.chapter.images[index];
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
                      color: AppColors.dark.withValues(alpha: 0.8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          state.chapter.previousChapterSlug != null
                              ? IconButton(
                                  onPressed: () {
                                    _goToChapterRead(context,
                                        state.chapter.previousChapterSlug!);
                                  },
                                  icon: Icon(
                                    SolarIconsOutline.altArrowLeft,
                                    color: Colors.white.withValues(alpha: 0.8),
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
                          state.chapter.nextChapterSlug != null
                              ? IconButton(
                                  onPressed: () {
                                    _goToChapterRead(context,
                                        state.chapter.nextChapterSlug!);
                                  },
                                  icon: Icon(
                                    SolarIconsOutline.altArrowRight,
                                    color: Colors.white.withValues(alpha: 0.8),
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

          if (state is ReaderError) {
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
