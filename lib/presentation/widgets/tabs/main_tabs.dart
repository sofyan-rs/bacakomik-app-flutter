import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:flutter/material.dart';
import 'package:bacakomik_app/core/assets/assets.gen.dart';
import 'package:bacakomik_app/presentation/screens/main/home/home_screen.dart';

class MainTabs extends StatefulWidget {
  const MainTabs({super.key});

  @override
  State<MainTabs> createState() => _MainTabsState();
}

class _MainTabsState extends State<MainTabs> {
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
                  icon: Assets.icons.homeOutline.svg(
                    colorFilter: ColorFilter.mode(
                      Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.6),
                      BlendMode.srcIn,
                    ),
                  ),
                  selectedIcon: Assets.icons.homeBold.svg(
                    colorFilter: ColorFilter.mode(
                      Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.8),
                      BlendMode.srcIn,
                    ),
                  ),
                  label: const Text(AppText.home),
                ),
                NavigationRailDestination(
                  icon: Assets.icons.compassOutline.svg(
                    colorFilter: ColorFilter.mode(
                      Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.6),
                      BlendMode.srcIn,
                    ),
                  ),
                  selectedIcon: Assets.icons.compassBold.svg(
                    colorFilter: ColorFilter.mode(
                      Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.8),
                      BlendMode.srcIn,
                    ),
                  ),
                  label: const Text(AppText.explore),
                ),
                NavigationRailDestination(
                  icon: Assets.icons.bookmarkOutline.svg(
                    colorFilter: ColorFilter.mode(
                      Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.6),
                      BlendMode.srcIn,
                    ),
                  ),
                  selectedIcon: Assets.icons.bookmarkBold.svg(
                    colorFilter: ColorFilter.mode(
                      Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.8),
                      BlendMode.srcIn,
                    ),
                  ),
                  label: const Text(AppText.favorite),
                ),
                NavigationRailDestination(
                  icon: Assets.icons.dotsOutline.svg(
                    colorFilter: ColorFilter.mode(
                      Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.6),
                      BlendMode.srcIn,
                    ),
                  ),
                  selectedIcon: Assets.icons.dotsBold.svg(
                    colorFilter: ColorFilter.mode(
                      Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.8),
                      BlendMode.srcIn,
                    ),
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
                Center(
                  child: Text('Explore'),
                ),
                Center(
                  child: Text('Favorites'),
                ),
                Center(
                  child: Text('History'),
                ),
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
                  icon: Assets.icons.homeOutline.svg(
                    colorFilter: ColorFilter.mode(
                      Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.6),
                      BlendMode.srcIn,
                    ),
                  ),
                  selectedIcon: Assets.icons.homeBold.svg(
                    colorFilter: ColorFilter.mode(
                      Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.8),
                      BlendMode.srcIn,
                    ),
                  ),
                  label: AppText.home,
                ),
                NavigationDestination(
                  icon: Assets.icons.compassOutline.svg(
                    colorFilter: ColorFilter.mode(
                      Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.6),
                      BlendMode.srcIn,
                    ),
                  ),
                  selectedIcon: Assets.icons.compassBold.svg(
                    colorFilter: ColorFilter.mode(
                      Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.8),
                      BlendMode.srcIn,
                    ),
                  ),
                  label: AppText.explore,
                ),
                NavigationDestination(
                  icon: Assets.icons.bookmarkOutline.svg(
                    colorFilter: ColorFilter.mode(
                      Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.6),
                      BlendMode.srcIn,
                    ),
                  ),
                  selectedIcon: Assets.icons.bookmarkBold.svg(
                    colorFilter: ColorFilter.mode(
                      Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.8),
                      BlendMode.srcIn,
                    ),
                  ),
                  label: AppText.favorite,
                ),
                NavigationDestination(
                  icon: Assets.icons.dotsOutline.svg(
                    colorFilter: ColorFilter.mode(
                      Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.6),
                      BlendMode.srcIn,
                    ),
                  ),
                  selectedIcon: Assets.icons.dotsBold.svg(
                    colorFilter: ColorFilter.mode(
                      Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.8),
                      BlendMode.srcIn,
                    ),
                  ),
                  label: AppText.more,
                ),
              ],
            )
          : null,
    );
  }
}
