import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:bacakomik_app/core/assets/assets.gen.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/constants/variables.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:bacakomik_app/features/home/presentation/widgets/comic_slider.dart';
import 'package:bacakomik_app/features/home/presentation/widgets/last_read_comic.dart';
import 'package:bacakomik_app/features/home/presentation/widgets/latest_chapter.dart';
import 'package:bacakomik_app/features/search/presentation/pages/search_screen.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

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

  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(HomeStarted());
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _refreshData(HomeState state) async {
    context.read<HomeBloc>().add(
      state is HomeLoaded ? HomeRefreshed() : HomeStarted(),
    );
  }

  void _openSearch() =>
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const SearchScreen()));

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<HomeBloc, HomeState>(
          listener: (context, state) async {
            if (state is HomeLoaded && state.isRefetch) {
              if (_player.state != PlayerState.playing) {
                await _player.setSource(AssetSource('sounds/kuru-kururin.mp3'));
                await _player.resume();
              }
              return;
            }
            await _player.release();
          },
          builder: (context, state) {
            return CustomRefreshIndicator(
              onRefresh: () async => _refreshData(state),
              builder: (context, child, controller) =>
                  _kururin(state, child, controller),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(bottom: bottomInset),
                children: [
                  ScreenHeader(
                    overline: HomeScreen.greeting(DateTime.now()),
                    title: AppVariables.appName,
                    actions: [
                      RoundIconButton(
                        icon: LucideIcons300.search,
                        semanticLabel: AppText.searchHint,
                        onTap: _openSearch,
                      ),
                    ],
                  ),
                  const LastReadComic(),
                  const SizedBox(height: DotSpace.s5),
                  ..._content(state),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _content(HomeState state) => switch (state) {
    HomeLoaded() => [
      ComicSlider(state: state),
      const SizedBox(height: DotSpace.s5),
      LatestChapter(state: state),
    ],
    HomeNoInternet() => [
      EmptyState.offline(onAction: () => _refreshData(state)),
    ],
    HomeError(:final message) => [
      EmptyState(
        icon: LucideIcons300.bug,
        title: AppText.error,
        message: message,
        actionLabel: AppText.retry,
        onAction: () => _refreshData(state),
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
    final showKururin = state is HomeLoaded && state.isRefetch;
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
