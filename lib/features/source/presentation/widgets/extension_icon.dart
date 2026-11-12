import 'package:yoru/core/network/image_cache.dart';
import 'package:yoru/core/presentation/widgets/dotline/comic_cover.dart';
import 'package:yoru/core/source/extension_meta.dart';
import 'package:yoru/core/theme/dotline_colors.dart';
import 'package:yoru/core/theme/dotline_text.dart';
import 'package:yoru/core/theme/dotline_tokens.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

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
    final width = (size * MediaQuery.devicePixelRatioOf(context)).round();
    return ClipRRect(
      borderRadius: BorderRadius.circular(DotRadius.s),
      child: SizedBox.square(
        dimension: size,
        child: ColoredBox(
          color: c.surfaceRaised,
          child: url == null
              ? letter
              : CachedNetworkImage(
                  key: coverKey(url),
                  cacheManager: coverImageCache,
                  imageUrl: url,
                  fit: BoxFit.cover,
                  memCacheWidth: width,
                  fadeInDuration: DotMotion.press,
                  placeholder: (_, _) => letter,
                  errorWidget: (_, url, _) {
                    forgetFailedCover(url, width);
                    return letter;
                  },
                ),
        ),
      ),
    );
  }
}
