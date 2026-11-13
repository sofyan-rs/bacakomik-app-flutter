import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:yoru/app/root_tabs.dart';
import 'package:yoru/core/assets/assets.gen.dart';
import 'package:yoru/core/constants/texts.dart';
import 'package:yoru/core/constants/variables.dart';
import 'package:yoru/core/presentation/widgets/dotline/dotline.dart';
import 'package:yoru/core/theme/dotline_tokens.dart';
import 'package:yoru/features/home/presentation/bloc/home_bloc.dart';
import 'package:yoru/features/home/presentation/widgets/clocked_animation.dart';
import 'package:yoru/features/home/presentation/widgets/comic_slider.dart';
import 'package:yoru/features/home/presentation/widgets/last_read_comic.dart';
import 'package:yoru/features/home/presentation/widgets/latest_chapter.dart';
import 'package:yoru/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:yoru/features/source/presentation/bloc/sources_cubit.dart';
import 'package:yoru/features/source/presentation/widgets/source_picker_sheet.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';
import 'package:yoru/features/source/presentation/widgets/source_error.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  /// Greeting for the hour of the day.
  static String greeting(DateTime now) => switch (now.hour) {
    >= 4 && < 10 => AppText.goodMorning,
    >= 10 && < 15 => AppText.goodAfternoon,
    >= 15 && <= 18 => AppText.goodEvening,
    _ => AppText.goodNight,
  };

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _player = AudioPlayer();

  /// Lalala stays up at least this long, even when the refresh is fast,
  /// so the easter egg is actually seen.
  static const _minSpin = Duration(seconds: 5);

  /// Length of the "lalala pipipi" song (and its animation), used when the
  /// "play until finish" setting is on.
  static const _songLength = Duration(milliseconds: 19670);
  var _spinning = false;

  /// Bumped on every spin so the animation restarts from its first frame,
  /// together with the sound.
  var _spinRun = 0;
  var _minSpinDone = true;
  Timer? _spinTimer;

  /// Loads the song ahead of time so it starts together with the animation.
  late final Future<void> _soundReady = _prepareSound();

  Future<void> _prepareSound() async {
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setSource(AssetSource('sounds/lalala-pipipi.mp3'));
  }

  @override
  void initState() {
    super.initState();
    _soundReady.ignore();
  }

  @override
  void dispose() {
    _spinTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _refreshData(HomeState state) async {
    if (state is HomeLoaded) _startLalala();
    context.read<HomeBloc>().add(
      state is HomeLoaded ? HomeRefreshed() : HomeStarted(),
    );
  }

  Future<void> _startLalala() async {
    _spinTimer?.cancel();
    final settings = context.read<SettingsCubit>().state;
    if (settings.kururinSound) {
      await _soundReady;
      if (!mounted) return;
      await _player.seek(Duration.zero);
      await _player.resume();
      if (!mounted) return;
    }
    setState(() {
      _spinRun++;
      _spinning = true;
      _minSpinDone = false;
    });
    // "Play until finish" only applies while the sound is on; its toggle is
    // hidden otherwise.
    final untilFinish = settings.kururinSound && settings.lalalaUntilFinish;
    _spinTimer = Timer(untilFinish ? _songLength : _minSpin, () {
      _minSpinDone = true;
      _stopLalalaIfDone();
    });
  }

  /// Stops once the refresh has finished and the minimum time has passed.
  void _stopLalalaIfDone() {
    if (!mounted || !_spinning || !_minSpinDone) return;
    final state = context.read<HomeBloc>().state;
    if (state is HomeLoaded && state.isRefetch) return;
    setState(() => _spinning = false);
    _player.pause();
  }

  void _openSearch() => RootTabsScope.read(context).openExploreSearch();

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<HomeBloc, HomeState>(
          listener: (context, state) => _stopLalalaIfDone(),
          builder: (context, state) {
            return CustomRefreshIndicator(
              onRefresh: () async => _refreshData(state),
              builder: (context, child, controller) =>
                  _lalala(state, child, controller),
              child: LayoutBuilder(
                builder: (context, constraints) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(bottom: bottomInset + DotSpace.s5),
                  children: [
                    _column(_header(state)),
                    _column(const LastReadComic()),
                    ..._content(
                      state,
                      contentInset(
                        constraints.maxWidth,
                        DotSize.feedMaxWidth,
                      ).left,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _header(HomeState state) {
    final source = context.watch<SourcesCubit>().state.active;
    return ScreenHeader(
      overline: HomeScreen.greeting(DateTime.now()),
      title: source?.baseName ?? AppVariables.appName,
      titleSemanticLabel: AppText.changeSource,
      onTitleTap: () => showSourcePicker(context),
      subtitleWidget: SourceSubtitle(
        source: source,
        status: switch (state) {
          HomeLoaded() => SourceStatus.online,
          HomeNoInternet() => SourceStatus.offline,
          HomeError() => SourceStatus.error,
          HomeInitial() || HomeLoading() => SourceStatus.connecting,
        },
      ),
      actions: [
        RoundIconButton(
          icon: LucideIcons300.search,
          semanticLabel: AppText.searchHint,
          onTap: _openSearch,
        ),
      ],
    );
  }

  /// Keeps [child] in the home column on wide screens.
  Widget _column(Widget child) =>
      CenteredContent(maxWidth: DotSize.feedMaxWidth, child: child);

  /// [inset] is the space beside the home column, for the slider that
  /// scrolls past it.
  List<Widget> _content(HomeState state, double inset) => switch (state) {
    HomeLoaded() => [
      // Hidden when the source has nothing for it (see showFeatured).
      if (state.home.newSeries.isNotEmpty) ...[
        ComicSlider(state: state, inset: inset),
        const SizedBox(height: DotSpace.s5),
      ],
      _column(LatestChapter(state: state)),
    ],
    HomeNoInternet() => [
      _column(EmptyState.offline(onAction: () => _refreshData(state))),
    ],
    HomeError(:final message) => [
      _column(
        SourceError(
          message: message,
          sourceId: context.read<SourcesCubit>().state.activeId,
          onRetry: () => _refreshData(state),
        ),
      ),
    ],
    HomeInitial() || HomeLoading() => [
      const Padding(
        padding: EdgeInsets.all(DotSpace.s7),
        child: Center(child: DotLoader()),
      ),
    ],
  };

  /// Lalala easter egg: the animation plays (with its "lalala pipipi" song)
  /// while the home tab refreshes.
  Widget _lalala(
    HomeState state,
    Widget child,
    IndicatorController controller,
  ) {
    final showLalala = _spinning;
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        if (showLalala || !controller.isIdle)
          Positioned(
            top: showLalala ? 25 : 25 * controller.value,
            child: SizedBox(
              height: 90,
              width: 90,
              child: Opacity(
                opacity: showLalala ? 1 : controller.value.clamp(0, 1),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(DotRadius.tile),
                  child: ClockedAnimation(
                    key: ValueKey(_spinRun),
                    asset: Assets.images.lalala.path,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        Transform.translate(
          offset: Offset(0, showLalala ? 130.0 : 130.0 * controller.value),
          child: child,
        ),
      ],
    );
  }
}
