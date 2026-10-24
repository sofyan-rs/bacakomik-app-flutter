import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:bacakomik_app/app/root_tabs.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/core/utils/deep_links.dart';
import 'package:bacakomik_app/core/utils/utils.dart';
import 'package:bacakomik_app/features/bookmark/presentation/pages/bookmarks_screen.dart';
import 'package:bacakomik_app/features/comic_detail/presentation/pages/comic_details_screen.dart';
import 'package:bacakomik_app/features/explore/presentation/pages/explore_screen.dart';
import 'package:bacakomik_app/features/history/presentation/pages/history_screen.dart';
import 'package:bacakomik_app/features/home/presentation/pages/home_screen.dart';
import 'package:bacakomik_app/features/settings/presentation/pages/more_screen.dart';
import 'package:bacakomik_app/features/update/presentation/bloc/update_cubit.dart';
import 'package:bacakomik_app/features/update/presentation/widgets/update_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// Five main tabs under a floating pill nav, with content fading into the
/// background behind it. On wide screens the pill becomes a rail on the left.
///
/// Tabs get the nav height as bottom [MediaQuery] padding, so scrollables
/// that use the default padding clear the nav on their own. Screens with
/// explicit padding add `MediaQuery.paddingOf(context).bottom` themselves.
/// With the rail, tabs get its width as left padding instead, which their
/// [SafeArea] applies.
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
    FloatingNavItem(icon: LucideIcons300.settings2, label: AppText.more),
  ];

  /// Comic links opened from outside the app, including the one that
  /// launched it.
  StreamSubscription<Uri>? _links;

  @override
  void initState() {
    super.initState();
    context.read<UpdateCubit>().check(quiet: true);
    _links = AppLinks().uriLinkStream.listen(_onLink);
  }

  @override
  void dispose() {
    _links?.cancel();
    super.dispose();
  }

  void _onLink(Uri uri) {
    final slug = DeepLinks.comicSlug(uri);
    if (slug == null || !mounted) return;
    ComicDetailsScreen.open(
      context,
      slug: slug,
      title: DeepLinks.titleFromSlug(slug),
    );
  }

  /// Reacts to the end of an update check, from app start or from Lainnya.
  void _onUpdateChecked(BuildContext context, UpdateState state) {
    switch (state) {
      case UpdateAvailable(:final release):
        showDotSheet<void>(
          context: context,
          builder: (_) => UpdateSheet(release: release),
        );
      case UpdateUpToDate():
        showSnackBar(context: context, message: AppText.upToDate);
      case UpdateCheckFailed():
        showSnackBar(context: context, message: AppText.checkUpdateFailed);
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final media = MediaQuery.of(context);
    final systemBottom = media.viewPadding.bottom;
    final keyboardOpen = media.viewInsets.bottom > 0;
    final navInset = floatingNavInset(context);
    final rail = useNavRail(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tabs = RootTabsScope.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarContrastEnforced: false,
          ),
      child: BlocListener<UpdateCubit, UpdateState>(
        listenWhen: (previous, _) => previous is UpdateChecking,
        listener: _onUpdateChecked,
        child: Scaffold(
          backgroundColor: c.bg,
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              MediaQuery(
                data: media.copyWith(
                  padding: rail
                      ? media.padding.copyWith(left: floatingRailInset(context))
                      : media.padding.copyWith(
                          bottom: keyboardOpen ? 0 : navInset,
                        ),
                ),
                child: IndexedStack(
                  index: tabs.index,
                  children: const [
                    HomeScreen(),
                    ExploreScreen(),
                    BookmarksScreen(),
                    HistoryScreen(),
                    MoreScreen(),
                  ],
                ),
              ),
              if (rail && !keyboardOpen)
                Positioned(
                  left: media.viewPadding.left + DotSize.navGap,
                  top: media.viewPadding.top,
                  bottom: media.viewPadding.bottom,
                  // Scrolls when the screen is too short for every tab.
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        vertical: DotSize.navGap,
                      ),
                      child: FloatingNavBar(
                        items: _items,
                        selectedIndex: tabs.index,
                        onSelected: tabs.select,
                        axis: Axis.vertical,
                      ),
                    ),
                  ),
                )
              else if (!keyboardOpen) ...[
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
                      selectedIndex: tabs.index,
                      onSelected: tabs.select,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
