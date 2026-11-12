import 'package:yoru/core/theme/dotline_theme.dart';
import 'package:yoru/features/update/presentation/widgets/release_notes.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('release notes render Markdown as text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: DotlineThemes.dark,
        home: const Scaffold(
          body: ReleaseNotes(
            '## Changes\n\n### New\n- **Mihon** extensions with `index_v2`\n'
            '- See [the docs](https://example.test)',
          ),
        ),
      ),
    );

    expect(find.text('CHANGES'), findsOneWidget);
    expect(find.text('NEW'), findsOneWidget);
    expect(find.textContaining('##'), findsNothing);
    expect(find.textContaining('**', findRichText: true), findsNothing);
    expect(
      find.text('Mihon extensions with index_v2', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('See the docs', findRichText: true), findsOneWidget);
  });
}
