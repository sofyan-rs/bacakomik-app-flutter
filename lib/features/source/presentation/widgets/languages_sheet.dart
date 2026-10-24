import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/di/injection.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/source/extension_manager.dart';
import 'package:bacakomik_app/core/source/extension_meta.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/source/presentation/pages/extensions_screen.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// Turns the languages of a multi-language extension on and off. Each one
/// on is a source of its own, e.g. "MangaDex (EN)"; at least one stays on.
Future<void> showLanguagesSheet(BuildContext context, ExtensionMeta meta) =>
    showDotSheet<void>(
      context: context,
      builder: (_) => _LanguagesSheet(meta: meta),
    );

class _LanguagesSheet extends StatefulWidget {
  const _LanguagesSheet({required this.meta});

  final ExtensionMeta meta;

  @override
  State<_LanguagesSheet> createState() => _LanguagesSheetState();
}

class _LanguagesSheetState extends State<_LanguagesSheet> {
  final _manager = getIt<ExtensionManager>();
  late final _enabled = {..._manager.languagesOf(widget.meta.id)};

  Future<void> _toggle(String language, bool on) async {
    setState(() => on ? _enabled.add(language) : _enabled.remove(language));
    await _manager.setLanguages(widget.meta.id, [
      for (final l in widget.meta.languages)
        if (_enabled.contains(l)) l,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActionSheetHeader(
          icon: LucideIcons300.languages,
          title: '${widget.meta.name} · ${AppText.languages}',
          subtitle: AppText.languagesDescription,
        ),
        const SizedBox(height: DotSpace.s4),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final language in widget.meta.languages)
                ListRow(
                  title: languageName(language),
                  subtitle: language.toUpperCase(),
                  onTap: _enabled.contains(language) && _enabled.length == 1
                      ? null
                      : () => _toggle(language, !_enabled.contains(language)),
                  trailing: DotSwitch(
                    value: _enabled.contains(language),
                    semanticLabel: languageName(language),
                    // The last language on cannot be turned off.
                    onChanged:
                        _enabled.contains(language) && _enabled.length == 1
                        ? null
                        : (on) => _toggle(language, on),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: DotSpace.s3),
        Text(
          AppText.languagesHint,
          style: DotlineText.bodyS.copyWith(color: c.inkFaint),
        ),
      ],
    );
  }
}
