import 'package:bacakomik_app/core/network/image_cache.dart';
import 'package:bacakomik_app/core/source/extension_meta.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// An extension's icon from its repo, kept with the covers so it shows
/// offline. Without one (or while it loads, or when it fails) the first
/// letter of the name.
class ExtensionIcon extends StatelessWidget {
  const ExtensionIcon(this.meta, {super.key, this.size = 40});

  final ExtensionMeta meta;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final letter = Center(
      child: Text(
        // An extension may ship without a name.
        (meta.name.characters.firstOrNull ?? '?').toUpperCase(),
        style: DotlineText.headline.copyWith(color: c.ink),
      ),
    );
    final url = meta.iconUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(DotRadius.s),
      child: SizedBox.square(
        dimension: size,
        child: ColoredBox(
          color: c.surfaceRaised,
          child: url == null
              ? letter
              : CachedNetworkImage(
                  cacheManager: coverImageCache,
                  imageUrl: url,
                  fit: BoxFit.cover,
                  memCacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                      .round(),
                  fadeInDuration: DotMotion.press,
                  placeholder: (_, _) => letter,
                  errorWidget: (_, _, _) => letter,
                ),
        ),
      ),
    );
  }
}
