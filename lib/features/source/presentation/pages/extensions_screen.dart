import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/di/injection.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/source/extension_meta.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/core/utils/language_names.dart';
import 'package:bacakomik_app/features/source/presentation/bloc/extensions_cubit.dart';
import 'package:bacakomik_app/features/source/presentation/widgets/extension_filters.dart';
import 'package:bacakomik_app/features/source/presentation/widgets/extension_icon.dart';
import 'package:bacakomik_app/features/source/presentation/widgets/mihon_settings_sheet.dart';
import 'package:bacakomik_app/features/source/presentation/widgets/repos_sheet.dart';
import 'package:bacakomik_app/features/source/presentation/widgets/source_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';
import 'package:bacakomik_app/features/source/presentation/widgets/languages_sheet.dart';

/// Installed extensions with their updates, and the ones the repos offer,
/// filtered by language.
class ExtensionsScreen extends StatelessWidget {
  const ExtensionsScreen({super.key, this.showAvailable = false});

  final bool showAvailable;

  static Future<void> open(
    BuildContext context, {
    bool showAvailable = false,
  }) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ExtensionsScreen(showAvailable: showAvailable),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ExtensionsCubit>()..refresh(),
      child: _ExtensionsView(showAvailable: showAvailable),
    );
  }
}

enum _Tab { installed, available }

class _ExtensionsView extends StatefulWidget {
  const _ExtensionsView({required this.showAvailable});

  final bool showAvailable;

  @override
  State<_ExtensionsView> createState() => _ExtensionsViewState();
}

class _ExtensionsViewState extends State<_ExtensionsView> {
  late var _tab = widget.showAvailable ? _Tab.available : _Tab.installed;

  /// Search, language and 18+ filter, shared by both tabs; adult
  /// extensions start hidden.
  var _filter = const ExtensionFilter(hideNsfw: true);
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Widget _filterBar(List<ExtensionMeta> extensions) => SliverToBoxAdapter(
    child: ExtensionFilterBar(
      filter: _filter,
      extensions: extensions,
      controller: _search,
      onChanged: (filter) => setState(() => _filter = filter),
    ),
  );

  /// Shown when the filter hides every extension of a tab.
  Widget get _noMatch => const SliverToBoxAdapter(
    child: EmptyState(
      icon: LucideIcons300.searchX,
      title: AppText.noMatchingExtensions,
      message: AppText.noMatchingExtensionsHint,
    ),
  );

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _install(ExtensionMeta meta, {bool update = false}) async {
    final error = await context.read<ExtensionsCubit>().install(meta);
    if (!mounted) return;
    _message(
      error ??
          '${meta.name} ${update ? AppText.extensionUpdated : AppText.extensionInstalled}',
    );
  }

  Future<void> _uninstall(ExtensionMeta meta) async {
    final confirmed = await showDotSheet<bool>(
      context: context,
      builder: (context) {
        final c = Dotline.of(context);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ActionSheetHeader(
              icon: LucideIcons300.trash2,
              title: '${AppText.uninstall} ${meta.name}',
              subtitle: extensionLine(meta),
            ),
            const SizedBox(height: DotSpace.s4),
            Text(
              AppText.uninstallDescription,
              style: DotlineText.body.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: DotSpace.s5),
            DotButton.destructive(
              label: AppText.uninstall,
              onTap: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: DotSpace.s3),
            DotButton.outline(
              label: AppText.cancel,
              onTap: () => Navigator.of(context).pop(false),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    final error = await context.read<ExtensionsCubit>().uninstall(meta.id);
    if (error != null && mounted) _message(error);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ExtensionsCubit>().state;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final cubit = context.read<ExtensionsCubit>();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Outside the scroll view so the title stays put.
            DotTopBar(
              title: AppText.extensions,
              actions: [
                RoundIconButton(
                  icon: LucideIcons300.gitBranch,
                  semanticLabel: AppText.manageRepos,
                  iconSize: DotSize.iconSmall,
                  onTap: () => showReposSheet(context, cubit),
                ),
              ],
            ),
            // The tabs stay put too; search and the lists scroll.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DotSpace.s4,
                DotSpace.s2,
                DotSpace.s4,
                DotSpace.s4,
              ),
              child: SegmentedControl<_Tab>(
                selected: _tab,
                onChanged: (tab) => setState(() => _tab = tab),
                segments: [
                  Segment(
                    value: _Tab.installed,
                    label: state.updateCount > 0
                        ? '${AppText.installed} · ${state.updateCount}'
                        : AppText.installed,
                  ),
                  const Segment(
                    value: _Tab.available,
                    label: AppText.available,
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: Dotline.of(context).ink,
                backgroundColor: Dotline.of(context).surface,
                onRefresh: cubit.refresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    ...switch (_tab) {
                      _Tab.installed => _installed(state),
                      _Tab.available => _available(state),
                    },
                    SliverPadding(
                      padding: EdgeInsets.only(
                        bottom: bottomInset + DotSpace.s5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _installed(ExtensionsState state) {
    if (state.installed.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: EmptyState(
            icon: LucideIcons300.puzzle,
            title: AppText.noSourceShort,
            message: AppText.noExtensionsHint,
            actionLabel: AppText.available,
            onAction: () => setState(() => _tab = _Tab.available),
          ),
        ),
      ];
    }
    final list = state.installed.where(_filter.matches).toList();
    return [
      _filterBar(state.installed),
      if (list.isEmpty) _noMatch,
      SliverListGroup(
        itemCount: list.length,
        itemBuilder: (context, i) {
          final meta = list[i];
          final update = state.updateFor(meta.id);
          return _ExtensionRow(
            meta: meta,
            busy: state.busy.contains(meta.id),
            action: update != null && update.supported
                ? _RowAction(
                    label: AppText.update,
                    onTap: () => _install(update, update: true),
                  )
                : null,
            // The new version goes in the subtitle; the button stays short.
            newVersion: update?.supported == true ? update!.version : null,
            onLanguages: meta.languages.isEmpty
                ? null
                : () => showLanguagesSheet(context, meta),
            onSettings: meta.hasSettings
                ? () => showMihonSettings(context, meta)
                : null,
            onRemove: () => _uninstall(meta),
          );
        },
      ),
    ];
  }

  List<Widget> _available(ExtensionsState state) {
    final all = state.notInstalled;
    final list = all.where(_filter.matches).toList();
    final failed = state.repos.where((r) => r.error != null).toList();

    return [
      _filterBar(all),
      for (final repo in failed)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              DotSpace.s4,
              0,
              DotSpace.s4,
              DotSpace.s3,
            ),
            child: Text(
              '${AppText.repoFailed}: ${repo.url}',
              style: DotlineText.bodyS.copyWith(
                color: Dotline.of(context).accentText,
              ),
            ),
          ),
        ),
      if (state.loading && list.isEmpty)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(DotSpace.s7),
            child: Center(child: DotLoader()),
          ),
        )
      else if (list.isEmpty && all.isNotEmpty)
        _noMatch
      else if (list.isEmpty)
        SliverToBoxAdapter(
          child: EmptyState(
            icon: LucideIcons300.packageCheck,
            title: AppText.noAvailableExtensions,
            message: AppText.noAvailableExtensionsHint,
          ),
        )
      else
        SliverListGroup(
          itemCount: list.length,
          itemBuilder: (context, i) {
            final meta = list[i];
            return _ExtensionRow(
              meta: meta,
              busy: state.busy.contains(meta.id),
              action: _RowAction(
                label: meta.supported
                    ? AppText.install
                    : AppText.needsAppUpdate,
                onTap: meta.supported ? () => _install(meta) : null,
              ),
            );
          },
        ),
    ];
  }
}

class _RowAction {
  const _RowAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;
}

class _ExtensionRow extends StatelessWidget {
  const _ExtensionRow({
    required this.meta,
    required this.busy,
    this.action,
    this.newVersion,
    this.onLanguages,
    this.onSettings,
    this.onRemove,
  });

  final ExtensionMeta meta;
  final bool busy;
  final _RowAction? action;

  /// Offered update, shown as `v1.0.0 → v1.0.1`.
  final String? newVersion;

  /// Opens the language toggles of a multi-language extension.
  final VoidCallback? onLanguages;

  /// Opens a Mihon extension's source settings.
  final VoidCallback? onSettings;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    return ListRow(
      title: meta.name,
      subtitleWidget: ExtensionLine(
        meta,
        suffix: newVersion == null ? '' : ' → v$newVersion',
      ),
      leading: ExtensionIcon(meta),
      trailing: busy
          ? const SizedBox(width: 48, child: DotLoader(dots: 3))
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // With the language and remove buttons beside it, an
                // update is an icon; the new version is in the subtitle.
                if (action case final action? when onRemove != null)
                  RoundIconButton(
                    icon: LucideIcons300.download,
                    semanticLabel: '${action.label} ${meta.name}',
                    iconSize: DotSize.iconSmall,
                    background: c.accent,
                    foreground: c.onAccent,
                    onTap: action.onTap,
                  )
                else if (action case final action?)
                  DotButton(
                    label: action.label,
                    onTap: action.onTap,
                    size: DotButtonSize.medium,
                    expand: false,
                  ),
                if (onLanguages != null)
                  RoundIconButton(
                    icon: LucideIcons300.languages,
                    semanticLabel: '${AppText.languages} ${meta.name}',
                    iconSize: DotSize.iconSmall,
                    background: Colors.transparent,
                    onTap: onLanguages,
                  ),
                if (onSettings != null)
                  RoundIconButton(
                    icon: LucideIcons300.settings2,
                    semanticLabel: '${AppText.sourceSettings} ${meta.name}',
                    iconSize: DotSize.iconSmall,
                    background: Colors.transparent,
                    onTap: onSettings,
                  ),
                if (onRemove != null)
                  RoundIconButton(
                    icon: LucideIcons300.trash2,
                    semanticLabel: '${AppText.uninstall} ${meta.name}',
                    iconSize: DotSize.iconSmall,
                    background: Colors.transparent,
                    onTap: onRemove,
                  ),
              ],
            ),
    );
  }
}

/// English name of a language code, else the code itself.
String languageName(String code) =>
    languageNames[code.toLowerCase()] ?? code.toUpperCase();
