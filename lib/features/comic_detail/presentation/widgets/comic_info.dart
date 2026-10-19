import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:flutter/material.dart';

/// Meta line, title, author, three stat tiles, synopsis and genres.
class ComicInfo extends StatefulWidget {
  const ComicInfo({super.key, required this.details});

  final ComicDetails details;

  static final _yearPattern = RegExp(r'\d{4}');

  /// Year from the API release date (`2018-04-01` → `2018`).
  static String year(String released) {
    final match = _yearPattern.firstMatch(released);
    return match?.group(0) ?? '-';
  }

  @override
  State<ComicInfo> createState() => _ComicInfoState();
}

class _ComicInfoState extends State<ComicInfo> {
  static const _collapsedLines = 4;
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final d = widget.details;
    final year = ComicInfo.year(d.released);
    final meta = [d.type, d.status, if (year != '-') year].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          meta.toUpperCase(),
          style: DotlineText.label.copyWith(color: c.inkFaint),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DotSpace.s3),
        Text(
          d.title,
          style: DotlineText.title.copyWith(color: c.ink),
          textAlign: TextAlign.center,
        ),
        // The API sends `?` (or nothing) when the author is unknown.
        if (!const {'', '-', '?'}.contains(d.author.trim())) ...[
          const SizedBox(height: DotSpace.s2),
          Text(
            d.author,
            style: DotlineText.bodyS.copyWith(color: c.inkMuted),
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
              for (final genre in d.genres) DotChip(label: genre.name),
            ],
          ),
        ],
      ],
    );
  }
}
