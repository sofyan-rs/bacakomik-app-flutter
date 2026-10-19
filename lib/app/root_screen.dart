import 'package:bacakomik_app/app/root_tabs.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/bookmark/presentation/pages/bookmarks_screen.dart';
import 'package:bacakomik_app/features/explore/presentation/pages/explore_screen.dart';
import 'package:bacakomik_app/features/history/presentation/pages/history_screen.dart';
import 'package:bacakomik_app/features/home/presentation/pages/home_screen.dart';
import 'package:bacakomik_app/features/settings/presentation/pages/more_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// Five main tabs under a floating pill nav, with content fading into the
/// background behind it.
///
/// Tabs get the nav height as bottom [MediaQuery] padding, so scrollables
/// that use the default padding clear the nav on their own. Screens with
/// explicit padding add `MediaQuery.paddingOf(context).bottom` themselves.
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  static const _items = [
    FloatingNavItem(icon: LucideIcons300.house, label: AppText.home),
    FloatingNavItem(icon: LucideIcons300.compass, label: AppText.explore),
    FloatingNavItem(icon: LucideIcons300.bookmark, label: AppText.bookmark),
    FloatingNavItem(icon: LucideIcons300.history, label: AppText.historyTab),
    FloatingNavItem(icon: LucideIcons300.ellipsis, label: AppText.more),
  ];

  final _tabs = RootTabs();

  @override
  void initState() {
    super.initState();
    _tabs.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _onTabChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final media = MediaQuery.of(context);
    final systemBottom = media.viewPadding.bottom;
    final keyboardOpen = media.viewInsets.bottom > 0;
    final navInset = floatingNavInset(context);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarContrastEnforced: false,
          ),
      child: Scaffold(
        backgroundColor: c.bg,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            MediaQuery(
              data: media.copyWith(
                padding: media.padding.copyWith(
                  bottom: keyboardOpen ? 0 : navInset,
                ),
              ),
              child: RootTabsScope(
                tabs: _tabs,
                child: IndexedStack(
                  index: _tabs.index,
                  children: const [
                    HomeScreen(),
                    ExploreScreen(),
                    BookmarksScreen(),
                    HistoryScreen(),
                    MoreScreen(),
                  ],
                ),
              ),
            ),
            if (!keyboardOpen) ...[
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: BottomFade(
                  height: systemBottom + DotSize.navGap + DotSize.navHeight,
                ),
              ),
              Positioned(
                left: DotSpace.s4,
                right: DotSpace.s4,
                bottom: systemBottom + DotSize.navGap,
                child: Center(
                  child: FloatingNavBar(
                    items: _items,
                    selectedIndex: _tabs.index,
                    onSelected: _tabs.select,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
