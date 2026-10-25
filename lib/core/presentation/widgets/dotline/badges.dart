import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:flutter/material.dart';

/// 6px `accent` dot, optionally followed by an `accentText` label ("BARU").
class NewBadge extends StatelessWidget {
  const NewBadge({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
        ),
        if (label != null) ...[
          const SizedBox(width: 6),
          Text(
            label!.toUpperCase(),
            style: DotlineText.label.copyWith(color: c.accentText),
          ),
        ],
      ],
    );
  }
}

/// `accent` pill with the new chapter count: "3".
class UpdateBadge extends StatelessWidget {
  const UpdateBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DotSpace.s2, vertical: 3),
      decoration: BoxDecoration(
        color: c.accent,
        borderRadius: BorderRadius.circular(DotRadius.pill),
      ),
      child: Text(
        '$count',
        style: DotlineText.data.copyWith(color: c.onAccent),
      ),
    );
  }
}

/// Small round count on `ink`, e.g. active filters next to "FILTER".
class CountBadge extends StatelessWidget {
  const CountBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    return Container(
      height: 20,
      constraints: const BoxConstraints(minWidth: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.ink,
        borderRadius: BorderRadius.circular(DotRadius.pill),
      ),
      child: Text(
        '$count',
        style: DotlineText.data.copyWith(color: c.onInk, height: 1),
      ),
    );
  }
}

/// Small `ink` pill with a language code over a cover: "ID", "EN".
class LangBadge extends StatelessWidget {
  const LangBadge({super.key, required this.lang});

  /// ISO 639-1 code, shown upper-case.
  final String lang;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    return Container(
      // Same size as [UpdateBadge], which sits next to it on covers.
      padding: const EdgeInsets.symmetric(horizontal: DotSpace.s2, vertical: 3),
      decoration: BoxDecoration(
        color: c.ink,
        borderRadius: BorderRadius.circular(DotRadius.pill),
      ),
      child: Text(
        lang.toUpperCase(),
        style: DotlineText.data.copyWith(color: c.onInk),
      ),
    );
  }
}
