import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:flutter/material.dart';

/// Release notes (the GitHub release's Markdown) in Dotline type: `#`
/// headings as labels, `-` / `*` lists as bullets, `**bold**`, `` `code` ``
/// and `[links](url)` as their text. Anything else is plain text.
class ReleaseNotes extends StatelessWidget {
  const ReleaseNotes(this.markdown, {super.key});

  final String markdown;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final body = DotlineText.body.copyWith(color: c.inkMuted);
    final blocks = <Widget>[];
    for (final raw in markdown.replaceAll('\r\n', '\n').split('\n')) {
      final line = raw.trimRight();
      if (line.trim().isEmpty) continue;
      final heading = RegExp(r'^\s*#{1,6}\s+(.*)$').firstMatch(line);
      if (heading != null) {
        blocks.add(
          Padding(
            padding: EdgeInsets.only(
              top: blocks.isEmpty ? 0 : DotSpace.s4,
              bottom: DotSpace.s2,
            ),
            child: Text(
              _plain(heading.group(1)!).toUpperCase(),
              style: DotlineText.label.copyWith(color: c.inkFaint),
            ),
          ),
        );
        continue;
      }
      final bullet = RegExp(r'^(\s*)[-*+]\s+(.*)$').firstMatch(line);
      if (bullet != null) {
        final depth = (bullet.group(1)!.length ~/ 2).clamp(0, 3);
        blocks.add(
          Padding(
            padding: EdgeInsets.only(
              left: DotSpace.s4 * depth,
              bottom: DotSpace.s2,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('·  ', style: body.copyWith(color: c.ink)),
                Expanded(child: Text.rich(_inline(bullet.group(2)!, body, c))),
              ],
            ),
          ),
        );
        continue;
      }
      blocks.add(
        Padding(
          padding: const EdgeInsets.only(bottom: DotSpace.s2),
          child: Text.rich(_inline(line.trim(), body, c)),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: blocks,
    );
  }

  static final _token = RegExp(
    r'\*\*(.+?)\*\*|__(.+?)__|`([^`]+)`|\[([^\]]+)\]\([^)]*\)',
  );

  /// [text] with its inline Markdown turned into styles.
  static TextSpan _inline(String text, TextStyle base, DotlineColors c) {
    final spans = <InlineSpan>[];
    var at = 0;
    for (final m in _token.allMatches(text)) {
      if (m.start > at) spans.add(TextSpan(text: text.substring(at, m.start)));
      if (m.group(1) ?? m.group(2) case final bold?) {
        spans.add(
          TextSpan(
            text: bold,
            style: TextStyle(color: c.ink, fontWeight: FontWeight.w600),
          ),
        );
      } else if (m.group(3) case final code?) {
        spans.add(TextSpan(text: code, style: DotlineText.data));
      } else {
        spans.add(TextSpan(text: m.group(4)));
      }
      at = m.end;
    }
    if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
    return TextSpan(style: base, children: spans);
  }

  /// [text] without inline Markdown marks.
  static String _plain(String text) =>
      text.replaceAllMapped(_token, (m) => m[1] ?? m[2] ?? m[3] ?? m[4] ?? '');
}
