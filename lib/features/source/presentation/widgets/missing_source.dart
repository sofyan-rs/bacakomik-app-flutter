import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/di/injection.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/source/extension_manager.dart';
import 'package:bacakomik_app/core/source/extension_meta.dart';
import 'package:bacakomik_app/features/source/presentation/pages/extensions_screen.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// Shown instead of a comic whose source extension is not installed (an
/// old bookmark after uninstalling, or a shared link). Offers to install
/// it from the repos, else to open Extensions. Calls [onInstalled] once
/// the source is there.
class MissingSource extends StatefulWidget {
  const MissingSource({
    super.key,
    required this.sourceId,
    required this.onInstalled,
  });

  final String sourceId;
  final VoidCallback onInstalled;

  @override
  State<MissingSource> createState() => _MissingSourceState();
}

class _MissingSourceState extends State<MissingSource> {
  final _manager = getIt<ExtensionManager>();

  /// The extension in the repos; null while looking or when no repo has it.
  ExtensionMeta? _offered;
  var _looking = true;
  var _installing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _find();
  }

  Future<void> _find() async {
    final catalog = await _manager.catalog();
    if (!mounted) return;
    setState(() {
      _looking = false;
      // A language of a multi-language extension installs the extension.
      _offered = [for (final entry in catalog) ...?entry.repo?.extensions]
          .where((e) => e.sourceFor(widget.sourceId) != null)
          .firstOrNull;
    });
  }

  Future<void> _install(ExtensionMeta meta) async {
    setState(() {
      _installing = true;
      _error = null;
    });
    try {
      await _manager.install(meta);
      // Turn on the comic's language next to the default ones.
      if (meta.sourceFor(widget.sourceId) case final source?
          when source.parentId != null) {
        await _manager.setLanguages(
          meta.id,
          {..._manager.languagesOf(meta.id), source.lang}.toList(),
        );
      }
      widget.onInstalled();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _installing = false);
    }
  }

  Future<void> _openExtensions() async {
    await ExtensionsScreen.open(context, showAvailable: true);
    if (_manager.meta(widget.sourceId) != null) widget.onInstalled();
  }

  @override
  Widget build(BuildContext context) {
    final offered = _offered;
    final name =
        offered?.sourceFor(widget.sourceId)?.name ??
        offered?.name ??
        widget.sourceId;
    return EmptyState(
      icon: LucideIcons300.puzzle,
      title: '$name ${AppText.sourceNotInstalled}',
      message:
          _error ??
          (_looking
              ? AppText.sourceLooking
              : offered == null
              ? AppText.sourceNotInRepos
              : AppText.sourceInstallHint),
      actionLabel: _looking
          ? null
          : offered == null
          ? AppText.extensions
          : _installing
          ? AppText.installing
          : '${AppText.install} $name',
      onAction: _looking || _installing
          ? null
          : offered == null
          ? _openExtensions
          : () => _install(offered),
    );
  }
}
