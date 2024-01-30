import 'package:bacakomik_app/presentation/screens/main/explore/explore_screen.dart';
import 'package:bacakomik_app/presentation/screens/main/favorites/favorites_screen.dart';
import 'package:bacakomik_app/presentation/screens/main/more/more_screen.dart';
import 'package:flutter/material.dart';

import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/presentation/screens/main/home/home_screen.dart';
import 'package:solar_icons/solar_icons.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  var _selectedIndex = 0;

  void _onTap(int index) {
    setState(
      () => _selectedIndex = index,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          if (MediaQuery.of(context).size.width >= 640)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onTap,
              labelType: NavigationRailLabelType.all,
              // elevation: 2,
              destinations: [
                NavigationRailDestination(
                  icon: const Icon(SolarIconsOutline.homeSmile),
                  selectedIcon: Icon(
                    SolarIconsBold.homeSmile,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  label: const Text(AppText.home),
                ),
                NavigationRailDestination(
                  icon: const Icon(SolarIconsOutline.compass),
                  selectedIcon: Icon(
                    SolarIconsBold.compass,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  label: const Text(AppText.explore),
                ),
                NavigationRailDestination(
                  icon:
                      const Icon(SolarIconsOutline.bookmarkSquareMinimalistic),
                  selectedIcon: Icon(
                    SolarIconsBold.bookmarkSquareMinimalistic,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  label: const Text(AppText.favorite),
                ),
                NavigationRailDestination(
                  icon: const Icon(SolarIconsOutline.menuDots),
                  selectedIcon: Icon(
                    SolarIconsBold.menuDots,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  label: const Text(AppText.more),
                ),
              ],
            ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: const [
                HomeScreen(),
                ExploreScreen(),
                FavoritesScreen(),
                MoreScreen(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width < 640
          ? NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onTap,
              labelBehavior:
                  NavigationDestinationLabelBehavior.onlyShowSelected,
              elevation: 2,
              shadowColor: Colors.black54,
              destinations: [
                NavigationDestination(
                  icon: const Icon(SolarIconsOutline.homeSmile),
                  selectedIcon: Icon(
                    SolarIconsBold.homeSmile,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  label: AppText.home,
                ),
                NavigationDestination(
                  icon: const Icon(SolarIconsOutline.compass),
                  selectedIcon: Icon(
                    SolarIconsBold.compass,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  label: AppText.explore,
                ),
                NavigationDestination(
                  icon:
                      const Icon(SolarIconsOutline.bookmarkSquareMinimalistic),
                  selectedIcon: Icon(
                    SolarIconsBold.bookmarkSquareMinimalistic,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  label: AppText.favorite,
                ),
                NavigationDestination(
                  icon: const Icon(SolarIconsOutline.menuDots),
                  selectedIcon: Icon(
                    SolarIconsBold.menuDots,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  label: AppText.more,
                ),
              ],
            )
          : null,
    );
  }
}
