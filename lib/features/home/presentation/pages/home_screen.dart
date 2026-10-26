import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:bacakomik_app/app/root_tabs.dart';
import 'package:bacakomik_app/core/assets/assets.gen.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/constants/variables.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:bacakomik_app/features/home/presentation/widgets/comic_slider.dart';
import 'package:bacakomik_app/features/home/presentation/widgets/last_read_comic.dart';
import 'package:bacakomik_app/features/home/presentation/widgets/latest_chapter.dart';
import 'package:bacakomik_app/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:bacakomik_app/features/source/presentation/bloc/sources_cubit.dart';
import 'package:bacakomik_app/features/source/presentation/widgets/source_picker_sheet.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';
import 'package:bacakomik_app/features/source/presentation/widgets/source_error.dart';

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

  /// Kuru-kuru stays up at least this long, even when the refresh is fast,
  /// so the easter egg is actually seen.
  static const _minSpin = Duration(milliseconds: 2500);
  var _spinning = false;
  var _minSpinDone = true;
  Timer? _spinTimer;

  @override
  void dispose() {
    _spinTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _refreshData(HomeState state) async {
    if (state is HomeLoaded) _startKururin();
    context.read<HomeBloc>().add(
      state is HomeLoaded ? HomeRefreshed() : HomeStarted(),
    );
  }

  Future<void> _startKururin() async {
    _spinTimer?.cancel();
    setState(() {
      _spinning = true;
      _minSpinDone = false;
    });
    _spinTimer = Timer(_minSpin, () {
      _minSpinDone = true;
      _stopKururinIfDone();
    });
    if (!context.read<SettingsCubit>().state.kururinSound) return;
    await _player.setSource(AssetSource('sounds/kuru-kururin.mp3'));
    await _player.resume();
  }

  /// Stops once the refresh has finished and the minimum time has passed.
  void _stopKururinIfDone() {
    if (!mounted || !_spinning || !_minSpinDone) return;
    final state = context.read<HomeBloc>().state;
    if (state is HomeLoaded && state.isRefetch) return;
    setState(() => _spinning = false);
    _player.stop();
  }

  void _openSearch() => RootTabsScope.read(context).openExploreSearch();

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<HomeBloc, HomeState>(
          listener: (context, state) => _stopKururinIfDone(),
          builder: (context, state) {
            return CustomRefreshIndicator(
              onRefresh: () async => _refreshData(state),
              builder: (context, child, controller) =>
                  _kururin(state, child, controller),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(bottom: bottomInset),
                children: [
                  _header(state),
                  const LastReadComic(),
                  ..._content(state),
                ],
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

  List<Widget> _content(HomeState state) => switch (state) {
    HomeLoaded() => [
      // Hidden when the source has nothing for it (see showFeatured).
      if (state.home.newSeries.isNotEmpty) ...[
        ComicSlider(state: state),
        const SizedBox(height: DotSpace.s5),
      ],
      LatestChapter(state: state),
    ],
    HomeNoInternet() => [
      EmptyState.offline(onAction: () => _refreshData(state)),
    ],
    HomeError(:final message) => [
      SourceError(
        message: message,
        sourceId: context.read<SourcesCubit>().state.activeId,
        onRetry: () => _refreshData(state),
      ),
    ],
    HomeInitial() || HomeLoading() => [
      const Padding(
        padding: EdgeInsets.all(DotSpace.s7),
        child: Center(child: DotLoader()),
      ),
    ],
  };

  /// Kuru-kuru easter egg: Herta spins (and plays her sound) while the home
  /// tab refreshes.
  Widget _kururin(
    HomeState state,
    Widget child,
    IndicatorController controller,
  ) {
    final showKururin = _spinning;
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        if (showKururin || !controller.isIdle)
          Positioned(
            top: showKururin ? 35 : 35 * controller.value,
            child: SizedBox(
              height: 60,
              width: 60,
              child: Opacity(
                opacity: showKururin ? 1 : controller.value.clamp(0, 1),
                child: ClipOval(
                  child: Image.asset(
                    Assets.images.kuruKururin.path,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        Transform.translate(
          offset: Offset(0, showKururin ? 130.0 : 130.0 * controller.value),
          child: child,
        ),
      ],
    );
  }
}
