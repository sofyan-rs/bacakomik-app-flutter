import 'dart:async';
import 'dart:io' as io;

import 'package:bacakomik_app/core/error/exceptions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Hidden WebViews that run extension scripts inside a site, for sites that
/// only answer a real browser (strict Cloudflare rules, tokens their own
/// JavaScript makes). One page per extension, kept a few minutes between
/// runs so the site does not load again each time.
class HeadlessPages {
  HeadlessPages({required this.userAgent, required this.onCookies});

  final String userAgent;

  /// Called after each run with the cookies the page holds for its site.
  final Future<void> Function(
    String extensionId,
    Uri url,
    List<io.Cookie> cookies,
  )
  onCookies;

  final _pages = <String, _Page>{};

  static const _keepAlive = Duration(minutes: 3);
  static const _loadTimeout = Duration(seconds: 25);
  static const _challengeTimeout = Duration(seconds: 20);

  /// Opens [url] (unless the page already shows it), then runs
  /// [script] as the body of an async function in it and returns its
  /// result. Runs of one extension go one at a time.
  Future<Object?> run(String extensionId, String url, String script) {
    final page = _pages.putIfAbsent(extensionId, _Page.new);
    final result = page.queue = page.queue.then(
      (_) => _run(extensionId, page, Uri.parse(url), script),
      onError: (_) => _run(extensionId, page, Uri.parse(url), script),
    );
    return result;
  }

  Future<Object?> _run(
    String extensionId,
    _Page page,
    Uri url,
    String script,
  ) async {
    page.idle?.cancel();
    try {
      final controller = await _open(page, url);
      await _passChallenge(controller, url);
      final result = await controller.callAsyncJavaScript(functionBody: script);
      if (result?.error case final error?) throw ServerException(error);
      await _saveCookies(extensionId, url);
      return result?.value;
    } finally {
      page.idle = Timer(_keepAlive, () => _close(extensionId));
    }
  }

  /// The page's controller, loading [url] first when it shows another site.
  Future<InAppWebViewController> _open(_Page page, Uri url) async {
    final controller = page.controller;
    // Navigating (not fetching) is what lets Cloudflare's check solve itself.
    if (controller != null && page.url == url.toString()) return controller;

    final loaded = page.loaded = Completer<void>();
    if (controller != null) {
      await controller.loadUrl(urlRequest: URLRequest(url: WebUri.uri(url)));
    } else {
      final view = page.view = HeadlessInAppWebView(
        initialUrlRequest: URLRequest(url: WebUri.uri(url)),
        initialSettings: InAppWebViewSettings(
          userAgent: userAgent,
          javaScriptEnabled: true,
          domStorageEnabled: true,
          isInspectable: kDebugMode,
        ),
        onWebViewCreated: (c) => page.controller = c,
        onLoadStop: (_, _) {
          if (!(page.loaded?.isCompleted ?? true)) page.loaded!.complete();
        },
        onReceivedError: (_, request, error) {
          if ((request.isForMainFrame ?? true) &&
              !(page.loaded?.isCompleted ?? true)) {
            page.loaded!.completeError(ServerException(error.description));
          }
        },
      );
      await view.run();
    }
    await loaded.future.timeout(
      _loadTimeout,
      onTimeout: () => throw ServerException('${url.host} did not load'),
    );
    page.url = url.toString();
    return page.controller!;
  }

  /// Waits while Cloudflare's "Just a moment" page solves itself; a check
  /// that needs the user becomes a [Challenge] for the visible WebView.
  Future<void> _passChallenge(InAppWebViewController c, Uri url) async {
    final deadline = DateTime.now().add(_challengeTimeout);
    while ((await c.getTitle() ?? '').contains('Just a moment')) {
      if (DateTime.now().isAfter(deadline)) {
        throw ServerException(Challenge.message(url.toString()));
      }
      await Future<void>.delayed(const Duration(seconds: 1));
    }
  }

  Future<void> _saveCookies(String extensionId, Uri url) async {
    final cookies = await CookieManager.instance().getCookies(
      url: WebUri.uri(url),
    );
    await onCookies(extensionId, url, [
      for (final c in cookies) ?_cookie(c.name, '${c.value}'),
    ]);
  }

  static io.Cookie? _cookie(String name, String value) {
    try {
      return io.Cookie(name, value)..path = '/';
    } on FormatException {
      return null;
    }
  }

  void _close(String extensionId) {
    final page = _pages.remove(extensionId);
    page?.idle?.cancel();
    page?.view?.dispose();
  }

  /// Closes an extension's page, e.g. on uninstall.
  void close(String extensionId) => _close(extensionId);
}

class _Page {
  HeadlessInAppWebView? view;
  InAppWebViewController? controller;
  String? url;
  Completer<void>? loaded;
  Timer? idle;
  Future<Object?> queue = Future.value();
}
