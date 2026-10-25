import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/di/injection.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/core/utils/utils.dart';
import 'package:bacakomik_app/features/migration/domain/usecases/pick_files.dart';
import 'package:bacakomik_app/features/migration/presentation/bloc/match_cubit.dart';
import 'package:bacakomik_app/features/migration/presentation/pages/match_screen.dart';
import 'package:bacakomik_app/features/migration/presentation/pages/mihon_import_screen.dart';
import 'package:bacakomik_app/features/migration/presentation/pages/source_migration_screen.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// More → Migration: migrate bookmarks between sources, or import a library
/// from Mihon/Tachiyomi or Comix.to.
class MigrationScreen extends StatelessWidget {
  const MigrationScreen({super.key});

  /// Source id the Comix.to export is searched in.
  static const comixSource = 'comix';

  static Future<void> open(BuildContext context) =>
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const MigrationScreen()));

  Future<void> _importComix(BuildContext context) async {
    final picked = await getIt<PickComixCsv>()(const NoParams());
    if (!context.mounted) return;
    picked.fold(
      (failure) => showSnackBar(context: context, message: failure.message),
      (entries) {
        if (entries == null) return;
        if (entries.isEmpty) {
          showSnackBar(context: context, message: AppText.noResults);
          return;
        }
        MatchScreen.open(
          context,
          mode: MatchMode.import,
          target: comixSource,
          items: [
            for (final e in entries)
              MatchItem(title: e.title, lastRead: e.lastRead),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            const DotTopBar(title: AppText.migration),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: DotSpace.s4),
              child: ListGroup(
                children: [
                  ListRow(
                    icon: LucideIcons300.arrowRightLeft,
                    title: AppText.migrateSource,
                    subtitle: AppText.migrateSourceDescription,
                    showChevron: true,
                    onTap: () => SourceMigrationScreen.open(context),
                  ),
                  ListRow(
                    icon: LucideIcons300.archiveRestore,
                    title: AppText.importMihon,
                    subtitle: AppText.importMihonDescription,
                    showChevron: true,
                    onTap: () => MihonImportScreen.open(context),
                  ),
                  ListRow(
                    icon: LucideIcons300.fileSpreadsheet,
                    title: AppText.importComix,
                    subtitle: AppText.importComixDescription,
                    showChevron: true,
                    onTap: () => _importComix(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
