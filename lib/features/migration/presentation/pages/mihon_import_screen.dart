import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/di/injection.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/core/utils/utils.dart';
import 'package:bacakomik_app/features/bookmark/presentation/bloc/bookmark_cubit.dart';
import 'package:bacakomik_app/features/category/presentation/bloc/category_cubit.dart';
import 'package:bacakomik_app/features/migration/domain/entities/mihon_import_plan.dart';
import 'package:bacakomik_app/features/migration/presentation/bloc/mihon_import_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// Import bookmarks from a Mihon/Tachiyomi backup, per source.
class MihonImportScreen extends StatelessWidget {
  const MihonImportScreen({super.key});

  static Future<void> open(BuildContext context) =>
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const MihonImportScreen()));

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<MihonImportCubit>(),
    child: const _MihonImportView(),
  );
}

class _MihonImportView extends StatelessWidget {
  const _MihonImportView();

  void _listener(BuildContext context, MihonImportState state) {
    if (state.error case final error?) {
      showSnackBar(context: context, message: error);
    }
    if (state.phase == MihonImportPhase.finished) {
      context.read<BookmarkCubit>().load();
      context.read<CategoryCubit>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MihonImportCubit, MihonImportState>(
      listenWhen: (a, b) =>
          (b.error != null && a.error != b.error) || a.phase != b.phase,
      listener: _listener,
      builder: (context, state) {
        final c = Dotline.of(context);
        final cubit = context.read<MihonImportCubit>();
        return PopScope(
          canPop: state.phase != MihonImportPhase.importing,
          child: Scaffold(
            body: SafeArea(
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(
                    child: DotTopBar(title: AppText.importMihon),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        DotSpace.s4,
                        0,
                        DotSpace.s4,
                        DotSpace.s4,
                      ),
                      child: Text(switch (state.phase) {
                        MihonImportPhase.finished => switch (state.result) {
                          final r? =>
                            '${AppText.importDone} · ${r.added} ${AppText.added}'
                                '${r.existing > 0 ? ' · ${r.existing} ${AppText.alreadyInLibrary}' : ''}'
                                '${r.sameTitle > 0 ? ' · ${r.sameTitle} ${AppText.sameTitleElsewhere}' : ''}. '
                                '${AppText.importLoadHint}',
                          null => AppText.importDone,
                        },
                        _ => AppText.mihonHint,
                      }, style: DotlineText.bodyS.copyWith(color: c.inkFaint)),
                    ),
                  ),
                  if (state.phase == MihonImportPhase.reading)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(DotSpace.s6),
                        child: Center(child: DotLoader()),
                      ),
                    ),
                  if (state.supported.isNotEmpty) ...[
                    const SliverToBoxAdapter(
                      child: SectionLabel(label: AppText.sources),
                    ),
                    SliverListGroup(
                      itemCount: state.supported.length,
                      itemBuilder: (context, i) =>
                          _GroupRow(group: state.supported[i], state: state),
                    ),
                  ],
                  if (state.unsupported.isNotEmpty) ...[
                    const SliverToBoxAdapter(
                      child: SectionLabel(label: AppText.notAvailableHere),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DotSpace.s4,
                        ),
                        child: Text(
                          [
                            for (final g in state.unsupported)
                              '${g.name} (${g.total})',
                          ].join(' · '),
                          style: DotlineText.bodyS.copyWith(color: c.inkFaint),
                        ),
                      ),
                    ),
                  ],
                  const SliverToBoxAdapter(
                    child: SizedBox(height: DotSpace.s4),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(DotSpace.s4),
                child: switch (state.phase) {
                  MihonImportPhase.idle ||
                  MihonImportPhase.reading => DotButton(
                    label: state.phase == MihonImportPhase.reading
                        ? AppText.readingFile
                        : AppText.chooseFile,
                    leading: LucideIcons300.fileUp,
                    onTap: state.phase == MihonImportPhase.reading
                        ? null
                        : cubit.pickFile,
                  ),
                  MihonImportPhase.loaded => DotButton(
                    label:
                        '${AppText.importCount} '
                        '${AppText.count(state.selectedCount, AppText.comic, AppText.comics)}',
                    onTap: state.selectedCount == 0 ? null : cubit.import,
                  ),
                  MihonImportPhase.importing => const DotButton(
                    label: AppText.importing,
                    onTap: null,
                  ),
                  MihonImportPhase.finished => DotButton(
                    label: AppText.done,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({required this.group, required this.state});

  final MihonSourceGroup group;
  final MihonImportState state;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final cubit = context.read<MihonImportCubit>();
    final source = group.source!;
    final installed = cubit.isInstalled(group);
    final installing = state.installing.contains(source.extensionId);
    final checked = state.selected.contains(group.id);
    final editable = state.phase == MihonImportPhase.loaded;
    return ListRow(
      title: source.name,
      subtitle: [
        AppText.count(group.entries.length, AppText.comic, AppText.comics),
        if (group.unreadable > 0)
          '${group.unreadable} ${AppText.unreadableLinks}',
        if (!installed) AppText.needsInstall,
      ].join(' · '),
      onTap: editable ? () => cubit.toggle(group.id) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!installed && editable)
            DotButton.outline(
              label: installing ? AppText.installing : AppText.install,
              size: DotButtonSize.medium,
              expand: false,
              onTap: installing ? null : () => cubit.install(group),
            ),
          Checkbox(
            value: checked,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            activeColor: c.ink,
            checkColor: c.onInk,
            onChanged: editable ? (_) => cubit.toggle(group.id) : null,
          ),
        ],
      ),
    );
  }
}
