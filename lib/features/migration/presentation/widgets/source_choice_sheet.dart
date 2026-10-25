import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

typedef SourceChoice = ({String id, String name, String? detail});

/// Picks one of [choices]. Pops the picked id, or null when dismissed.
Future<String?> showSourceChoiceSheet(
  BuildContext context, {
  required String title,
  required List<SourceChoice> choices,
  String? selected,
  String? emptyMessage,
}) => showDotSheet<String>(
  context: context,
  builder: (context) {
    final c = Dotline.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: DotlineText.title.copyWith(color: c.ink)),
        const SizedBox(height: DotSpace.s4),
        if (choices.isEmpty && emptyMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: DotSpace.s5),
            child: Text(
              emptyMessage,
              style: DotlineText.body.copyWith(color: c.inkMuted),
              textAlign: TextAlign.center,
            ),
          ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListGroup(
                background: c.bg,
                children: [
                  for (final choice in choices)
                    ListRow(
                      title: choice.name,
                      subtitle: choice.detail,
                      trailing: choice.id == selected
                          ? Icon(LucideIcons300.check, color: c.ink)
                          : null,
                      onTap: () => Navigator.of(context).pop(choice.id),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  },
);
