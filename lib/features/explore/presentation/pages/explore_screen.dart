import 'package:bacakomik_app/features/explore/presentation/bloc/explore_bloc.dart';
import 'package:bacakomik_app/features/explore/presentation/bloc/filter_cubit.dart';
import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/features/explore/presentation/widgets/filter_comic.dart';
import 'package:bacakomik_app/features/explore/presentation/widgets/filter_result.dart';
import 'package:bacakomik_app/features/search/presentation/pages/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  Future _getFilterData(int page) async {
    context.read<ExploreBloc>().add(
          ExploreRequested(
            filter: context.read<FilterCubit>().state,
            page: page,
          ),
        );
  }

  Future _getFilterDataNext(int page) async {
    context.read<ExploreBloc>().add(
          ExploreNextPageRequested(
            filter: context.read<FilterCubit>().state,
            page: page,
          ),
        );
  }

  @override
  void initState() {
    super.initState();
    _getFilterData(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: const Row(
          children: [
            Icon(
              SolarIconsBold.compass,
              color: AppColors.primary,
            ),
            SizedBox(width: 10),
            Text(AppText.explore),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => FilterComic(
                onApply: () {
                  _getFilterData(1);
                },
              ),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(
          SolarIconsOutline.filter,
          color: Colors.white,
          size: 23,
        ),
      ),
      body: FilterResult(
        onLoadMore: (page) {
          _getFilterDataNext(page);
        },
        onRefresh: () {
          _getFilterData(1);
        },
      ),
    );
  }
}
