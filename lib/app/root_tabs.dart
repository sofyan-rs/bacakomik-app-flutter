import 'package:flutter/widgets.dart';

/// Selected main tab, shared so a tab can send the user to another one
/// (Beranda's search button opens Jelajah with the search field focused).
class RootTabs extends ChangeNotifier {
  static const home = 0;
  static const explore = 1;

  var _index = home;
  int get index => _index;

  var _searchRequests = 0;

  /// Bumped each time search is requested; Jelajah focuses its field when
  /// this changes.
  int get searchRequests => _searchRequests;

  void select(int index) {
    if (index == _index) return;
    _index = index;
    notifyListeners();
  }

  void openExploreSearch() {
    _index = explore;
    _searchRequests++;
    notifyListeners();
  }
}

class RootTabsScope extends InheritedNotifier<RootTabs> {
  const RootTabsScope({
    super.key,
    required RootTabs tabs,
    required super.child,
  }) : super(notifier: tabs);

  /// Without subscribing to changes; for callbacks and listeners.
  static RootTabs read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<RootTabsScope>()!.notifier!;
}
