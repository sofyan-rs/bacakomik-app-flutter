import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/source/extension_meta.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/source/presentation/pages/extensions_screen.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// What the Extensions lists show: a name or site search, one language,
/// and whether adult extensions are hidden.
class ExtensionFilter {
  const ExtensionFilter({this.query = '', this.lang, this.hideNsfw = false});

  final String query;

  /// Null shows every language.
  final String? lang;
  final bool hideNsfw;

  bool get active => query.isNotEmpty || lang != null || hideNsfw;

  ExtensionFilter copyWith({
    String? query,
    String? Function()? lang,
    bool? hideNsfw,
  }) => ExtensionFilter(
    query: query ?? this.query,
    lang: lang == null ? this.lang : lang(),
    hideNsfw: hideNsfw ?? this.hideNsfw,
  );

  bool matches(ExtensionMeta meta) {
    if (hideNsfw && meta.nsfw) return false;
    if (lang case final lang? when !languagesOf(meta).contains(lang)) {
      return false;
    }
    final q = query.trim().toLowerCase();
    return q.isEmpty ||
        meta.name.toLowerCase().contains(q) ||
        meta.domain.toLowerCase().contains(q);
  }

  /// Every language [meta] reads: a multi-language extension shows under
  /// each of its languages, so MangaDex is found under Indonesian.
  static Set<String> languagesOf(ExtensionMeta meta) => {
    meta.lang,
    ...meta.languages,
    for (final s in meta.mihonSources) s.lang,
  };
}

/// Search field, a language picker and an 18+ switch above an extension
/// list.
class ExtensionFilterBar extends StatelessWidget {
  const ExtensionFilterBar({
    super.key,
    required this.filter,
    required this.extensions,
    required this.controller,
    required this.onChanged,
  });

  final ExtensionFilter filter;

  /// The list being filtered, for the languages it has and their counts.
  final List<ExtensionMeta> extensions;
  final TextEditingController controller;
  final ValueChanged<ExtensionFilter> onChanged;

  Future<void> _pickLanguage(BuildContext context) async {
    final counts = <String, int>{};
    for (final e in extensions) {
      for (final l in ExtensionFilter.languagesOf(e)) {
        counts.update(l, (n) => n + 1, ifAbsent: () => 1);
      }
    }
    final picked = await showDotSheet<_Pick>(
      context: context,
      builder: (_) => _LanguageSheet(
        counts: counts,
        total: extensions.length,
        selected: filter.lang,
      ),
    );
    if (picked != null) onChanged(filter.copyWith(lang: () => picked.lang));
  }

  @override
  Widget build(BuildContext context) {
    final lang = filter.lang;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DotSpace.s4,
        0,
        DotSpace.s4,
        DotSpace.s4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SearchField(
            hint: AppText.searchExtensions,
            controller: controller,
            onChanged: (q) => onChanged(filter.copyWith(query: q)),
            onClear: () {
              controller.clear();
              onChanged(filter.copyWith(query: ''));
            },
          ),
          const SizedBox(height: DotSpace.s3),
          Row(
            children: [
              DotChip(
                label: lang == null ? AppText.allLanguages : languageName(lang),
                trailing: LucideIcons300.chevronDown,
                selected: lang != null,
                onTap: () => _pickLanguage(context),
              ),
              const SizedBox(width: DotSpace.s2),
              DotChip(
                label: AppText.hideNsfw,
                selected: filter.hideNsfw,
                onTap: () =>
                    onChanged(filter.copyWith(hideNsfw: !filter.hideNsfw)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The language sheet's answer; [lang] null is "all languages".
class _Pick {
  const _Pick(this.lang);

  final String? lang;
}

/// Languages with how many extensions each has. The phone's usual ones
/// (Indonesian, English) come first, then the rest by name.
class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet({
    required this.counts,
    required this.total,
    required this.selected,
  });

  final Map<String, int> counts;
  final int total;
  final String? selected;

  static const _first = ['id', 'en'];

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final langs = counts.keys.toList()
      ..sort((a, b) {
        final ia = _first.indexOf(a);
        final ib = _first.indexOf(b);
        if (ia >= 0 || ib >= 0) {
          return (ia < 0 ? 99 : ia).compareTo(ib < 0 ? 99 : ib);
        }
        return languageName(a).compareTo(languageName(b));
      });
    Widget row(String title, int count, String? lang) => ListRow(
      title: title,
      value: '$count',
      trailing: selected == lang
          ? Icon(LucideIcons300.check, color: c.ink)
          : null,
      onTap: () => Navigator.of(context).pop(_Pick(lang)),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ActionSheetHeader(
          icon: LucideIcons300.languages,
          title: AppText.languages,
        ),
        const SizedBox(height: DotSpace.s4),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListGroup(
                background: Dotline.of(context).bg,
                children: [
                  row(AppText.allLanguages, total, null),
                  for (final l in langs) row(languageName(l), counts[l]!, l),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: DotSpace.s2),
        Text(
          AppText.languageFilterHint,
          style: DotlineText.bodyS.copyWith(color: c.inkFaint),
        ),
      ],
    );
  }
}
