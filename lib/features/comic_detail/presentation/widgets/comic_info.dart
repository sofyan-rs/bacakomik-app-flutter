import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/comic_detail/presentation/widgets/comic_title.dart';
import 'package:flutter/material.dart';

/// Meta line, title, author, source, three stat tiles, synopsis and genres.
class ComicInfo extends StatefulWidget {
  const ComicInfo({
    super.key,
    required this.details,
    this.source,
    this.onGenreTap,
  });

  final ComicDetails details;

  /// Where the series comes from, e.g. `VoraToon · ID`; hidden when null.
  final String? source;

  /// Tapping a genre chip; null leaves the chips inert.
  final void Function(Genre genre)? onGenreTap;

  static final _yearPattern = RegExp(r'\d{4}');

  /// Year from the API release date (`2018-04-01` → `2018`).
  static String year(String released) {
    final match = _yearPattern.firstMatch(released);
    return match?.group(0) ?? '-';
  }

  /// Separators sites put between alternative titles; ` / ` but not `1/2`.
  /// A line break is how [SeriesDetailResponse] stores a source's list.
  static final _altStrongSeparator = RegExp(r'\s*[•|;\n]\s*|\s+/\s+');

  /// Titles have commas too, so `, ` splits only when nothing else does.
  /// A comma without a space stays (`10,000 Years`).
  static final _altCommaSeparator = RegExp(r'\s*,\s+');

  /// Separators left at either end of a part (`Title ,`).
  static final _altEdges = RegExp(r'^[\s,;•|]+|[\s,;•|]+$');

  /// Values sources send for "no alternative title". `Field Kosong` is
  /// VoraToon's.
  static const _altPlaceholders = {'', '-', '?', 'n/a', 'none', 'field kosong'};

  /// The alternative titles to show, joined with ` · `, or null when there
  /// are none.
  ///
  /// Newer extensions send a list (stored one per line). Older ones and stored
  /// details send one string: a native title, or a list that mixes English,
  /// romaji and native titles and may repeat the main title. Placeholders,
  /// repeats and the main title are dropped; the source's order stays.
  static String? altTitles(String title, String alternativeTitle) {
    String key(String s) => s
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase()
        .replaceAll(RegExp('[‘’`]'), "'");
    final separator = _altStrongSeparator.hasMatch(alternativeTitle)
        ? _altStrongSeparator
        : _altCommaSeparator;
    final seen = {key(title)};
    final parts = [
      for (final part in alternativeTitle.split(separator))
        if (part.replaceAll(RegExp(r'\s+'), ' ').replaceAll(_altEdges, '')
            case final p
            when !_altPlaceholders.contains(p.toLowerCase()) &&
                seen.add(key(p)))
          p,
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  @override
  State<ComicInfo> createState() => _ComicInfoState();
}

class _ComicInfoState extends State<ComicInfo> {
  static const _collapsedLines = 4;
  var _expanded = false;
  var _altExpanded = false;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final d = widget.details;
    final year = ComicInfo.year(d.released);
    final alt = ComicInfo.altTitles(d.title, d.alternativeTitle);
    final meta = [
      if (d.type != '-') d.type,
      d.status,
      if (year != '-') year,
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          meta.toUpperCase(),
          style: DotlineText.label.copyWith(color: c.inkFaint),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DotSpace.s3),
        ComicTitle(d.title),
        if (alt != null) ...[
          const SizedBox(height: DotSpace.s2),
          GestureDetector(
            onTap: () => setState(() => _altExpanded = !_altExpanded),
            child: Text(
              alt,
              style: DotlineText.bodyS.copyWith(color: c.inkFaint),
              textAlign: TextAlign.center,
              maxLines: _altExpanded ? null : 2,
              overflow: _altExpanded ? null : TextOverflow.ellipsis,
            ),
          ),
        ],
        // The API sends `?` (or nothing) when the author is unknown.
        if (!const {'', '-', '?'}.contains(d.author.trim())) ...[
          const SizedBox(height: DotSpace.s2),
          Text(
            d.author,
            style: DotlineText.bodyS.copyWith(color: c.inkMuted),
            textAlign: TextAlign.center,
          ),
        ],
        if (widget.source case final source?) ...[
          const SizedBox(height: DotSpace.s2),
          Text(
            '${AppText.sourceFrom} $source'.toUpperCase(),
            style: DotlineText.label.copyWith(color: c.inkFaint),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: DotSpace.s5),
        Row(
          children: [
            Expanded(
              child: StatTile(
                value: d.rating,
                label: AppText.rating,
                compact: true,
              ),
            ),
            const SizedBox(width: DotSpace.s3),
            Expanded(
              child: StatTile(
                value: '${d.chapters.length}',
                label: AppText.chapter,
                compact: true,
              ),
            ),
            const SizedBox(width: DotSpace.s3),
            Expanded(
              child: StatTile(
                value: year,
                label: AppText.released,
                compact: true,
              ),
            ),
          ],
        ),
        if (d.synopsis.isNotEmpty) ...[
          const SizedBox(height: DotSpace.s5),
          Text(
            AppText.synopsis.toUpperCase(),
            style: DotlineText.label.copyWith(color: c.inkFaint),
          ),
          const SizedBox(height: DotSpace.s2),
          LayoutBuilder(
            builder: (context, constraints) {
              final style = DotlineText.body.copyWith(color: c.inkMuted);
              final painter = TextPainter(
                text: TextSpan(text: d.synopsis, style: style),
                maxLines: _collapsedLines,
                textDirection: Directionality.of(context),
              )..layout(maxWidth: constraints.maxWidth);
              final overflows = painter.didExceedMaxLines;
              painter.dispose();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.synopsis,
                    style: style,
                    maxLines: _expanded ? null : _collapsedLines,
                    overflow: _expanded ? null : TextOverflow.ellipsis,
                  ),
                  if (overflows) ...[
                    const SizedBox(height: DotSpace.s2),
                    GestureDetector(
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: Text(
                        _expanded ? AppText.hide : AppText.readMore,
                        style: DotlineText.body.copyWith(
                          color: c.ink,
                          decoration: TextDecoration.underline,
                          decorationColor: c.ink,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
        if (d.genres.isNotEmpty) ...[
          const SizedBox(height: DotSpace.s5),
          Wrap(
            spacing: DotSpace.s2,
            runSpacing: DotSpace.s2,
            children: [
              for (final genre in d.genres)
                DotChip(
                  label: genre.name,
                  onTap: widget.onGenreTap == null
                      ? null
                      : () => widget.onGenreTap!(genre),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
