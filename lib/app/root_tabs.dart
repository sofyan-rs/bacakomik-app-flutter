import 'package:flutter/widgets.dart';

/// Selected main tab, shared so a screen can send the user to another tab
/// (Beranda's search button opens Jelajah with the search field focused; a
/// genre chip on a comic opens Jelajah filtered by that genre). Provided
/// above the [Navigator], so pushed routes can use it too.
class RootTabs extends ChangeNotifier {
  static const home = 0;
  static const explore = 1;

  var _index = home;
  int get index => _index;

  var _searchRequests = 0;

  /// Bumped each time search is requested; Jelajah focuses its field when
  /// this changes.
  int get searchRequests => _searchRequests;

  var _filterRequests = 0;

  /// Bumped each time another screen sets Jelajah's filter; Jelajah loads
  /// again when this changes.
  int get filterRequests => _filterRequests;

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

  /// Shows Jelajah after its filter was set elsewhere.
  void openExploreFiltered() {
    _index = explore;
    _filterRequests++;
    notifyListeners();
  }
}

class RootTabsScope extends InheritedNotifier<RootTabs> {
  const RootTabsScope({
    super.key,
    required RootTabs tabs,
    required super.child,
  }) : super(notifier: tabs);

  /// Rebuilds the caller when the tab changes.
  static RootTabs of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RootTabsScope>()!.notifier!;

  /// Without subscribing to changes; for callbacks and listeners.
  static RootTabs read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<RootTabsScope>()!.notifier!;
}
