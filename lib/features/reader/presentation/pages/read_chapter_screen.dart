import 'dart:async';

import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/di/injection.dart';
import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/history/presentation/bloc/history_cubit.dart';
import 'package:bacakomik_app/features/reader/domain/entities/chapter_content.dart';
import 'package:bacakomik_app/features/reader/presentation/bloc/reader_bloc.dart';
import 'package:bacakomik_app/features/reader/presentation/widgets/chapter_end.dart';
import 'package:bacakomik_app/features/reader/presentation/widgets/chapter_image.dart';
import 'package:bacakomik_app/features/reader/presentation/widgets/reader_settings_sheet.dart';
import 'package:bacakomik_app/features/settings/domain/entities/app_settings.dart';
import 'package:bacakomik_app/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

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

class _ReadChapterViewState extends State<_ReadChapterView>
    with SingleTickerProviderStateMixin {
  /// Most chapters fit; longer ones scale the meter down.
  static const _maxMeterDots = 24;

  var _controlsVisible = true;
  Timer? _autoHide;

  /// 0-based index of the page on screen; `pages` means the end item.
  var _page = 0;

  final _itemScroll = ItemScrollController();
  final _itemPositions = ItemPositionsListener.create();
  PageController? _pageController;
  final _zoom = TransformationController();
  TapDownDetails? _doubleTap;
  var _zoomed = false;
  late final _zoomAnimation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  )..addListener(() => _zoom.value = _zoomTween?.value ?? _zoom.value);
  Animation<Matrix4>? _zoomTween;

  /// Pages load in batches of [_batch], in order. Only pages below
  /// [_loadLimit] may show their image.
  static const _batch = 5;
  var _loadLimit = 0;
  List<String> _images = const [];
  final _settled = <int>{};

  @override
  void initState() {
    super.initState();
    context.read<ReaderBloc>().add(ChapterRequested(widget.slug));
    _itemPositions.itemPositions.addListener(_onItemPositions);
    _zoom.addListener(_onZoomChanged);
    _syncWakelock(context.read<SettingsCubit>().state.keepScreenOn);
  }

  @override
  void dispose() {
    _autoHide?.cancel();
    _itemPositions.itemPositions.removeListener(_onItemPositions);
    _pageController?.dispose();
    _zoomAnimation.dispose();
    _zoom.dispose();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _syncWakelock(bool keepOn) =>
      keepOn ? WakelockPlus.enable() : WakelockPlus.disable();

  void _setControls(bool visible) {
    _autoHide?.cancel();
    setState(() => _controlsVisible = visible);
    SystemChrome.setEnabledSystemUIMode(
      visible ? SystemUiMode.edgeToEdge : SystemUiMode.immersiveSticky,
    );
  }

  void _onZoomChanged() {
    final zoomed = _zoom.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
  }

  /// Double tap: zoom 2.5x into the tapped point, or back out.
  void _toggleZoom() {
    final Matrix4 target;
    if (_zoomed) {
      target = Matrix4.identity();
    } else {
      final tap = _doubleTap;
      if (tap == null) return;
      const scale = 2.5;
      final p = tap.localPosition;
      target = Matrix4.identity()
        ..translateByDouble(-p.dx * (scale - 1), -p.dy * (scale - 1), 0, 1)
        ..scaleByDouble(scale, scale, 1, 1);
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _zoom.value = target;
      return;
    }
    _zoomTween = Matrix4Tween(begin: _zoom.value, end: target).animate(
      CurvedAnimation(parent: _zoomAnimation, curve: DotMotion.slideCurve),
    );
    _zoomAnimation.forward(from: 0);
  }

  /// Starts the first batch when the chapter arrives.
  void _startLoading(List<String> images) {
    _images = images;
    _loadLimit = 0;
    _settled.clear();
    _loadNextBatch();
  }

  /// Opens the next [_batch] pages and fetches them in the background.
  void _loadNextBatch() {
    if (_loadLimit >= _images.length) return;
    final start = _loadLimit;
    final end = (start + _batch).clamp(0, _images.length);
    setState(() => _loadLimit = end);
    for (var i = start; i < end; i++) {
      final page = i;
      precacheImage(
        CachedNetworkImageProvider(_images[page], cacheKey: _images[page]),
        context,
        onError: (_, _) {},
      ).whenComplete(() => _onPageSettled(page));
    }
  }

  /// A page finished loading (or failed). The next batch starts once the
  /// current one has settled.
  void _onPageSettled(int page) {
    if (!mounted) return;
    _settled.add(page);
    final batchStart = _loadLimit - _batch;
    final batchDone = [
      for (var i = batchStart.clamp(0, _loadLimit); i < _loadLimit; i++) i,
    ].every(_settled.contains);
    if (batchDone) _loadNextBatch();
  }

  /// Reading close to the last opened page opens the next batch early.
  void _onPageReached(int page) {
    if (page >= _loadLimit - 2) _loadNextBatch();
  }

  /// The first page whose bottom is below the top third of the screen.
  void _onItemPositions() {
    final positions = _itemPositions.itemPositions.value;
    if (positions.isEmpty) return;
    final visible = positions.where((p) => p.itemTrailingEdge > 0.33);
    if (visible.isEmpty) return;
    final index = visible.reduce((a, b) => a.index < b.index ? a : b).index;
    if (index != _page) {
      setState(() => _page = index);
      _onPageReached(index);
    }
  }

  void _openChapter(String slug) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ReadChapterScreen(
          slug: slug,
          comicSlug: widget.comicSlug,
          comicDetails: widget.comicDetails,
        ),
      ),
    );
  }

  void _goToPage(int page, int pageCount, ReadingDirection direction) {
    final target = page.clamp(0, pageCount);
    if (direction == ReadingDirection.vertical) {
      if (_itemScroll.isAttached) {
        _itemScroll.scrollTo(
          index: target,
          duration: DotMotion.slide,
          curve: DotMotion.slideCurve,
        );
      }
    } else {
      _pageController?.animateToPage(
        target,
        duration: DotMotion.slide,
        curve: DotMotion.slideCurve,
      );
    }
  }

  void _showChapterList(String currentSlug) {
    final chapters = widget.comicDetails.chapters;
    final current = chapters.indexWhere((c) => c.slug == currentSlug);
    showDotSheet<void>(
      context: context,
      builder: (sheetContext) {
        final c = Dotline.of(sheetContext);
        return SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppText.chapterList,
                style: DotlineText.title.copyWith(color: c.ink),
              ),
              const SizedBox(height: DotSpace.s4),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(DotRadius.m),
                  child: ColoredBox(
                    color: c.bg,
                    child: ScrollablePositionedList.separated(
                      initialScrollIndex: current < 0 ? 0 : current,
                      itemCount: chapters.length,
                      separatorBuilder: (_, _) => const Divider(),
                      itemBuilder: (_, index) {
                        final chapter = chapters[index];
                        final isCurrent = index == current;
                        return ListRow(
                          title: '${AppText.chapter} ${chapter.number}',
                          value: chapter.date,
                          trailing: isCurrent
                              ? Icon(
                                  LucideIcons300.bookOpen,
                                  size: DotSize.iconSmall,
                                  color: c.ink,
                                )
                              : null,
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            if (!isCurrent) _openChapter(chapter.slug);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSettings() {
    final settings = context.read<SettingsCubit>();
    showDotSheet<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: settings,
        child: const ReaderSettingsSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final settings = context.watch<SettingsCubit>().state;

    return BlocListener<SettingsCubit, AppSettings>(
      listenWhen: (a, b) => a.keepScreenOn != b.keepScreenOn,
      listener: (_, s) => _syncWakelock(s.keepScreenOn),
      child: Scaffold(
        backgroundColor: c.bg,
        body: BlocConsumer<ReaderBloc, ReaderState>(
          listener: (context, state) {
            if (state is ReaderLoaded) {
              _startLoading(state.chapter.images);
              context.read<HistoryCubit>().addHistory(
                slug: widget.slug,
                chapterNumber: state.chapter.chapterNumber,
                comicSlug: widget.comicSlug,
                comicDetails: widget.comicDetails,
              );
              _autoHide = Timer(const Duration(seconds: 2), () {
                if (mounted) _setControls(false);
              });
            }
          },
          builder: (context, state) {
            final chapter = state is ReaderLoaded ? state.chapter : null;
            return Stack(
              children: [
                Positioned.fill(child: _body(state, settings)),
                _topBar(chapter),
                if (chapter != null) _bottomPill(chapter, settings),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _body(ReaderState state, AppSettings settings) {
    return switch (state) {
      ReaderLoaded(:final chapter) => GestureDetector(
        onTap: () => _setControls(!_controlsVisible),
        onDoubleTapDown: (d) => _doubleTap = d,
        onDoubleTap: _toggleZoom,
        child: InteractiveViewer(
          transformationController: _zoom,
          minScale: 1,
          maxScale: 4,
          // Unzoomed, drags scroll the pages. Zoomed in the vertical
          // reader, the list keeps scrolling and the viewer pans sideways.
          panEnabled: _zoomed,
          panAxis: settings.readingDirection == ReadingDirection.vertical
              ? PanAxis.horizontal
              : PanAxis.free,
          child: settings.readingDirection == ReadingDirection.vertical
              ? _verticalPages(chapter, settings)
              : _horizontalPages(chapter, settings),
        ),
      ),
      ReaderNoInternet() => EmptyState.offline(
        onAction: () =>
            context.read<ReaderBloc>().add(ChapterRequested(widget.slug)),
      ),
      ReaderError(:final message) => EmptyState(
        icon: LucideIcons300.bug,
        title: AppText.error,
        message: message,
        actionLabel: AppText.retry,
        onAction: () =>
            context.read<ReaderBloc>().add(ChapterRequested(widget.slug)),
      ),
      ReaderInitial() || ReaderLoading() => const Center(child: DotLoader()),
    };
  }

  Widget _chapterEnd(ChapterContent chapter) {
    final next = chapter.nextChapterSlug;
    final nextChapter = next == null
        ? null
        : widget.comicDetails.chapters
                  .where((c) => c.slug == next)
                  .firstOrNull ??
              Chapter(number: next.split('/').last, slug: next, date: '-');
    return ChapterEnd(
      chapterNumber: chapter.chapterNumber,
      pageCount: chapter.images.length,
      cover: widget.comicDetails.coverImg,
      next: nextChapter,
      onNext: () => _openChapter(next!),
      onChapterList: () => _showChapterList(widget.slug),
      onHome: () => Navigator.of(context).popUntil((r) => r.isFirst),
    );
  }

  Widget _verticalPages(ChapterContent chapter, AppSettings settings) {
    final pages = chapter.images;
    final height = settings.pageFit == PageFit.height
        ? MediaQuery.sizeOf(context).height
        : null;
    return ScrollablePositionedList.builder(
      itemScrollController: _itemScroll,
      itemPositionsListener: _itemPositions,
      itemCount: pages.length + 1,
      itemBuilder: (context, index) {
        if (index == pages.length) return _chapterEnd(chapter);
        return Padding(
          padding: EdgeInsets.only(bottom: settings.pageGap ? DotSpace.s2 : 0),
          child: ChapterImg(
            key: ValueKey(pages[index]),
            chapterImage: pages[index],
            page: index + 1,
            load: index < _loadLimit,
            fit: settings.pageFit,
            fitHeight: height,
          ),
        );
      },
    );
  }

  Widget _horizontalPages(ChapterContent chapter, AppSettings settings) {
    final pages = chapter.images;
    final controller = _pageController ??= PageController(
      initialPage: _page.clamp(0, pages.length),
    );
    return PageView.builder(
      controller: controller,
      reverse: settings.readingDirection == ReadingDirection.rightToLeft,
      itemCount: pages.length + 1,
      physics: _zoomed ? const NeverScrollableScrollPhysics() : null,
      onPageChanged: (page) {
        setState(() => _page = page);
        _onPageReached(page);
      },
      itemBuilder: (context, index) {
        if (index == pages.length) {
          return SingleChildScrollView(child: _chapterEnd(chapter));
        }
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: settings.pageGap ? DotSpace.s1 : 0,
          ),
          child: Center(
            child: ChapterImg(
              key: ValueKey(pages[index]),
              chapterImage: pages[index],
              page: index + 1,
              load: index < _loadLimit,
              fit: settings.pageFit,
              fitHeight: settings.pageFit == PageFit.height
                  ? MediaQuery.sizeOf(context).height
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _animatedControl({required bool top, required Widget child}) {
    final animate = !MediaQuery.disableAnimationsOf(context);
    return AnimatedSlide(
      duration: animate ? DotMotion.slide : Duration.zero,
      curve: DotMotion.slideCurve,
      offset: _controlsVisible ? Offset.zero : Offset(0, top ? -1 : 1),
      child: AnimatedOpacity(
        duration: animate ? DotMotion.press : Duration.zero,
        opacity: _controlsVisible ? 1 : 0,
        child: IgnorePointer(ignoring: !_controlsVisible, child: child),
      ),
    );
  }

  Widget _topBar(ChapterContent? chapter) {
    final c = Dotline.of(context);
    final number = chapter?.chapterNumber;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: _animatedControl(
        top: true,
        child: ColoredBox(
          color: c.bg,
          child: SafeArea(
            bottom: false,
            child: DotTopBar(
              title: number == null ? null : '${AppText.chapter} $number',
              subtitle: widget.comicDetails.title,
              actions: [
                RoundIconButton(
                  icon: LucideIcons300.list,
                  semanticLabel: AppText.chapterList,
                  iconSize: DotSize.iconSmall,
                  onTap: () => _showChapterList(widget.slug),
                ),
                RoundIconButton(
                  icon: LucideIcons300.slidersHorizontal,
                  semanticLabel: AppText.readerSettings,
                  iconSize: DotSize.iconSmall,
                  onTap: _showSettings,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomPill(ChapterContent chapter, AppSettings settings) {
    final c = Dotline.of(context);
    final pageCount = chapter.images.length;
    final shown = (_page + 1).clamp(1, pageCount);
    final previous = chapter.previousChapterSlug;
    final next = chapter.nextChapterSlug;

    return Positioned(
      left: DotSpace.s4,
      right: DotSpace.s4,
      bottom: MediaQuery.paddingOf(context).bottom + DotSize.navGap,
      child: _animatedControl(
        top: false,
        child: Container(
          height: DotSize.navHeight,
          padding: const EdgeInsets.all(DotSize.navPadding),
          decoration: BoxDecoration(
            color: c.navBar,
            borderRadius: BorderRadius.circular(DotRadius.pill),
            boxShadow: [shadowFloat(Theme.of(context).brightness)],
          ),
          child: Row(
            children: [
              RoundIconButton(
                icon: LucideIcons300.chevronLeft,
                semanticLabel: AppText.previousChapter,
                size: DotSize.navCircle,
                background: Colors.transparent,
                onTap: previous == null ? null : () => _openChapter(previous),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _goToPage(
                    _page + 1,
                    pageCount,
                    settings.readingDirection,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      DotMeter(
                        value: shown,
                        total: pageCount,
                        dots: pageCount.clamp(1, _maxMeterDots),
                        gap: 2,
                      ),
                      const SizedBox(height: DotSpace.s1),
                      Text(
                        '${AppText.pageShort} $shown / $pageCount'
                            .toUpperCase(),
                        style: DotlineText.data.copyWith(color: c.inkMuted),
                      ),
                    ],
                  ),
                ),
              ),
              RoundIconButton(
                icon: LucideIcons300.chevronRight,
                semanticLabel: AppText.nextChapter,
                size: DotSize.navCircle,
                background: c.navSelected,
                onTap: next == null ? null : () => _openChapter(next),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
