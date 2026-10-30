import 'dart:async';
import 'dart:io' as io;

import 'package:bacakomik_app/core/error/exceptions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Whether this platform has a WebView. Linux does not: its implementation
/// needs WPE WebKit, which most distributions do not ship (see
/// `third_party/flutter_inappwebview_linux_stub`).
final bool webViewAvailable = kIsWeb || !io.Platform.isLinux;

/// Hidden WebViews that run extension scripts inside a site, for sites that
/// only answer a real browser (strict Cloudflare rules, tokens their own
/// JavaScript makes). One page per extension, kept [keepAlive] after its
/// last run so the site does not load again each time.
///
/// Flutter runs Dart on Android's main thread and a rendered WebView draws
/// on it too, so pages are small ([viewport]), paused and hidden between
/// runs, and render only while a run needs it ([renders]).
class HeadlessPages {
  HeadlessPages({
    required this.userAgent,
    this.onCookies,
    this.renders = true,
    this.keepAlive = const Duration(seconds: 60),
  });

  final String userAgent;

  /// Called after each run with the cookies the page holds for its site.
  /// Without it the cookies are not read: that is a blocking CookieManager
  /// call on the main thread.
  final Future<void> Function(
    String extensionId,
    Uri url,
    List<io.Cookie> cookies,
  )?
  onCookies;

  /// Whether the page renders while a script runs in it (see MainActivity):
  /// lazy-loading pages only load what an IntersectionObserver or a scroll
  /// reveals. Pages that only `fetch` leave it off. Every page renders while
  /// it shows a Cloudflare check.
  final bool renders;

  /// How long a page stays loaded after its last run. An idle page is
  /// paused and hidden, but its site's timers (ads) still run, so this is
  /// short: long enough for the calls of one screen (a comic, then its
  /// chapter list), not for a whole reading session.
  final Duration keepAlive;

  /// Page size in logical pixels: a common phone viewport, so sites lay out
  /// for mobile and lazy loaders see a real viewport, but less to render
  /// than the full screen the plugin defaults to.
  static const viewport = Size(360, 640);

  final _pages = <String, _Page>{};

  static const _loadTimeout = Duration(seconds: 25);
  static const _challengeTimeout = Duration(seconds: 20);

  /// Long enough for a script that walks a long chapter in the site's reader.
  static const _scriptTimeout = Duration(minutes: 3);

  /// Opens [url] (unless the page already shows it), then runs
  /// [script] as the body of an async function in it and returns its
  /// result. Runs of one extension go one at a time.
  Future<Object?> run(String extensionId, String url, String script) {
    if (!webViewAvailable) {
      return Future.error(
        ServerException('This source needs a WebView, which Linux lacks'),
      );
    }
    Future<Object?> next(_) => _run(extensionId, Uri.parse(url), script);
    final previous = _queues[extensionId] ?? Future<Object?>.value();
    return _queues[extensionId] = previous.then(next, onError: next);
  }

  /// The last run of each extension; the next one waits for it.
  final _queues = <String, Future<Object?>>{};

  Future<Object?> _run(String extensionId, Uri url, String script) async {
    // Looked up now: a failed run or the idle timer may have closed the
    // page this run was queued behind.
    final page = _pages.putIfAbsent(extensionId, _Page.new);
    page.idle?.cancel();
    try {
      final controller = await _open(page, url);
      await _wake(page);
      await _passChallenge(page, url);
      final result = await controller
          .callAsyncJavaScript(functionBody: script)
          .timeout(
            _scriptTimeout,
            onTimeout: () =>
                throw ServerException('${url.host} did not finish in time'),
          );
      if (result?.error case final error?) throw ServerException(error);
      await _saveCookies(extensionId, url);
      return result?.value;
    } catch (_) {
      // A page left on a check or a failed load would be reused as it is,
      // even after the user passed the check in the visible WebView; the
      // next run starts from a fresh page with the cookies it got there.
      _close(extensionId);
      rethrow;
    } finally {
      if (identical(_pages[extensionId], page)) {
        // Awaited: the next run of this extension starts after it.
        await _sleep(page);
        page.idle = Timer(keepAlive, () => _close(extensionId));
      }
    }
  }

  /// The page's controller, loading [url] first when it shows another site.
  Future<InAppWebViewController> _open(_Page page, Uri url) async {
    final controller = page.controller;
    // Navigating (not fetching) is what lets Cloudflare's check solve itself.
    if (controller != null &&
        page.url == url.toString() &&
        !await _onCheck(controller)) {
      return controller;
    }

    final loaded = page.loaded = Completer<void>();
    page.host = url.host;
    if (controller != null) {
      await controller.loadUrl(urlRequest: URLRequest(url: WebUri.uri(url)));
    } else {
      final view = page.view = HeadlessInAppWebView(
        initialSize: viewport,
        initialUrlRequest: URLRequest(url: WebUri.uri(url)),
        initialSettings: InAppWebViewSettings(
          userAgent: userAgent,
          javaScriptEnabled: true,
          domStorageEnabled: true,
          isInspectable: kDebugMode,
          // Ads open windows and redirect the page; neither may take the
          // page away from the site a script runs in.
          supportMultipleWindows: true,
          javaScriptCanOpenWindowsAutomatically: false,
          useShouldOverrideUrlLoading: true,
        ),
        onWebViewCreated: (c) => page.controller = c,
        onCreateWindow: (_, _) async => false,
        shouldOverrideUrlLoading: (_, action) async {
          final to = action.request.url?.host ?? '';
          final allowed =
              !(action.isForMainFrame) || _sameSite(to, page.host ?? '');
          return allowed
              ? NavigationActionPolicy.ALLOW
              : NavigationActionPolicy.CANCEL;
        },
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

  static Future<bool> _onCheck(InAppWebViewController c) async =>
      (await c.getTitle() ?? '').contains('Just a moment');

  /// Waits while Cloudflare's "Just a moment" page solves itself, rendered
  /// so its checks run as they would on screen; a check that needs the user
  /// becomes a [Challenge] for the visible WebView.
  Future<void> _passChallenge(_Page page, Uri url) async {
    final c = page.controller!;
    if (!await _onCheck(c)) return;
    await _show(page, true);
    final deadline = DateTime.now().add(_challengeTimeout);
    while (await _onCheck(c)) {
      if (DateTime.now().isAfter(deadline)) {
        throw ServerException(Challenge.message(url.toString()));
      }
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    if (!renders) await _show(page, false);
  }

  /// Resumes a page paused by [_sleep]; renders it when [renders].
  Future<void> _wake(_Page page) async {
    if (page.paused) {
      page.paused = false;
      await _platform(() => page.controller?.resume());
    }
    if (renders) await _show(page, true);
  }

  /// Between runs: no rendering and no animations (`WebView.onPause`). Not
  /// `pauseTimers`, which would pause every WebView in the app.
  Future<void> _sleep(_Page page) async {
    await _show(page, false);
    if (page.paused || page.controller == null) return;
    page.paused = true;
    await _platform(() => page.controller?.pause());
  }

  Future<void> _saveCookies(String extensionId, Uri url) async {
    final onCookies = this.onCookies;
    if (onCookies == null) return;
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

  /// [a] and [b] are one host, or one is a subdomain of the other; a
  /// Cloudflare check may also load its own page.
  static bool _sameSite(String a, String b) =>
      a.isEmpty ||
      a == b ||
      a.endsWith('.$b') ||
      b.endsWith('.$a') ||
      a == 'challenges.cloudflare.com';

  static const _hiddenWebViews = MethodChannel('bacakomik/hidden_webviews');

  /// Lets [page] render at alpha 0, or hides it again (see MainActivity).
  static Future<void> _show(_Page page, bool render) async {
    final view = page.view;
    if (view == null || page.rendering == render || !io.Platform.isAndroid) {
      return;
    }
    page.rendering = render;
    await _platform(
      () => _hiddenWebViews.invokeMethod<bool>(render ? 'render' : 'hide', {
        'id': view.id,
      }),
    );
  }

  /// Runs a platform call that is missing in tests and on some platforms.
  static Future<void> _platform(Future<void>? Function() call) async {
    try {
      await call();
    } on MissingPluginException {
      // Tests and other platforms.
    } on UnimplementedError {
      // No pause/resume on this platform.
    } on PlatformException catch (e) {
      debugPrint('Hidden WebView: $e');
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

  /// The site the page is meant to show.
  String? host;
  Completer<void>? loaded;
  Timer? idle;

  /// Shown at alpha 0 so Chromium renders it.
  var rendering = false;

  /// Paused with `WebView.onPause` after its last run.
  var paused = false;
}
