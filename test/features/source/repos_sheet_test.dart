import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yoru/core/constants/texts.dart';
import 'package:yoru/core/theme/dotline_theme.dart';
import 'package:yoru/features/source/presentation/bloc/extensions_cubit.dart';
import 'package:yoru/features/source/presentation/widgets/repos_sheet.dart';

class _MockCubit extends MockCubit<ExtensionsState>
    implements ExtensionsCubit {}

void main() {
  late _MockCubit cubit;

  setUp(() {
    cubit = _MockCubit();
    when(() => cubit.state).thenReturn(const ExtensionsState());
  });

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      theme: DotlineThemes.dark,
      home: Scaffold(
        body: BlocProvider<ExtensionsCubit>.value(
          value: cubit,
          child: const SingleChildScrollView(child: ReposSheet()),
        ),
      ),
    ),
  );

  testWidgets('iOS asks for a Yoru repo only', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await pump(tester);
    expect(find.text(AppText.repoHintIos), findsOneWidget);
    expect(find.text(AppText.repoHint), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Android lists the Mihon formats too', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await pump(tester);
    expect(find.text(AppText.repoHint), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('shows why a repo was turned away, in full', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    when(() => cubit.addRepo(any()))
        .thenAnswer((_) async => AppText.mihonRepoUnsupportedIos);
    await pump(tester);
    await tester.enterText(
      find.byType(TextField),
      'https://github.com/keiyoushi/extensions/raw/repo/index.pb',
    );
    await tester.tap(find.text(AppText.addRepo));
    await tester.pumpAndSettle();
    expect(find.text(AppText.mihonRepoUnsupportedIos), findsOneWidget);
    final text = tester.widget<TextField>(find.byType(TextField));
    expect(text.decoration?.errorMaxLines, 3);
    debugDefaultTargetPlatformOverride = null;
  });
}
