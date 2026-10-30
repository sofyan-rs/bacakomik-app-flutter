import 'dart:async';
import 'dart:io' as io;

import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/di/injection.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/source/extension_bridge.dart';
import 'package:bacakomik_app/core/source/extension_manager.dart';
import 'package:bacakomik_app/core/source/headless_pages.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// A source's site in a WebView, e.g. to pass a Cloudflare check. Uses the
/// extension's User-Agent and copies the cookies it gets into the
/// extension's cookie jar after every page load.
class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key, required this.sourceId, required this.url});

  final String sourceId;
  final String url;

  /// Where there is no WebView (Linux), opens [url] in the browser.
  static Future<void> open(
    BuildContext context, {
    required String sourceId,
    required String url,
  }) async {
    if (!webViewAvailable) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WebViewScreen(sourceId: sourceId, url: url),
      ),
    );
  }

  /// Opens the page of the series [key] on its site, or of its [chapter].
  static Future<void> openSeries(
    BuildContext context, {
    required String sourceId,
    required String key,
    String? chapter,
  }) async {
    final url = await getIt<ExtensionManager>().webUrlOf(key, chapter: chapter);
    if (!context.mounted || url.isEmpty) return;
    await open(context, sourceId: sourceId, url: url);
  }

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  final _bridge = getIt<ExtensionBridge>();
  InAppWebViewController? _controller;
  late var _url = Uri.parse(widget.url);
  String? _title;
  var _progress = 0.0;
  var _canGoBack = false;

  /// Why the page did not load (e.g. a blocked TLS handshake); shown over
  /// the WebView with a retry button.
  String? _error;

  @override
  void dispose() {
    unawaited(_saveCookies(_url));
    super.dispose();
  }

  Future<void> _saveCookies(Uri url) async {
    if (!url.hasScheme || !url.scheme.startsWith('http')) return;
    final cookies = await CookieManager.instance().getCookies(
      url: WebUri.uri(url),
    );
    // The WebView reports name and value only; scope them to the whole site.
    await _bridge.saveCookies(widget.sourceId, url, [
      for (final c in cookies) ?_cookie(c.name, '${c.value}'),
    ]);
  }

  /// Null for a value `dart:io` rejects (e.g. with spaces or quotes).
  static io.Cookie? _cookie(String name, String value) {
    try {
      return io.Cookie(name, value)..path = '/';
    } on FormatException {
      return null;
    }
  }

  Future<void> _clearCookies() async {
    final root = Uri(scheme: _url.scheme, host: _url.host);
    await CookieManager.instance().deleteCookies(
      url: WebUri.uri(root),
      domain: _url.host,
    );
    await _bridge.clearCookies(widget.sourceId, root);
    await _controller?.reload();
    if (mounted) {
      showSnackBar(context: context, message: AppText.cookiesCleared);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    return PopScope(
      canPop: !_canGoBack,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _controller?.goBack();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DotTopBar(
                title: _title?.isNotEmpty == true ? _title : _url.host,
                subtitle: _url.host,
                // Closes the screen; system back goes back a page first.
                onBack: () => Navigator.of(context).pop(),
                actions: [
                  DotMenuButton(
                    items: [
                      DotMenuItem(
                        label: AppText.refresh,
                        icon: LucideIcons300.rotateCw,
                        onTap: () => _controller?.reload(),
                      ),
                      DotMenuItem(
                        label: AppText.share,
                        icon: LucideIcons300.share2,
                        onTap: () => SharePlus.instance.share(
                          ShareParams(uri: _url, subject: _title),
                        ),
                      ),
                      DotMenuItem(
                        label: AppText.openInBrowser,
                        icon: LucideIcons300.externalLink,
                        onTap: () => launchUrl(
                          _url,
                          mode: LaunchMode.externalApplication,
                        ),
                      ),
                      DotMenuItem(
                        label: AppText.clearCookies,
                        icon: LucideIcons300.cookie,
                        destructive: true,
                        onTap: _clearCookies,
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(
                height: 2,
                child: _progress < 1
                    ? LinearProgressIndicator(
                        value: _progress,
                        color: c.ink,
                        backgroundColor: Colors.transparent,
                      )
                    : null,
              ),
              Expanded(
                child: Stack(
                  children: [
                    InAppWebView(
                      initialUrlRequest: URLRequest(url: WebUri(widget.url)),
                      initialSettings: InAppWebViewSettings(
                        userAgent: ExtensionBridge.userAgent,
                        javaScriptEnabled: true,
                        domStorageEnabled: true,
                        // chrome://inspect in debug builds.
                        isInspectable: kDebugMode,
                      ),
                      onWebViewCreated: (controller) =>
                          _controller = controller,
                      onProgressChanged: (_, progress) =>
                          setState(() => _progress = progress / 100),
                      onTitleChanged: (_, title) =>
                          setState(() => _title = title),
                      onUpdateVisitedHistory: (controller, url, _) async {
                        final canGoBack = await controller.canGoBack();
                        if (!mounted) return;
                        setState(() {
                          if (url != null) _url = url.uriValue;
                          _canGoBack = canGoBack;
                        });
                      },
                      onLoadStart: (_, _) => setState(() => _error = null),
                      onReceivedError: (_, request, error) {
                        if (request.isForMainFrame ?? true) {
                          setState(() => _error = error.description);
                        }
                      },
                      onLoadStop: (_, url) {
                        if (url != null) unawaited(_saveCookies(url.uriValue));
                      },
                    ),
                    if (_error case final error?)
                      ColoredBox(
                        color: c.bg,
                        child: Center(
                          child: EmptyState(
                            icon: LucideIcons300.globe,
                            title: AppText.pageNotLoaded,
                            message: error,
                            actionLabel: AppText.retry,
                            onAction: () => _controller?.reload(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
