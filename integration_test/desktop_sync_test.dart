import 'package:bacakomik_app/app/root_screen.dart';
import 'package:bacakomik_app/features/sync/presentation/bloc/sync_cubit.dart';
import 'package:bacakomik_app/main.dart' as app;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Signs in to Google in the browser and syncs once. Needs a person to
/// finish the browser sign-in, and the desktop client:
/// `flutter test integration_test/desktop_sync_test.dart -d macos
/// --dart-define-from-file=dart_defines.local.json`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('signs in and syncs', (tester) async {
    app.main();
    await _until(tester, () => find.byType(RootScreen).evaluate().isNotEmpty);
    final sync = tester.element(find.byType(RootScreen)).read<SyncCubit>();

    if (!sync.state.signedIn) {
      // Not awaited: it waits on the browser, while frames keep pumping.
      sync.signIn();
      await _until(
        tester,
        () =>
            sync.state.signedIn || sync.state.status == SyncStatus.signInFailed,
        timeout: const Duration(minutes: 4),
      );
    }
    // ignore: avoid_print
    print('SYNC signed in as ${sync.state.email} (${sync.state.status})');
    expect(sync.state.signedIn, isTrue);

    sync.sync();
    await _until(tester, () => !sync.state.busy);
    // ignore: avoid_print
    print('SYNC ${sync.state.status} at ${sync.state.lastSyncedAt}');
    expect(sync.state.status, isNot(SyncStatus.failed));
  });
}

Future<void> _until(
  WidgetTester tester,
  bool Function() done, {
  Duration timeout = const Duration(seconds: 60),
}) async {
  final end = DateTime.now().add(timeout);
  while (!done()) {
    if (DateTime.now().isAfter(end)) throw TestFailure('Timed out');
    await tester.pump(const Duration(milliseconds: 250));
  }
}
