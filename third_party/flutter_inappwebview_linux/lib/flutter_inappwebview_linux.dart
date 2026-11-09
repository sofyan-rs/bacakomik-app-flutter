/// flutter_inappwebview on WebKitGTK: the parts of its platform interface the
/// app uses (headless pages, an in-app page, cookies). See
/// `linux/inappwebview_linux_plugin.cc`.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview_platform_interface/flutter_inappwebview_platform_interface.dart';

const _rawChannel = MethodChannel('bacakomik/inappwebview_linux');

/// The plugin's channel, listening for its events from the first use on:
/// the binding does not exist yet when the plugin registers.
MethodChannel get _channel {
  if (!_listening) {
    _listening = true;
    _rawChannel.setMethodCallHandler((call) async {
      final args = (call.arguments as Map).cast<String, Object?>();
      return _views[args['id']]?._handle(call.method, args);
    });
    // A hot restart leaves the views of the last run behind.
    unawaited(
      _rawChannel.invokeMethod<void>('disposeAll').catchError((Object _) {}),
    );
  }
  return _rawChannel;
}

/// Views by id, for the events the plugin sends.
final _views = <int, LinuxInAppWebViewController>{};
var _nextId = 0;
var _listening = false;

class LinuxInAppWebViewPlatform extends InAppWebViewPlatform {
  static void registerWith() {
    InAppWebViewPlatform.instance = LinuxInAppWebViewPlatform();
  }

  @override
  LinuxCookieManager createPlatformCookieManager(
    PlatformCookieManagerCreationParams params,
  ) => LinuxCookieManager(params);

  @override
  LinuxCookieManager createPlatformCookieManagerStatic() =>
      LinuxCookieManager(const PlatformCookieManagerCreationParams());

  @override
  LinuxInAppWebViewController createPlatformInAppWebViewController(
    PlatformInAppWebViewControllerCreationParams params,
  ) => LinuxInAppWebViewController(params);

  @override
  LinuxInAppWebViewController createPlatformInAppWebViewControllerStatic() =>
      LinuxInAppWebViewController(
        const PlatformInAppWebViewControllerCreationParams(id: -1),
      );

  @override
  LinuxInAppWebViewWidget createPlatformInAppWebViewWidget(
    PlatformInAppWebViewWidgetCreationParams params,
  ) => LinuxInAppWebViewWidget(params);

  @override
  LinuxInAppWebViewWidget createPlatformInAppWebViewWidgetStatic() =>
      LinuxInAppWebViewWidget(PlatformInAppWebViewWidgetCreationParams());

  @override
  LinuxHeadlessInAppWebView createPlatformHeadlessInAppWebView(
    PlatformHeadlessInAppWebViewCreationParams params,
  ) => LinuxHeadlessInAppWebView(params);

  @override
  LinuxHeadlessInAppWebView createPlatformHeadlessInAppWebViewStatic() =>
      LinuxHeadlessInAppWebView(PlatformHeadlessInAppWebViewCreationParams());
}

/// The creation arguments the plugin takes from [params].
Map<String, Object?> _createArgs(
  int id,
  PlatformWebViewCreationParams params, {
  required URLRequest? request,
  required InAppWebViewSettings? settings,
  required bool headless,
  Size? size,
}) => {
  'id': id,
  'url': request?.url?.toString(),
  'userAgent': settings?.userAgent,
  'devTools': settings?.isInspectable ?? false,
  'headless': headless,
  'intercept':
      params.shouldOverrideUrlLoading != null &&
      (settings?.useShouldOverrideUrlLoading ?? true),
  // A page that handles new windows itself gets none; others open them in
  // place, as a browser tab would.
  'newWindowsInPlace': params.onCreateWindow == null,
  'width': ?size?.width,
  'height': ?size?.height,
};

class LinuxInAppWebViewController extends PlatformInAppWebViewController {
  LinuxInAppWebViewController(super.params) : super.implementation();

  int get _id => params.id as int;
  PlatformWebViewCreationParams? get _params => params.webviewParams;

  /// What the app's callbacks get: its InAppWebViewController.
  late final dynamic _facing =
      _params?.controllerFromPlatform?.call(this) ?? this;

  void _attach() => _views[_id] = this;

  Future<T?> _call<T>(String method, [Map<String, Object?>? args]) =>
      _channel.invokeMethod<T>(method, {'id': _id, ...?args});

  Future<Object?> _handle(String method, Map<String, Object?> args) async {
    final p = _params;
    if (p == null) return null;
    final url = switch (args['url']) {
      final String u when u.isNotEmpty => WebUri(u),
      _ => null,
    };
    switch (method) {
      case 'onLoadStart':
        p.onLoadStart?.call(_facing, url);
      case 'onLoadStop':
        p.onLoadStop?.call(_facing, url);
      case 'onReceivedError':
        p.onReceivedError?.call(
          _facing,
          WebResourceRequest(url: url ?? WebUri(''), isForMainFrame: true),
          WebResourceError(
            description: args['description'] as String? ?? '',
            type: WebResourceErrorType.UNKNOWN,
          ),
        );
      case 'onProgressChanged':
        p.onProgressChanged?.call(_facing, args['progress'] as int);
      case 'onTitleChanged':
        p.onTitleChanged?.call(_facing, args['title'] as String?);
      case 'onUpdateVisitedHistory':
        p.onUpdateVisitedHistory?.call(_facing, url, false);
      case 'shouldOverrideUrlLoading':
        final decide = p.shouldOverrideUrlLoading;
        if (decide == null || url == null) return true;
        final policy = await decide(
          _facing,
          NavigationAction(
            request: URLRequest(url: url),
            isForMainFrame: true,
          ),
        );
        return policy != NavigationActionPolicy.CANCEL;
    }
    return null;
  }

  @override
  Future<void> loadUrl({
    required URLRequest urlRequest,
    @Deprecated('Use allowingReadAccessTo instead')
    Uri? iosAllowingReadAccessTo,
    WebUri? allowingReadAccessTo,
  }) => _call('loadUrl', {'url': urlRequest.url?.toString()});

  @override
  Future<void> reload() => _call('reload');

  @override
  Future<void> stopLoading() => _call('stopLoading');

  @override
  Future<void> goBack() => _call('goBack');

  @override
  Future<bool> canGoBack() async => await _call<bool>('canGoBack') ?? false;

  @override
  Future<String?> getTitle() => _call<String>('getTitle');

  @override
  Future<WebUri?> getUrl() async {
    final url = await _call<String>('getUrl');
    return url == null ? null : WebUri(url);
  }

  @override
  Future<CallAsyncJavaScriptResult?> callAsyncJavaScript({
    required String functionBody,
    Map<String, dynamic> arguments = const <String, dynamic>{},
    ContentWorld? contentWorld,
  }) async {
    // Arguments become the function's parameters, as on other platforms.
    final body = arguments.isEmpty
        ? functionBody
        : 'return await (async (${arguments.keys.join(', ')}) => {\n'
              '$functionBody\n'
              '})(...${jsonEncode(arguments.values.toList())});';
    final result = await _call<Map<Object?, Object?>>('callAsyncJavaScript', {
      'functionBody': body,
    });
    final value = result?['value'] as String?;
    return CallAsyncJavaScriptResult(
      value: value == null ? null : jsonDecode(value),
      error: result?['error'] as String?,
    );
  }

  @override
  void dispose({bool isKeepAlive = false}) => _views.remove(_id);
}

class LinuxHeadlessInAppWebView extends PlatformHeadlessInAppWebView {
  LinuxHeadlessInAppWebView(super.params) : super.implementation();

  @override
  late final String id = '${_nextId++}';
  late final int _id = int.parse(id);

  LinuxInAppWebViewController? _controller;
  var _running = false;

  @override
  LinuxInAppWebViewController? get webViewController => _controller;

  @override
  Future<void> run() async {
    if (_controller != null) return;
    final controller = _controller = LinuxInAppWebViewController(
      PlatformInAppWebViewControllerCreationParams(
        id: _id,
        webviewParams: params,
      ),
    ).._attach();
    try {
      await _channel.invokeMethod<void>(
        'create',
        _createArgs(
          _id,
          params,
          request: params.initialUrlRequest,
          settings: params.initialSettings,
          headless: true,
          size: params.initialSize,
        ),
      );
    } catch (_) {
      controller.dispose();
      _controller = null;
      rethrow;
    }
    _running = true;
    params.onWebViewCreated?.call(controller._facing);
  }

  @override
  bool isRunning() => _running;

  @override
  Future<void> setSize(Size size) async {
    if (!_running) return;
    await _channel.invokeMethod<void>('setRect', {
      'id': _id,
      'width': size.width,
      'height': size.height,
    });
  }

  @override
  Future<void> dispose() async {
    final controller = _controller;
    if (controller == null) return;
    _controller = null;
    _running = false;
    controller.dispose();
    await _channel
        .invokeMethod<void>('dispose', {'id': _id})
        .catchError((Object _) {});
  }
}

class LinuxInAppWebViewWidget extends PlatformInAppWebViewWidget {
  LinuxInAppWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) =>
      _OverlayWebView(key: params.key, params: params);

  @override
  T controllerFromPlatform<T>(PlatformInAppWebViewController controller) =>
      (params.controllerFromPlatform?.call(controller) ?? controller) as T;

  @override
  void dispose() {}
}

/// Where the web view goes: the plugin lays the native view over this
/// widget's rect while it is on screen and nothing should cover it.
class _OverlayWebView extends StatefulWidget {
  const _OverlayWebView({super.key, required this.params});

  final PlatformInAppWebViewWidgetCreationParams params;

  @override
  State<_OverlayWebView> createState() => _OverlayWebViewState();
}

class _OverlayWebViewState extends State<_OverlayWebView> {
  final int _id = _nextId++;
  late final LinuxInAppWebViewController _controller;
  var _created = false;
  var _disposed = false;

  /// The rect last sent, null while hidden.
  Rect? _sent;
  var _tracking = false;

  @override
  void initState() {
    super.initState();
    final params = widget.params;
    _controller = LinuxInAppWebViewController(
      PlatformInAppWebViewControllerCreationParams(
        id: _id,
        webviewParams: params,
      ),
    ).._attach();
    unawaited(_create(params));
  }

  Future<void> _create(PlatformInAppWebViewWidgetCreationParams params) async {
    try {
      await _channel.invokeMethod<void>(
        'create',
        _createArgs(
          _id,
          params,
          request: params.initialUrlRequest,
          settings: params.initialSettings,
          headless: false,
        ),
      );
    } on PlatformException catch (e) {
      params.onReceivedError?.call(
        _controller._facing,
        WebResourceRequest(
          url: params.initialUrlRequest?.url ?? WebUri(''),
          isForMainFrame: true,
        ),
        WebResourceError(
          description: e.message ?? e.code,
          type: WebResourceErrorType.UNKNOWN,
        ),
      );
      return;
    }
    if (_disposed) {
      await _channel.invokeMethod<void>('dispose', {'id': _id});
      return;
    }
    _created = true;
    params.onWebViewCreated?.call(_controller._facing);
    _track();
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  /// Follows the widget after every frame: routes and scrolling move it
  /// without rebuilding it. Asks for no frames of its own.
  void _track() {
    if (_tracking || _disposed) return;
    _tracking = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _tracking = false;
      if (_disposed) return;
      _sync();
      _track();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // TickerMode turns off under Visibility(maintainState) and Offstage.
    if (_created) _track();
  }

  void _sync() {
    final rect = _visibleRect();
    if (rect == _sent) return;
    _sent = rect;
    unawaited(
      _channel
          .invokeMethod<void>('setRect', {
            'id': _id,
            'visible': rect != null,
            'x': rect?.left ?? 0,
            'y': rect?.top ?? 0,
            'width': rect?.width ?? 0,
            'height': rect?.height ?? 0,
          })
          .catchError((Object _) {}),
    );
  }

  Rect? _visibleRect() {
    if (!mounted || !TickerMode.valuesOf(context).enabled) return null;
    final route = ModalRoute.of(context);
    if (route != null &&
        (!route.isCurrent ||
            route.animation?.status != AnimationStatus.completed ||
            (route.secondaryAnimation?.status ?? AnimationStatus.dismissed) !=
                AnimationStatus.dismissed)) {
      return null;
    }
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    // Whole logical pixels, as GTK places widgets.
    return Rect.fromLTRB(
      rect.left.roundToDouble(),
      rect.top.roundToDouble(),
      rect.right.roundToDouble(),
      rect.bottom.roundToDouble(),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _controller.dispose();
    if (_created) {
      unawaited(
        _channel
            .invokeMethod<void>('dispose', {'id': _id})
            .catchError((Object _) {}),
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

class LinuxCookieManager extends PlatformCookieManager {
  LinuxCookieManager(super.params) : super.implementation();

  @override
  Future<List<Cookie>> getCookies({
    required WebUri url,
    @Deprecated('Use webViewController instead')
    PlatformInAppWebViewController? iosBelow11WebViewController,
    PlatformInAppWebViewController? webViewController,
  }) async {
    final list = await _channel.invokeListMethod<Map<Object?, Object?>>(
      'getCookies',
      {'url': url.toString()},
    );
    return [
      for (final c in list ?? const <Map<Object?, Object?>>[])
        Cookie(
          name: c['name'] as String? ?? '',
          value: c['value'],
          domain: c['domain'] as String?,
          path: c['path'] as String?,
          expiresDate: c['expiresDate'] as int?,
          isSessionOnly: c['isSessionOnly'] as bool?,
          isSecure: c['isSecure'] as bool?,
          isHttpOnly: c['isHttpOnly'] as bool?,
        ),
    ];
  }

  @override
  Future<Cookie?> getCookie({
    required WebUri url,
    required String name,
    @Deprecated('Use webViewController instead')
    PlatformInAppWebViewController? iosBelow11WebViewController,
    PlatformInAppWebViewController? webViewController,
  }) async {
    for (final c in await getCookies(url: url)) {
      if (c.name == name) return c;
    }
    return null;
  }

  @override
  Future<bool> deleteCookie({
    required WebUri url,
    required String name,
    String path = '/',
    String? domain,
    @Deprecated('Use webViewController instead')
    PlatformInAppWebViewController? iosBelow11WebViewController,
    PlatformInAppWebViewController? webViewController,
  }) async =>
      await _channel.invokeMethod<bool>('deleteCookies', {
        'url': url.toString(),
        'name': name,
        'domain': domain,
      }) ??
      false;

  @override
  Future<bool> deleteCookies({
    required WebUri url,
    String path = '/',
    String? domain,
    @Deprecated('Use webViewController instead')
    PlatformInAppWebViewController? iosBelow11WebViewController,
    PlatformInAppWebViewController? webViewController,
  }) async =>
      await _channel.invokeMethod<bool>('deleteCookies', {
        'url': url.toString(),
        'domain': domain,
      }) ??
      false;

  @override
  Future<bool> deleteAllCookies() async =>
      await _channel.invokeMethod<bool>('deleteAllCookies') ?? false;
}
