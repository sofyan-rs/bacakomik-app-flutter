import 'package:bacakomik_app/core/assets/assets.gen.dart';
import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchInputController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 75,
        title: TextField(
          controller: _searchInputController,
          cursorColor: AppColors.primary,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 15),
            hintText: 'Search',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.9)),
            enabledBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(
                Radius.circular(7),
              ),
              borderSide: BorderSide(
                color:
                    Theme.of(context).colorScheme.onBackground.withOpacity(0.1),
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(7),
              ),
              borderSide: BorderSide(
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Assets.icons.arrowLeftOutline.svg(
            colorFilter: ColorFilter.mode(
              Theme.of(context).colorScheme.onBackground,
              BlendMode.srcIn,
            ),
          ),
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
                width: 23,
                height: 23,
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
      body: const Center(
        child: Text('Search Screen'),
      ),
    );
  }
}
