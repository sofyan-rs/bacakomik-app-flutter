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
import 'package:bacakomik_app/features/reader/presentation/reader_wakelock.dart';
import 'package:bacakomik_app/features/reader/presentation/widgets/chapter_end.dart';
import 'package:bacakomik_app/features/reader/presentation/widgets/chapter_image.dart';
import 'package:bacakomik_app/features/reader/presentation/widgets/reader_settings_sheet.dart';
import 'package:bacakomik_app/features/settings/domain/entities/app_settings.dart';
import 'package:bacakomik_app/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:bacakomik_app/features/source/presentation/widgets/source_error.dart';
import 'package:bacakomik_app/core/source/comic_key.dart';
import 'package:bacakomik_app/core/network/image_cache.dart';

/// The page number the reader shows (1-based) for 0-based [page] of a
/// chapter with [pageCount] pages; the end item shows the last page. 0 for a
/// chapter without pages.
@visibleForTesting
int shownPageNumber(int page, int pageCount) =>
    pageCount <= 0 ? 0 : (page + 1).clamp(1, pageCount);

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

  /// 0-based index of the page on screen; `pages` means the end item. A
  /// notifier so a page change only rebuilds the page meter.
  final _page = ValueNotifier(0);

  final _itemScroll = ItemScrollController();
  final _scrollOffset = ScrollOffsetController();
  final _itemPositions = ItemPositionsListener.create();
  PageController? _pageController;
  final _zoom = TransformationController();
  TapDownDetails? _doubleTap;
  var _zoomed = false;

  /// Fingers on the reader. With two or more, the page list stops scrolling
  /// so its drag recognizer leaves the gesture arena and the pinch wins.
  var _pointers = 0;
  var _pinching = false;
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

  /// The reading position is saved a moment after the page changes, and
  /// when the reader closes.
  late final HistoryCubit _history;
  late final SettingsCubit _settings;

  /// Vertical auto-scroll. It runs in short linear segments so a speed
  /// change applies within a second. A touch stops the current segment;
  /// scrolling resumes shortly after the last finger lifts.
  var _autoScroll = false;
  var _autoScrollRun = 0;
  Timer? _autoScrollResume;
  ChapterContent? _chapter;
  Timer? _saveTimer;
  int? _savedPage;

  /// The last save was the one made on opening the chapter, which does not
  /// finish it (see [_saveProgress]).
  var _savedOpening = false;

  /// Another chapter was opened in place of this one; this reader saves
  /// nothing more, so its position can't become newer than the new one's.
  var _left = false;

  /// Saves while reading are quiet (no sync per page); closing the reader
  /// or sending the app to the background announces the position to sync.
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _history = context.read<HistoryCubit>();
    _settings = context.read<SettingsCubit>();
    _page.value = _history.resumePage(widget.slug);
    context.read<ReaderBloc>().add(ChapterRequested(widget.slug));
    _itemPositions.itemPositions.addListener(_onItemPositions);
    _zoom.addListener(_onZoomChanged);
    readerWakelock.acquire(keepOn: _settings.state.keepScreenOn);
    _lifecycle = AppLifecycleListener(onPause: _announceProgress);
  }

  @override
  void dispose() {
    _autoHide?.cancel();
    _autoScrollResume?.cancel();
    _lifecycle.dispose();
    _announceProgress();
    _itemPositions.itemPositions.removeListener(_onItemPositions);
    _pageController?.dispose();
    _zoomAnimation.dispose();
    _zoom.dispose();
    _page.dispose();
    readerWakelock.release();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  /// Saves the page on screen if it changed. While reading the save is
  /// quiet; with [announce] it is a normal save that lets sync run, and an
  /// unchanged page re-announces the last quiet save.
  ///
  /// The save made on [opening] never finishes the chapter, so opening a
  /// one-page chapter (or one resumed on its last page) does not mark it
  /// read: it is finished by the next save, a moment later, if the reader
  /// is still on that page ([_scheduleSave]).
  void _saveProgress({bool announce = false, bool opening = false}) {
    final chapter = _chapter;
    final page = _page.value;
    if (chapter == null || chapter.images.isEmpty || _left) return;
    final finishOpened = _savedOpening && !announce && !opening;
    if (page == _savedPage && !finishOpened) {
      if (announce) _history.announce(widget.slug);
      return;
    }
    _savedPage = page;
    _savedOpening = opening;
    _history.addHistory(
      slug: widget.slug,
      chapterNumber: chapter.chapterNumber,
      comicSlug: widget.comicSlug,
      comicDetails: widget.comicDetails,
      page: page,
      pageCount: chapter.images.length,
      canFinish: !opening,
      quiet: !announce,
    );
  }

  /// The reader closes or the app goes to the background: save now, so
  /// sync sends the position to other devices.
  void _announceProgress() {
    _saveTimer?.cancel();
    _saveProgress(announce: true);
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 1), _saveProgress);
  }

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

  void _onPointerDown(PointerDownEvent _) {
    _pointers++;
    _autoScrollResume?.cancel();
    if (_pointers >= 2 && !_pinching) setState(() => _pinching = true);
  }

  /// Scrolling comes back only once every finger is up, so lifting one
  /// finger after a pinch does not turn the other into a scroll.
  void _onPointerUp(PointerEvent _) {
    _pointers = (_pointers - 1).clamp(0, _pointers);
    if (_pointers == 0 && _pinching) setState(() => _pinching = false);
    if (_pointers == 0 && _autoScroll) {
      _autoScrollResume?.cancel();
      _autoScrollResume = Timer(
        const Duration(milliseconds: 800),
        _runAutoScroll,
      );
    }
  }

  void _setAutoScroll(bool on) {
    _autoScrollResume?.cancel();
    _autoScrollRun++;
    if (on == _autoScroll) return;
    setState(() => _autoScroll = on);
    if (on) {
      _setControls(false);
      _runAutoScroll();
    }
  }

  /// The end of the chapter is fully on screen.
  bool get _atEnd => _itemPositions.itemPositions.value.any(
    (p) => p.index == _images.length && p.itemTrailingEdge <= 1.0,
  );

  Future<void> _runAutoScroll() async {
    final run = ++_autoScrollRun;
    const segment = Duration(seconds: 1);
    while (mounted && _autoScroll && run == _autoScrollRun && _pointers == 0) {
      if (_atEnd) {
        _setAutoScroll(false);
        return;
      }
      final speed = _settings.state.autoScrollSpeed;
      await _scrollOffset.animateScroll(
        offset: speed * autoScrollStep * segment.inMilliseconds / 1000,
        duration: segment,
      );
    }
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

  /// Starts loading when the chapter arrives: every batch up to the
  /// resumed page at once, then one batch at a time.
  void _startLoading(List<String> images, {required bool offline}) {
    _images = images;
    _loadLimit = 0;
    _settled.clear();
    // Downloaded pages are on the device; nothing to fetch.
    if (offline) {
      setState(() => _loadLimit = images.length);
      return;
    }
    do {
      _loadNextBatch();
    } while (_loadLimit <= _page.value + 1 && _loadLimit < images.length);
  }

  /// Opens the next [_batch] pages and fetches them in the background.
  void _loadNextBatch() {
    if (_loadLimit >= _images.length) return;
    final start = _loadLimit;
    final end = (start + _batch).clamp(0, _images.length);
    setState(() => _loadLimit = end);
    for (var i = start; i < end; i++) {
      final page = i;
      // Download into the disk cache only; decoding happens when the page
      // is shown, at screen width (see ChapterImg).
      comicImageCache
          .getSingleFile(
            _images[page],
            key: _images[page],
            // Same headers as ChapterImg: it shares this download.
            headers: _chapter?.imageHeaders ?? const {},
          )
          .then((_) {}, onError: (_) {})
          .whenComplete(() => _onPageSettled(page));
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
    // Stay about two batches ahead of the reader instead of fetching the
    // whole chapter.
    final aheadOfReader = _loadLimit - _page.value;
    if (batchDone && aheadOfReader < _batch * 2) _loadNextBatch();
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
    if (index != _page.value) {
      _page.value = index;
      _onPageReached(index);
      _scheduleSave();
    }
  }

  void _openChapter(String slug) {
    if (_left) return;
    // Save this chapter now, before the next one opens and saves: this
    // route is disposed only after the transition, and a save from there
    // would make this chapter look read after the new one.
    _announceProgress();
    _left = true;
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
      listenWhen: (a, b) =>
          a.keepScreenOn != b.keepScreenOn ||
          a.readingDirection != b.readingDirection,
      listener: (_, s) {
        readerWakelock.setKeepOn(s.keepScreenOn);
        if (s.readingDirection != ReadingDirection.vertical) {
          _setAutoScroll(false);
        }
      },
      child: Scaffold(
        backgroundColor: c.bg,
        body: BlocConsumer<ReaderBloc, ReaderState>(
          listener: (context, state) {
            if (state is ReaderLoaded) {
              final pages = state.chapter.images.length;
              _chapter = state.chapter;
              // A chapter that got shorter since the last visit.
              if (_page.value >= pages) _page.value = 0;
              _startLoading(
                state.chapter.images,
                offline: state.chapter.isOffline,
              );
              _saveProgress(opening: true);
              if (pages > 0 && _page.value >= pages - 1) _scheduleSave();
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
      ReaderLoaded(:final chapter) => Listener(
        onPointerDown: _onPointerDown,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerUp,
        child: GestureDetector(
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
      ),
      ReaderNoInternet() => EmptyState.offline(
        onAction: () =>
            context.read<ReaderBloc>().add(ChapterRequested(widget.slug)),
      ),
      ReaderError(:final message) => SourceError(
        message: message,
        sourceId: ComicKey.sourceOf(widget.slug),
        onRetry: () =>
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
      initialScrollIndex: _page.value.clamp(0, pages.length),
      itemScrollController: _itemScroll,
      scrollOffsetController: _scrollOffset,
      itemPositionsListener: _itemPositions,
      physics: _pinching ? const NeverScrollableScrollPhysics() : null,
      itemCount: pages.length + 1,
      itemBuilder: (context, index) {
        if (index == pages.length) return _chapterEnd(chapter);
        return Padding(
          padding: EdgeInsets.only(bottom: settings.pageGap ? DotSpace.s2 : 0),
          child: ChapterImg(
            key: ValueKey(pages[index]),
            chapterImage: pages[index],
            isFile: chapter.isOffline,
            page: index + 1,
            headers: chapter.imageHeaders,
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
      initialPage: _page.value.clamp(0, pages.length),
    );
    return PageView.builder(
      controller: controller,
      reverse: settings.readingDirection == ReadingDirection.rightToLeft,
      itemCount: pages.length + 1,
      physics: _zoomed || _pinching
          ? const NeverScrollableScrollPhysics()
          : null,
      onPageChanged: (page) {
        _page.value = page;
        _onPageReached(page);
        _scheduleSave();
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
              isFile: chapter.isOffline,
              page: index + 1,
              headers: chapter.imageHeaders,
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
                if (chapter != null &&
                    context.read<SettingsCubit>().state.readingDirection ==
                        ReadingDirection.vertical)
                  RoundIconButton(
                    icon: _autoScroll
                        ? LucideIcons300.pause
                        : LucideIcons300.play,
                    semanticLabel: _autoScroll
                        ? AppText.autoScrollStop
                        : AppText.autoScrollStart,
                    iconSize: DotSize.iconSmall,
                    onTap: () => _setAutoScroll(!_autoScroll),
                  ),
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
                    _page.value + 1,
                    pageCount,
                    settings.readingDirection,
                  ),
                  child: ValueListenableBuilder(
                    valueListenable: _page,
                    builder: (context, page, _) {
                      final shown = shownPageNumber(page, pageCount);
                      return Column(
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
                      );
                    },
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
