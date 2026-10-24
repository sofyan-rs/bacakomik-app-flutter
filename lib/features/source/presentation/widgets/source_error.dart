import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/error/exceptions.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/features/source/presentation/pages/web_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// Error state for a failed source call. A bot check ([Challenge]) offers
/// to pass it in the WebView, whose cookies the extension then reuses, and
/// retries when the WebView closes; anything else shows the message with a
/// retry button.
class SourceError extends StatelessWidget {
  const SourceError({
    super.key,
    required this.message,
    required this.sourceId,
    required this.onRetry,
  });

  final String message;

  /// Extension that made the call; its cookie jar gets the WebView's
  /// cookies. Null when unknown, which disables the WebView offer.
  final String? sourceId;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final url = Challenge.urlOf(message);
    final sourceId = this.sourceId;
    if (url == null || sourceId == null) {
      return EmptyState(
        icon: LucideIcons300.bug,
        title: AppText.error,
        message: message,
        actionLabel: AppText.retry,
        onAction: onRetry,
      );
    }
    return EmptyState(
      icon: LucideIcons300.shieldAlert,
      title: AppText.verificationNeeded,
      message: AppText.verificationNeededHint,
      actionLabel: AppText.verifyInWebView,
      onAction: () async {
        await WebViewScreen.open(context, sourceId: sourceId, url: url);
        onRetry();
      },
    );
  }
}
