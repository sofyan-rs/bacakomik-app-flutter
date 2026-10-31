import 'package:bacakomik_app/core/network/image_cache.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/comic_cover.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Hero tag of one cover on screen, for the flight to the comic's details.
///
/// Equal only for the same [element] (the card showing the cover): the same
/// comic twice on one screen (Home lists it in two rows) never shares a tag,
/// which Flutter does not allow. It also carries the width the card's cover
/// is decoded at, so the flight shows that image, already in memory, instead
/// of decoding the cover again at every size it passes through.
final class CoverHeroTag {
  CoverHeroTag(BuildContext context, this.imageUrl) : element = context;

  /// Typed as [BuildContext] (the card's [Element]); compared by identity.
  final BuildContext element;
  final String imageUrl;

  /// Set by [CoverHero] once the card's cover is laid out.
  int? decodeWidth;

  @override
  bool operator ==(Object other) =>
      other is CoverHeroTag && identical(other.element, element);

  @override
  int get hashCode => identityHashCode(element);
}

/// [child] (a card's [ComicCover]) as the start of the flight to the
/// comic's details, which wrap their cover in a [Hero] with the same [tag].
class CoverHero extends StatelessWidget {
  const CoverHero({super.key, required this.tag, required this.child});

  final CoverHeroTag? tag;
  final Widget child;

  /// Both ends fly the card's image at the card's decode width.
  static Widget shuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final tag = (fromHeroContext.widget as Hero).tag as CoverHeroTag;
    return ClipRRect(
      borderRadius: BorderRadius.circular(DotRadius.m),
      child: tag.imageUrl.isEmpty
          ? const DotGridPlaceholder()
          : CachedNetworkImage(
              cacheManager: coverImageCache,
              imageUrl: tag.imageUrl,
              fit: BoxFit.cover,
              memCacheWidth: tag.decodeWidth,
              fadeInDuration: Duration.zero,
              placeholder: (_, _) => const DotGridPlaceholder(),
              errorWidget: (_, _, _) => const DotGridPlaceholder(),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tag = this.tag;
    if (tag == null) return child;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth.isFinite) {
          tag.decodeWidth =
              (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context))
                  .round();
        }
        return Hero(tag: tag, flightShuttleBuilder: shuttle, child: child);
      },
    );
  }
}
