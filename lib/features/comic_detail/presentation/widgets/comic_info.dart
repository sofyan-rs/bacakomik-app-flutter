import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/core/utils/alt_titles.dart';
import 'package:bacakomik_app/features/comic_detail/presentation/widgets/comic_title.dart';
import 'package:flutter/material.dart';

/// Meta line, title, author, source, three stat tiles, synopsis and genres.
class ComicInfo extends StatefulWidget {
  const ComicInfo({
    super.key,
    required this.details,
    this.source,
    this.onGenreTap,
    this.canTapGenre,
    this.chaptersLoading = false,
  });

  final ComicDetails details;

  /// Where the series comes from, e.g. `VoraToon · ID`; hidden when null.
  final String? source;

  /// Tapping a genre chip; null leaves the chips inert.
  final void Function(Genre genre)? onGenreTap;

  /// Whether a genre opens anything; others are plain labels.
  final bool Function(Genre genre)? canTapGenre;

  /// The chapter list is still loading: its count shows as `…`.
  final bool chaptersLoading;

  static final _yearPattern = RegExp(r'\d{4}');

  /// Year from the API release date (`2018-04-01` → `2018`).
  static String year(String released) {
    final match = _yearPattern.firstMatch(released);
    return match?.group(0) ?? '-';
  }

  /// The alternative titles to show, joined with ` · `, or null when there
  /// are none. See [splitAltTitles].
  static String? altTitles(String title, String alternativeTitle) {
    final parts = splitAltTitles(title, alternativeTitle);
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
    final hasRating = !const {'', '-', '0', '0.0'}.contains(d.rating.trim());
    final status = d.status.trim();
    // Each shows only when known: a source without scores gets two tiles.
    // The status, a word rather than a number, follows the source line.
    final tiles = [
      (widget.chaptersLoading ? '…' : '${d.chapters.length}', AppText.chapter),
      if (year != '-') (year, AppText.released),
      if (hasRating) (d.rating.trim(), AppText.score),
    ];
    final meta = d.type == '-' ? '' : d.type;
    final sourceLine = [
      if (widget.source case final source?) '${AppText.sourceFrom} $source',
      if (status.isNotEmpty && status != '-') status,
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (meta.isNotEmpty) ...[
          Text(
            meta.toUpperCase(),
            style: DotlineText.label.copyWith(color: c.inkFaint),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DotSpace.s3),
        ],
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
        if (sourceLine.isNotEmpty) ...[
          const SizedBox(height: DotSpace.s2),
          Text(
            sourceLine.toUpperCase(),
            style: DotlineText.label.copyWith(color: c.inkFaint),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: DotSpace.s5),
        Row(
          children: [
            for (final (i, (value, label)) in tiles.indexed) ...[
              if (i > 0) const SizedBox(width: DotSpace.s3),
              Expanded(
                child: StatTile(value: value, label: label, compact: true),
              ),
            ],
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
                  onTap:
                      widget.onGenreTap == null ||
                          !(widget.canTapGenre?.call(genre) ?? true)
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
