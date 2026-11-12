import 'package:yoru/core/constants/texts.dart';
import 'package:yoru/core/di/injection.dart';
import 'package:yoru/core/presentation/widgets/dotline/dotline.dart';
import 'package:yoru/features/latest/presentation/bloc/latest_bloc.dart';
import 'package:yoru/features/latest/presentation/widgets/latest_chapter_more.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LatestChapterScreen extends StatelessWidget {
  const LatestChapterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const DotTopBar(title: AppText.latest),
            Expanded(
              child: BlocProvider(
                create: (_) => getIt<LatestBloc>(),
                child: const LatestChapterMore(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
