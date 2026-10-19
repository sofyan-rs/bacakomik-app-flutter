import 'package:bacakomik_app/core/presentation/widgets/dotline/pressable.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// 52-high `surfaceRaised` search pill.
///
/// With [onTap] and no [controller] it is a button that opens search
/// (Jelajah); otherwise it is a text input.
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.hint,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.onClear,
  });

  final String hint;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final hintStyle = DotlineText.body.copyWith(color: c.inkFaint);

    final field = controller == null && onTap != null
        ? Text(hint, style: hintStyle, maxLines: 1)
        : TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: autofocus,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            textInputAction: TextInputAction.search,
            style: DotlineText.body.copyWith(color: c.ink),
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: hint,
              hintStyle: hintStyle,
            ),
          );

    final pill = Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: BorderRadius.circular(DotRadius.pill),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons300.search,
            size: DotSize.iconSmall,
            color: c.inkMuted,
          ),
          const SizedBox(width: DotSpace.s3),
          Expanded(child: field),
          if (onClear != null && controller != null)
            ListenableBuilder(
              listenable: controller!,
              builder: (context, _) => controller!.text.isEmpty
                  ? const SizedBox.shrink()
                  : GestureDetector(
                      onTap: onClear,
                      child: Semantics(
                        button: true,
                        label: 'Hapus',
                        child: Icon(
                          LucideIcons300.x,
                          size: DotSize.iconSmall,
                          color: c.inkMuted,
                        ),
                      ),
                    ),
            ),
        ],
      ),
    );

    return controller == null && onTap != null
        ? Pressable(onTap: onTap, semanticLabel: hint, child: pill)
        : pill;
  }
}
