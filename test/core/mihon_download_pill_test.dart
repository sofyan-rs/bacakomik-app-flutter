import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yoru/core/constants/texts.dart';
import 'package:yoru/core/presentation/widgets/mihon_download_pill.dart';
import 'package:yoru/core/source/mihon_process_host.dart';
import 'package:yoru/core/theme/dotline_theme.dart';

void main() {
  testWidgets('shows a Mihon download while it runs, then goes', (
    tester,
  ) async {
    addTearDown(() => ProcessMihonHost.downloads.value = null);
    await tester.pumpWidget(
      MaterialApp(
        theme: DotlineThemes.dark,
        home: const Scaffold(body: MihonDownloadPill()),
      ),
    );
    expect(find.byType(Text), findsNothing);

    ProcessMihonHost.downloads.value = const MihonDownload(
      MihonDownloadKind.browser,
      0.42,
    );
    await tester.pump();
    expect(
      find.text('${AppText.downloadingMihonBrowser} · 42%'),
      findsOneWidget,
    );

    ProcessMihonHost.downloads.value = null;
    await tester.pump();
    expect(find.byType(Text), findsNothing);
  });
}
