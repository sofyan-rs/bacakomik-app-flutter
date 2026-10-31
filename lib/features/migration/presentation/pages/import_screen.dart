import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/di/injection.dart';
import 'package:bacakomik_app/core/source/extension_manager.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/core/utils/utils.dart';
import 'package:bacakomik_app/features/migration/domain/usecases/pick_files.dart';
import 'package:bacakomik_app/features/migration/presentation/bloc/match_cubit.dart';
import 'package:bacakomik_app/features/migration/presentation/pages/match_screen.dart';
import 'package:bacakomik_app/features/migration/presentation/pages/mihon_import_screen.dart';
import 'package:bacakomik_app/features/migration/presentation/widgets/source_choice_sheet.dart';
import 'package:bacakomik_app/features/source/presentation/bloc/sources_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// More → Import from other apps: a library from Mihon/Tachiyomi or
/// Comix.to. Migrating between sources is its own row in More.
class ImportScreen extends StatelessWidget {
  const ImportScreen({super.key});

  /// Source the Comix.to export is searched in unless another is picked.
  static const comixSource = 'comix';

  static Future<void> open(BuildContext context) =>
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const ImportScreen()));

  Future<void> _importComix(BuildContext context) async {
    final picked = await getIt<PickComixCsv>()(const NoParams());
    if (!context.mounted) return;
    final entries = picked.fold((failure) {
      showSnackBar(context: context, message: failure.message);
      return null;
    }, (entries) => entries);
    if (entries == null) return;
    if (entries.isEmpty) {
      showSnackBar(context: context, message: AppText.noResults);
      return;
    }
    // Comix first, even when not installed: MatchScreen offers to install it.
    final installed = context.read<SourcesCubit>().state.installed;
    final target = await showSourceChoiceSheet(
      context,
      title: AppText.importComixTo,
      selected: comixSource,
      choices: [
        if (!installed.any((s) => s.id == comixSource))
          (
            id: comixSource,
            name: getIt<ExtensionManager>().nameOf(comixSource),
            detail: 'comix.to',
          ),
        for (final s in installed) (id: s.id, name: s.name, detail: s.domain),
      ],
    );
    if (target == null || !context.mounted) return;
    MatchScreen.open(
      context,
      mode: MatchMode.import,
      targets: [target],
      items: [
        for (final e in entries)
          MatchItem(title: e.title, lastRead: e.lastRead),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Outside the scroll view so the title stays put.
            const DotTopBar(title: AppText.importFromApps),
            Expanded(
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DotSpace.s4,
                    ),
                    child: ListGroup(
                      children: [
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
          ],
        ),
      ),
    );
  }
}
