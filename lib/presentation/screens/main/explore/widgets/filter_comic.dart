// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

import 'package:bacakomik_app/core/bloc/filter_cubit/filter_cubit.dart';
import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:bacakomik_app/core/constants/filters.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/presentation/widgets/chip/custom_choice_chip.dart';

class FilterComic extends StatefulWidget {
  const FilterComic({
    Key? key,
    required this.onApply,
  }) : super(key: key);

  final void Function() onApply;

  @override
  State<FilterComic> createState() => _FilterComicState();
}

class _FilterComicState extends State<FilterComic>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController(initialPage: 0);
  late TabController tabController;

  String _selectedType = 'all';
  String _selectedStatus = 'all';
  String _selectedSortBy = 'update';
  List<String> _selectedGenres = [];

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
    tabController.dispose();
  }

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    // Get initial filter state
    _selectedType = context.read<FilterCubit>().state.type;
    _selectedStatus = context.read<FilterCubit>().state.status;
    _selectedSortBy = context.read<FilterCubit>().state.sortBy;
    _selectedGenres = context.read<FilterCubit>().state.genres;
  }

  void _setFilter() {
    context.read<FilterCubit>().setFilter(
          type: _selectedType,
          status: _selectedStatus,
          sortBy: _selectedSortBy,
          genres: _selectedGenres,
        );
    widget.onApply();
    Navigator.of(context).pop();
  }

  void _resetFilter() {
    setState(() {
      _selectedType = 'all';
      _selectedStatus = 'all';
      _selectedSortBy = 'update';
      _selectedGenres = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppText.filter),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(
            SolarIconsOutline.arrowLeft,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: TextButton(
              onPressed: _resetFilter,
              child: const Text(
                AppText.reset,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: tabController,
          onTap: (index) {
            _pageController.animateToPage(index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut);
          },
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          labelColor: AppColors.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onBackground,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorWeight: 4,
          tabs: const [
            Tab(text: 'Umum'),
            Tab(text: 'Genre'),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          onPressed: _setFilter,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.all(15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          child: const Text(
            AppText.apply,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          tabController.animateTo(index);
        },
        children: [
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                AppText.type,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Wrap(
                children:
                    List<Widget>.generate(Filters.typeList.length, (index) {
                  final isSelected =
                      _selectedType == Filters.typeList[index].id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: CustomChoiceChip(
                      isSelected: isSelected,
                      label: Filters.typeList[index].name,
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedType = Filters.typeList[index].id;
                        });
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              const Text(
                AppText.status,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Wrap(
                children:
                    List<Widget>.generate(Filters.statusList.length, (index) {
                  final isSelected =
                      _selectedStatus == Filters.statusList[index].id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: CustomChoiceChip(
                      isSelected: isSelected,
                      label: Filters.statusList[index].name,
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedStatus = Filters.statusList[index].id;
                        });
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              const Text(
                AppText.sortBy,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Wrap(
                children:
                    List<Widget>.generate(Filters.sortbyList.length, (index) {
                  final isSelected =
                      _selectedSortBy == Filters.sortbyList[index].id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: CustomChoiceChip(
                      isSelected: isSelected,
                      label: Filters.sortbyList[index].name,
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedSortBy = Filters.sortbyList[index].id;
                        });
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
            ],
          ),
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Wrap(
                children:
                    List<Widget>.generate(Filters.genreList.length, (index) {
                  final isSelected =
                      _selectedGenres.contains(Filters.genreList[index].id);
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: CustomChoiceChip(
                      isSelected: isSelected,
                      label: Filters.genreList[index].name,
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            _selectedGenres.add(Filters.genreList[index].id);
                          } else {
                            _selectedGenres.remove(Filters.genreList[index].id);
                          }
                        });
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
