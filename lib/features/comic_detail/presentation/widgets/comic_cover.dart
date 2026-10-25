import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/core/utils/utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';
import 'package:bacakomik_app/core/network/image_cache.dart';

/// Centered detail cover. Tap to view it large and save it to the gallery.
class DetailCover extends StatelessWidget {
  const DetailCover({super.key, required this.cover});

  final String? cover;

  static const width = 168.0;

  void _showLarge(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(DotSpace.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(DotRadius.m),
              child: CachedNetworkImage(
                cacheManager: coverImageCache,
                imageUrl: url,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: DotSpace.s4),
            DotButton(
              label: AppText.saveImg,
              leading: LucideIcons300.download,
              size: DotButtonSize.medium,
              onTap: () {
                Navigator.of(context).pop();
                saveImg(context: context, img: url, cache: coverImageCache);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = cover ?? '';
    return Center(
      child: SizedBox(
        width: width,
        child: Pressable(
          semanticLabel: AppText.seeCover,
          onTap: url.isEmpty ? null : () => _showLarge(context, url),
          child: ComicCover(imageUrl: url, radius: DotRadius.m),
        ),
      ),
    );
  }
}
