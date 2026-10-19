import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/di/injection.dart';
import 'package:bacakomik_app/features/latest/presentation/bloc/latest_bloc.dart';
import 'package:bacakomik_app/features/latest/presentation/widgets/latest_chapter_more.dart';
import 'package:solar_icons/solar_icons.dart';

class LatestChapterScreen extends StatelessWidget {
  const LatestChapterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppText.latest),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(
            SolarIconsOutline.arrowLeft,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      body: BlocProvider(
        create: (_) => getIt<LatestBloc>(),
        child: const LatestChapterMore(),
      ),
    );
  }
}
