import 'dart:async';

import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/di/injection.dart';
import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/comic_detail/presentation/pages/comic_details_screen.dart';
import 'package:bacakomik_app/features/history/presentation/bloc/history_cubit.dart';
import 'package:bacakomik_app/features/reader/domain/entities/chapter_content.dart';
import 'package:bacakomik_app/features/reader/domain/usecases/get_chapter_content.dart';
import 'package:bacakomik_app/features/reader/presentation/bloc/reader_bloc.dart';
import 'package:bacakomik_app/features/reader/presentation/reader_wakelock.dart';
import 'package:bacakomik_app/features/reader/presentation/widgets/chapter_end.dart';
import 'package:bacakomik_app/features/reader/presentation/widgets/chapter_image.dart';
import 'package:bacakomik_app/features/reader/presentation/widgets/reader_settings_sheet.dart';
import 'package:bacakomik_app/features/settings/domain/entities/app_settings.dart';
import 'package:bacakomik_app/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:bacakomik_app/features/source/presentation/pages/web_view_screen.dart';
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

/// One chapter in the reader. With infinite scroll the vertical list holds
/// several, in reading order; otherwise only the one opened.
class _Segment {
  _Segment(this.slug, this.content);

  final String slug;
  final ChapterContent content;

  /// Pages load in batches, in order. Only pages below [loadLimit] may show
  /// their image.
  var loadLimit = 0;
  final settled = <int>{};

  List<String> get images => content.images;
}

/// An item of the vertical page list.
sealed class _Item {
  const _Item();
}

final class _PageItem extends _Item {
  const _PageItem(this.segment, this.page);

  final _Segment segment;
  final int page;
}

/// Between two chapters of the list: [segment] ends, [next] starts.
final class _BreakItem extends _Item {
  const _BreakItem(this.segment, this.next);

  final _Segment segment;
  final _Segment next;
}

/// Above the first chapter while the one before it loads (infinite scroll).
final class _HeadItem extends _Item {
  const _HeadItem();
}

/// After the last chapter: its end card, or the next chapter loading.
final class _TailItem extends _Item {
  const _TailItem(this.segment);

  final _Segment segment;
}

/// Fetching the chapter before the first or after the last of the list.
enum _Fetch { idle, loading, failed }

class ReadChapterScreen extends StatelessWidget {
  const ReadChapterScreen({
    super.key,
    required this.slug,
    required this.comicSlug,
    required this.comicDetails,
    this.fromSeries = true,
  });

  final String slug;
  final String comicSlug;
  final ComicDetails comicDetails;

  /// Opened from the series' page, which "Back to series" returns to;
  /// otherwise (Downloads) that page opens in place of the reader.
  final bool fromSeries;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ReaderBloc>(),
      child: _ReadChapterView(
        slug: slug,
        comicSlug: comicSlug,
        comicDetails: comicDetails,
        fromSeries: fromSeries,
      ),
    );
  }
}

class _ReadChapterView extends StatefulWidget {
  const _ReadChapterView({
    required this.slug,
    required this.comicSlug,
    required this.comicDetails,
    this.fromSeries = true,
  });

  final String slug;
  final String comicSlug;
  final ComicDetails comicDetails;

  /// Opened from the series' page, which "Back to series" returns to;
  /// otherwise (Downloads) that page opens in place of the reader.
  final bool fromSeries;

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

  /// Replaced when the vertical list is built anew ([_newList]).
  var _itemScroll = ItemScrollController();
  var _scrollOffset = ScrollOffsetController();
  final _itemPositions = ItemPositionsListener.create();
  PageController? _pageController;
  final _zoom = TransformationController();
  TapDownDetails? _doubleTap;
  var _zoomed = false;

  /// Zoomed in the vertical reader, the viewer pans freely but never moves
  /// up or down itself: the vertical part of a pan (and of its fling)
  /// scrolls the page list instead, see [_panVertical]. [_pinY] and
  /// [_pinScale] are where the viewer is held; [_viewport] bounds it
  /// sideways. [_listContext] is inside the page list's scrollable, see
  /// [_scrollList].
  double? _pinY;
  double? _pinScale;
  Size? _viewport;
  BuildContext? _listContext;
  var _adjustingZoom = false;

  /// Fingers on the reader. With two or more, the page list stops scrolling
  /// so its drag recognizer leaves the gesture arena and the pinch wins.
  var _pointers = 0;
  var _pinching = false;
  late final _zoomAnimation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  )..addListener(() => _zoom.value = _zoomTween?.value ?? _zoom.value);
  Animation<Matrix4>? _zoomTween;

  /// Pages load in batches of [_batch] (see [_Segment.loadLimit]).
  static const _batch = 5;

  /// Chapters in the list, oldest first, and the one being read: the
  /// position, history, title and page meter are its.
  final _segments = <_Segment>[];
  _Segment? _current;
  List<_Item> _items = const [];

  /// Whether [_items] were built for infinite scroll.
  var _itemsInfinite = false;
  var _nextFetch = _Fetch.idle;
  var _previousFetch = _Fetch.idle;
  late final _getChapter = getIt<GetChapterContent>();

  /// Chapters added above the list shift every item down, so the list is
  /// built anew ([_listGeneration]), opening at [_anchor]: the item that
  /// was on screen, where it was.
  var _listGeneration = 0;
  ({int index, double alignment})? _anchor;

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
  ///
  /// Nothing is saved in incognito mode.
  void _saveProgress({bool announce = false, bool opening = false}) {
    final segment = _current;
    final chapter = segment?.content;
    final page = _page.value;
    if (segment == null || chapter == null || chapter.images.isEmpty) return;
    if (_left || _settings.state.incognito) return;
    final finishOpened = _savedOpening && !announce && !opening;
    if (page == _savedPage && !finishOpened) {
      if (announce) _history.announce(segment.slug);
      return;
    }
    _savedPage = page;
    _savedOpening = opening;
    _history.addHistory(
      slug: segment.slug,
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
    if (!_adjustingZoom &&
        _settings.state.readingDirection == ReadingDirection.vertical) {
      _panVertical();
    }
  }

  /// Turns the viewer's vertical movement into a list scroll and keeps the
  /// page within the screen sideways. A move at an unchanged scale is a pan:
  /// the list scrolls by it and the viewer stays at [_pinY]. A pinch or the
  /// double-tap animation changes the scale; then the viewer only stays
  /// within the zoomed page.
  void _panVertical() {
    final size = _viewport;
    if (size == null) return;
    final m = _zoom.value;
    final scale = m.getMaxScaleOnAxis();
    final t = m.getTranslation();
    final x = t.x.clamp(-(scale - 1) * size.width, 0.0);
    var y = t.y;
    final pinY = _pinY;
    final pinScale = _pinScale;
    final panned =
        pinY != null &&
        pinScale != null &&
        scale > 1.01 &&
        (scale - pinScale).abs() < 0.001 &&
        !_zoomAnimation.isAnimating;
    if (panned) {
      _scrollList(-(y - pinY) / scale);
      y = pinY;
    } else {
      y = y.clamp(-(scale - 1) * size.height, 0.0);
    }
    _pinY = y;
    _pinScale = scale;
    if (x != t.x || y != t.y) {
      _adjustingZoom = true;
      _zoom.value = m.clone()..setTranslationRaw(x, y, t.z);
      _adjustingZoom = false;
    }
  }

  /// Scrolls the vertical page list by [delta], within its ends. It jumps
  /// the list's position: [ScrollOffsetController.animateScroll] can't take
  /// a zero duration (`DrivenScrollActivity` asserts on it), and a short
  /// animation per pan update would cut off the one before it.
  void _scrollList(double delta) {
    final context = _listContext;
    if (context == null || !context.mounted || delta == 0) return;
    final position = Scrollable.maybeOf(context)?.position;
    if (position == null || !position.hasContentDimensions) return;
    final to = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (to != position.pixels) position.jumpTo(to);
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

  /// Infinite scroll is on and applies: the vertical reader.
  bool get _infinite =>
      _settings.state.infiniteScroll &&
      _settings.state.readingDirection == ReadingDirection.vertical;

  /// Another chapter can still join the end of the list.
  bool get _moreAfter =>
      _infinite &&
      _segments.isNotEmpty &&
      _segments.last.content.nextChapterSlug != null;

  /// The end of the last chapter is fully on screen.
  bool get _atEnd =>
      !_moreAfter &&
      _itemPositions.itemPositions.value.any(
        (p) => p.index == _items.length - 1 && p.itemTrailingEdge <= 1.0,
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

  /// Starts loading a chapter's pages: every batch up to the page read (the
  /// resumed one) at once, then one batch at a time.
  void _startLoading(_Segment segment) {
    final images = segment.images;
    segment.loadLimit = 0;
    segment.settled.clear();
    // Downloaded pages are on the device; nothing to fetch.
    if (segment.content.isOffline) {
      setState(() => segment.loadLimit = images.length);
      return;
    }
    final from = identical(segment, _current) ? _page.value : 0;
    do {
      _loadNextBatch(segment);
    } while (segment.loadLimit <= from + 1 &&
        segment.loadLimit < images.length);
  }

  /// Opens the next [_batch] pages and fetches them in the background.
  void _loadNextBatch(_Segment segment) {
    final images = segment.images;
    if (segment.loadLimit >= images.length) return;
    final start = segment.loadLimit;
    final end = (start + _batch).clamp(0, images.length);
    setState(() => segment.loadLimit = end);
    for (var i = start; i < end; i++) {
      final page = i;
      // Download into the disk cache only; decoding happens when the page
      // is shown, at screen width (see ChapterImg).
      comicImageCache
          .getSingleFile(
            images[page],
            key: images[page],
            // Same headers as ChapterImg: it shares this download.
            headers: segment.content.imageHeaders,
          )
          .then((_) {}, onError: (_) {})
          .whenComplete(() => _onPageSettled(segment, page));
    }
  }

  /// A page finished loading (or failed). The next batch starts once the
  /// current one has settled.
  void _onPageSettled(_Segment segment, int page) {
    if (!mounted) return;
    segment.settled.add(page);
    final limit = segment.loadLimit;
    final batchDone = [
      for (var i = (limit - _batch).clamp(0, limit); i < limit; i++) i,
    ].every(segment.settled.contains);
    // Stay about two batches ahead of the reader instead of fetching the
    // whole chapter. A chapter not reached yet counts from its start.
    final readerPage = identical(segment, _current) ? _page.value : 0;
    if (batchDone && limit - readerPage < _batch * 2) _loadNextBatch(segment);
  }

  /// Reading close to the last opened page opens the next batch early;
  /// close to the end of the list, the next chapter is fetched.
  void _onPageReached(int page) {
    final segment = _current;
    if (segment == null) return;
    if (page >= segment.loadLimit - 2) _loadNextBatch(segment);
    if (identical(segment, _segments.last) &&
        page >= segment.images.length - 3) {
      _fetchNext();
    }
  }

  /// Rebuilds [_items] from [_segments].
  void _updateItems() {
    final segments = _segments;
    _itemsInfinite = _infinite;
    if (segments.isEmpty) {
      _items = const [];
      return;
    }
    _items = [
      if (_infinite && segments.first.content.previousChapterSlug != null)
        const _HeadItem(),
      for (final (i, segment) in segments.indexed) ...[
        for (var page = 0; page < segment.images.length; page++)
          _PageItem(segment, page),
        if (i < segments.length - 1) _BreakItem(segment, segments[i + 1]),
      ],
      _TailItem(segments.last),
    ];
  }

  /// Index in [_items] of [page] of [segment]; its page count is the item
  /// after its last page.
  int _indexOf(_Segment segment, int page) {
    final index = _items.indexWhere(
      (item) => switch (item) {
        _PageItem(segment: final s, page: final p) =>
          identical(s, segment) && p == page,
        _BreakItem(segment: final s) || _TailItem(segment: final s) =>
          identical(s, segment) && page >= segment.images.length,
        _HeadItem() => false,
      },
    );
    return index < 0 ? 0 : index;
  }

  /// A new vertical list, opening at [_anchor] (see [_listGeneration]).
  void _newList() {
    _listGeneration++;
    _itemScroll = ItemScrollController();
    _scrollOffset = ScrollOffsetController();
    _listContext = null;
  }

  /// Infinite scroll was turned on or off (or no longer applies): only the
  /// chapter being read stays, the list built anew around it, its page on
  /// screen where it was.
  void _resetList() {
    final current = _current;
    if (current == null) return;
    final shown = _itemPositions.itemPositions.value
        .where((p) => p.index == _indexOf(current, _page.value))
        .firstOrNull;
    setState(() {
      _segments
        ..clear()
        ..add(current);
      _nextFetch = _Fetch.idle;
      _previousFetch = _Fetch.idle;
      _updateItems();
      _anchor = (
        index: _indexOf(current, _page.value),
        alignment: shown?.itemLeadingEdge ?? 0,
      );
      _newList();
    });
  }

  /// The first page whose bottom is below the top third of the screen.
  /// With infinite scroll, an end of the list on screen fetches the chapter
  /// beyond it.
  void _onItemPositions() {
    final positions = _itemPositions.itemPositions.value
        .where((p) => p.index < _items.length)
        .toList();
    if (positions.isEmpty) return;
    if (_infinite) {
      for (final p in positions) {
        switch (_items[p.index]) {
          case _HeadItem():
            _fetchPrevious();
          case _TailItem():
            _fetchNext();
          case _:
        }
      }
    }
    final visible = positions.where(
      (p) => p.itemTrailingEdge > 0.33 && _items[p.index] is! _HeadItem,
    );
    if (visible.isEmpty) return;
    final index = visible.reduce((a, b) => a.index < b.index ? a : b).index;
    final (segment, page) = switch (_items[index]) {
      _PageItem(:final segment, :final page) => (segment, page),
      _BreakItem(:final segment) ||
      _TailItem(:final segment) => (segment, segment.images.length),
      _HeadItem() => (_current!, _page.value),
    };
    if (!identical(segment, _current)) {
      _enter(segment, page);
    } else if (page != _page.value) {
      _page.value = page;
      _onPageReached(page);
      _scheduleSave();
    }
  }

  /// Reading went on into another chapter of the list: the one left is
  /// saved where it was left, then this one as opened.
  void _enter(_Segment segment, int page) {
    _announceProgress();
    setState(() => _current = segment);
    _savedPage = null;
    _savedOpening = false;
    _page.value = page;
    _onPageReached(page);
    _saveProgress(opening: true);
  }

  /// Adds the chapter after the last one to the end of the list.
  Future<void> _fetchNext() async {
    if (!_moreAfter || _nextFetch != _Fetch.idle) return;
    final last = _segments.last;
    final slug = last.content.nextChapterSlug!;
    setState(() => _nextFetch = _Fetch.loading);
    final result = await _getChapter(slug);
    if (!mounted) return;
    if (!_infinite || !identical(last, _segments.last)) {
      _nextFetch = _Fetch.idle;
      return;
    }
    result.fold((_) => setState(() => _nextFetch = _Fetch.failed), (content) {
      final segment = _Segment(slug, content);
      setState(() {
        _nextFetch = _Fetch.idle;
        _segments.add(segment);
        _updateItems();
      });
      _startLoading(segment);
    });
  }

  /// Adds the chapter before the first one to the top of the list, keeping
  /// what is on screen in place.
  Future<void> _fetchPrevious() async {
    if (!_infinite || _previousFetch != _Fetch.idle || _segments.isEmpty) {
      return;
    }
    final first = _segments.first;
    final slug = first.content.previousChapterSlug;
    if (slug == null) return;
    setState(() => _previousFetch = _Fetch.loading);
    final result = await _getChapter(slug);
    if (!mounted) return;
    if (!_infinite || !identical(first, _segments.first)) {
      _previousFetch = _Fetch.idle;
      return;
    }
    result.fold((_) => setState(() => _previousFetch = _Fetch.failed), (
      content,
    ) {
      // Read from its end, upwards: each page loads as it comes on screen.
      final segment = _Segment(slug, content)
        ..loadLimit = content.images.length;
      final shown = _itemPositions.itemPositions.value.where(
        (p) => p.index < _items.length && _items[p.index] is! _HeadItem,
      );
      final top = shown.isEmpty
          ? null
          : shown.reduce((a, b) => a.index < b.index ? a : b);
      final before = _items.length;
      setState(() {
        _previousFetch = _Fetch.idle;
        _segments.insert(0, segment);
        _updateItems();
        _anchor = (
          index: (top?.index ?? 0) + _items.length - before,
          alignment: top?.itemLeadingEdge ?? 0,
        );
        _newList();
      });
    });
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
          fromSeries: widget.fromSeries,
        ),
      ),
    );
  }

  void _backToSeries() {
    if (widget.fromSeries) {
      Navigator.of(context).maybePop();
      return;
    }
    final details = widget.comicDetails;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ComicDetailsScreen(
          slug: widget.comicSlug,
          title: details.title,
          cover: details.coverImg,
        ),
      ),
    );
  }

  void _goToPage(int page, int pageCount, ReadingDirection direction) {
    final target = page.clamp(0, pageCount);
    if (direction == ReadingDirection.vertical) {
      final current = _current;
      if (_itemScroll.isAttached && current != null) {
        _itemScroll.scrollTo(
          index: _indexOf(current, target),
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
                          title: AppText.chapterName(
                            chapter.number,
                            chapter.title,
                          ),
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
          a.readingDirection != b.readingDirection ||
          a.infiniteScroll != b.infiniteScroll,
      listener: (_, s) {
        readerWakelock.setKeepOn(s.keepScreenOn);
        if (s.readingDirection != ReadingDirection.vertical) {
          _setAutoScroll(false);
        }
        if (_infinite != _itemsInfinite) {
          _resetList();
        } else {
          // A vertical list built after the pages were read sideways opens
          // at the page read, not at an older anchor.
          _anchor = null;
        }
      },
      child: Scaffold(
        backgroundColor: c.bg,
        body: BlocConsumer<ReaderBloc, ReaderState>(
          listener: (context, state) {
            if (state is ReaderLoaded) {
              final pages = state.chapter.images.length;
              final segment = _Segment(widget.slug, state.chapter);
              _segments
                ..clear()
                ..add(segment);
              _current = segment;
              // A chapter that got shorter since the last visit.
              if (_page.value >= pages) _page.value = 0;
              _updateItems();
              _startLoading(segment);
              _saveProgress(opening: true);
              if (pages > 0 && _page.value >= pages - 1) _scheduleSave();
              _autoHide = Timer(const Duration(seconds: 2), () {
                if (mounted) _setControls(false);
              });
            }
          },
          builder: (context, state) {
            final chapter = state is ReaderLoaded ? _current?.content : null;
            return Stack(
              children: [
                Positioned.fill(child: _body(state, settings)),
                _topBar(chapter),
                if (chapter != null && settings.progressBar)
                  _progressBar(chapter, settings),
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
      ReaderLoaded() when _current != null => Listener(
        onPointerDown: _onPointerDown,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerUp,
        child: GestureDetector(
          onTap: () => _setControls(!_controlsVisible),
          onDoubleTapDown: (d) => _doubleTap = d,
          onDoubleTap: _toggleZoom,
          child: LayoutBuilder(
            builder: (context, constraints) {
              _viewport = constraints.biggest;
              final vertical =
                  settings.readingDirection == ReadingDirection.vertical;
              return InteractiveViewer(
                transformationController: _zoom,
                minScale: 1,
                maxScale: 4,
                // Unzoomed, drags scroll the pages. Zoomed, the viewer takes
                // every drag, in any direction. In the vertical reader it is
                // unbounded because [_panVertical] keeps it in place and
                // scrolls the list instead.
                panEnabled: _zoomed,
                boundaryMargin: vertical
                    ? const EdgeInsets.all(double.infinity)
                    : EdgeInsets.zero,
                child: vertical
                    ? _verticalPages(settings)
                    : _horizontalPages(_current!.content, settings),
              );
            },
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
      ReaderInitial() ||
      ReaderLoading() ||
      ReaderLoaded() => const Center(child: DotLoader()),
    };
  }

  Widget _chapterEnd(ChapterContent chapter) {
    final next = chapter.nextChapterSlug;
    final current = _current?.slug ?? widget.slug;
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
      onChapterList: () => _showChapterList(current),
      onBackToSeries: _backToSeries,
    );
  }

  /// "Chapter N finished", then the next one's name: where one chapter of
  /// the list runs into the next.
  Widget _chapterBreak(_Segment segment, _Segment next) {
    final c = Dotline.of(context);
    final number = next.content.chapterNumber;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DotSpace.s4,
        vertical: DotSpace.s6,
      ),
      child: Column(
        children: [
          Text(
            '${AppText.chapter} ${segment.content.chapterNumber} '
                    '${AppText.finishedLower}'
                .toUpperCase(),
            style: DotlineText.label.copyWith(color: c.inkFaint),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DotSpace.s2),
          Text(
            AppText.chapterName(number, _titleOf(number)),
            style: DotlineText.title.copyWith(color: c.ink),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// An end of the list while the chapter beyond it loads, or failed to.
  Widget _chapterLoading(
    _Fetch fetch,
    VoidCallback retry, {
    double bottom = 0,
  }) {
    final c = Dotline.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        DotSpace.s4,
        DotSpace.s6,
        DotSpace.s4,
        DotSpace.s6 + bottom,
      ),
      child: Center(
        child: fetch == _Fetch.failed
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppText.chapterLoadFailed,
                    style: DotlineText.body.copyWith(color: c.inkMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: DotSpace.s3),
                  DotButton.outline(
                    label: AppText.retry,
                    size: DotButtonSize.medium,
                    onTap: retry,
                  ),
                ],
              )
            : const DotLoader(),
      ),
    );
  }

  String? _titleOf(String number) => widget.comicDetails.chapters
      .where((c) => c.number == number)
      .firstOrNull
      ?.title;

  Widget _verticalPages(AppSettings settings) {
    final height = settings.pageFit == PageFit.height
        ? MediaQuery.sizeOf(context).height
        : null;
    final current = _current!;
    final list = ScrollablePositionedList.builder(
      key: ValueKey(_listGeneration),
      initialScrollIndex:
          _anchor?.index ??
          _indexOf(current, _page.value.clamp(0, current.images.length)),
      initialAlignment: _anchor?.alignment ?? 0,
      itemScrollController: _itemScroll,
      scrollOffsetController: _scrollOffset,
      itemPositionsListener: _itemPositions,
      // Zoomed, the viewer scrolls the list (see [_panVertical]).
      physics: _pinching || _zoomed
          ? const NeverScrollableScrollPhysics()
          : null,
      itemCount: _items.length,
      itemBuilder: (context, index) => switch (_items[index]) {
        _PageItem(:final segment, :final page) => Padding(
          padding: EdgeInsets.only(bottom: settings.pageGap ? DotSpace.s2 : 0),
          child: ChapterImg(
            key: ValueKey(segment.images[page]),
            chapterImage: segment.images[page],
            isFile: segment.content.isOffline,
            page: page + 1,
            headers: segment.content.imageHeaders,
            load: page < segment.loadLimit,
            fit: settings.pageFit,
            fitHeight: height,
          ),
        ),
        _BreakItem(:final segment, :final next) => _chapterBreak(segment, next),
        _HeadItem() => _chapterLoading(_previousFetch, () {
          setState(() => _previousFetch = _Fetch.idle);
          _fetchPrevious();
        }),
        _TailItem(:final segment) =>
          _moreAfter
              ? _chapterLoading(
                  _nextFetch,
                  () {
                    setState(() => _nextFetch = _Fetch.idle);
                    _fetchNext();
                  },
                  // Clears the floating chapter pill, as the end card does.
                  bottom:
                      DotSize.navHeight +
                      DotSize.navGap +
                      MediaQuery.paddingOf(context).bottom,
                )
              : _chapterEnd(segment.content),
      },
    );
    // The list that last reported is the one on screen: while it moves to
    // a page, ScrollablePositionedList passes on only the incoming list's
    // updates, and that list stays once it arrives.
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) {
        _listContext = n.context;
        return false;
      },
      child: NotificationListener<ScrollUpdateNotification>(
        onNotification: (n) {
          _listContext = n.context ?? _listContext;
          return false;
        },
        child: list,
      ),
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
          // Centred on its page, still scrollable on a short screen.
          return LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(child: _chapterEnd(chapter)),
              ),
            ),
          );
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
              load: index < (_current?.loadLimit ?? 0),
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
              title: number == null
                  ? null
                  : AppText.chapterName(number, _titleOf(number)),
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
                  onTap: () => _showChapterList(_current?.slug ?? widget.slug),
                ),
                DotMenuButton(
                  iconSize: DotSize.iconSmall,
                  items: [
                    DotMenuItem(
                      label: AppText.readerSettings,
                      icon: LucideIcons300.slidersHorizontal,
                      onTap: _showSettings,
                    ),
                    if (number != null)
                      DotMenuItem(
                        label: AppText.openWebView,
                        icon: LucideIcons300.globe,
                        onTap: () => WebViewScreen.openSeries(
                          context,
                          sourceId: ComicKey.sourceOf(widget.comicSlug),
                          key: widget.comicSlug,
                          chapter: number,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Thin page progress line along the bottom edge, shown while the
  /// controls (and their page meter) are hidden. Right to left, it fills
  /// from the right.
  Widget _progressBar(ChapterContent chapter, AppSettings settings) {
    final c = Dotline.of(context);
    final pageCount = chapter.images.length;
    final animate = !MediaQuery.disableAnimationsOf(context);
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        child: AnimatedOpacity(
          duration: animate ? DotMotion.press : Duration.zero,
          opacity: _controlsVisible ? 0 : 1,
          child: ValueListenableBuilder(
            valueListenable: _page,
            builder: (context, page, _) {
              final shown = shownPageNumber(page, pageCount);
              return Container(
                height: 3,
                color: c.lineStrong,
                alignment:
                    settings.readingDirection == ReadingDirection.rightToLeft
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: AnimatedFractionallySizedBox(
                  duration: animate ? DotMotion.press : Duration.zero,
                  widthFactor: pageCount == 0 ? 0 : shown / pageCount,
                  heightFactor: 1,
                  child: ColoredBox(color: c.ink),
                ),
              );
            },
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
