import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bacakomik_app/core/assets/assets.gen.dart';
import 'package:bacakomik_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/constants/variables.dart';
import 'package:bacakomik_app/features/home/presentation/widgets/comic_slider.dart';
import 'package:bacakomik_app/features/home/presentation/widgets/last_read_comic.dart';
import 'package:bacakomik_app/features/home/presentation/widgets/latest_chapter.dart';
import 'package:bacakomik_app/features/search/presentation/pages/search_screen.dart';
import 'package:solar_icons/solar_icons.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
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

  Future _refreshData(HomeState state) async {
    context.read<HomeBloc>().add(
          state is HomeLoaded ? HomeRefreshed() : HomeStarted(),
        );
  }

  @override
  Widget build(BuildContext context) {
    String hiText = AppText.goodMorning;
    if (DateTime.now().hour >= 4 && DateTime.now().hour < 10) {
      hiText = AppText.goodMorning;
    } else if (DateTime.now().hour >= 10 && DateTime.now().hour < 15) {
      hiText = AppText.goodAfternoon;
    } else if (DateTime.now().hour >= 15 && DateTime.now().hour <= 18) {
      hiText = AppText.goodEvening;
    } else {
      hiText = AppText.goodNight;
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        elevation: 0.8,
        title: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hiText,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.start,
                ),
                const Text(
                  AppVariables.appName,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.start,
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SearchScreen(),
                  ),
                );
              },
              icon: const Icon(
                SolarIconsOutline.magnifier,
                color: Colors.white,
                size: 23,
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
                padding: const EdgeInsets.all(12),
              ),
            ),
          ),
        ],
      ),
      body: BlocConsumer<HomeBloc, HomeState>(
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
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                ComicSlider(),
                LastReadComic(withoutPb: true),
                LatestChapter(),
              ],
            ),
            builder: (context, child, controller) {
              final showKururin = state is HomeLoaded && state.isRefetch;

              return Stack(
                alignment: Alignment.topCenter,
                children: <Widget>[
                  if (showKururin || !controller.isIdle)
                    Positioned(
                      top: showKururin ? 35 : 35 * controller.value,
                      child: SizedBox(
                        height: 60,
                        width: 60,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(
                            Assets.images.kuruKururin.path,
                            fit: BoxFit.cover,
                            opacity: AnimationController(
                              vsync: this,
                              value: showKururin
                                  ? 1
                                  : controller.value.clamp(0, 1),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Transform.translate(
                    offset: Offset(
                      0,
                      showKururin ? 130.0 : 130.0 * controller.value,
                    ),
                    child: child,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
