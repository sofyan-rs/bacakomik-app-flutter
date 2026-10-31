import 'package:bacakomik_app/app/root_tabs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Keyboard shortcuts for every screen, for desktop: ⌘1–⌘5 (Ctrl off macOS)
/// switch tabs, ⌘F and ⌘K open search, Escape goes back. Screens with their
/// own bindings (the reader) handle keys first.
class AppShortcuts extends StatelessWidget {
  const AppShortcuts({
    super.key,
    required this.navigator,
    required this.tabs,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigator;
  final RootTabs tabs;
  final Widget child;

  static const _tabKeys = [
    LogicalKeyboardKey.digit1,
    LogicalKeyboardKey.digit2,
    LogicalKeyboardKey.digit3,
    LogicalKeyboardKey.digit4,
    LogicalKeyboardKey.digit5,
  ];

  /// Closes pushed screens and sheets, back to the tabs.
  void _toTabs() => navigator.currentState?.popUntil((route) => route.isFirst);

  @override
  Widget build(BuildContext context) {
    final mac = defaultTargetPlatform == TargetPlatform.macOS;
    SingleActivator command(LogicalKeyboardKey key) =>
        SingleActivator(key, meta: mac, control: !mac);
    void search() {
      _toTabs();
      tabs.openExploreSearch();
    }

    return CallbackShortcuts(
      bindings: {
        for (var i = 0; i < _tabKeys.length; i++)
          command(_tabKeys[i]): () {
            _toTabs();
            tabs.select(i);
          },
        command(LogicalKeyboardKey.keyF): search,
        command(LogicalKeyboardKey.keyK): search,
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            navigator.currentState?.maybePop(),
      },
      // Something has to hold focus for the keys to arrive before any field
      // or route takes it.
      child: Focus(autofocus: true, child: child),
    );
  }
}
