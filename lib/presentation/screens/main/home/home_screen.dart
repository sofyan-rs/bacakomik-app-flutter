import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:bacakomik_app/core/bloc/home_bloc/home_bloc.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bacakomik_app/core/assets/assets.gen.dart';
import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:bacakomik_app/presentation/screens/main/home/widgets/comic_slider.dart';
import 'package:bacakomik_app/presentation/screens/main/home/widgets/latest_chapter.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';

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
    context.read<HomeBloc>().add(GetHome());
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future _refreshData(HomeState state) async {
    if (state is HomeLoaded) {
      context.read<HomeBloc>().add(RefetchHome());
    } else {
      context.read<HomeBloc>().add(GetHome());
    }
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
        toolbarHeight: 90,
        elevation: 1,
        backgroundColor: AppColors.primary.withOpacity(0.2),
        title: Row(
          children: [
            CircleAvatar(
              radius: 25,
              // backgroundImage: NetworkImage(
              //   '',
              // ),
              backgroundColor: Theme.of(context).colorScheme.background,
            ),
            const SizedBox(width: 10),
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
                  'Sofyan R.',
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
              onPressed: () {},
              icon: Assets.icons.searchOutline.svg(
                colorFilter: ColorFilter.mode(
                  Colors.white.withOpacity(0.9),
                  BlendMode.srcIn,
                ),
                width: 20,
                height: 20,
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
          if (state is HomeRefetching) {
            if (_player.state != PlayerState.playing) {
              await _player.setSource(AssetSource('sounds/kuru-kuru.mp3'));
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
                LatestChapter(),
              ],
            ),
            builder: (context, child, controller) {
              return Stack(
                alignment: Alignment.topCenter,
                children: <Widget>[
                  if (state is HomeRefetching || !controller.isIdle)
                    Positioned(
                      top: state is HomeRefetching ? 35 : 35 * controller.value,
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
                              value: state is HomeRefetching
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
                      state is HomeRefetching
                          ? 130.0
                          : 130.0 * controller.value,
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
