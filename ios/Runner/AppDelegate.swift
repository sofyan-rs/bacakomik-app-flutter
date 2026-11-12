import Flutter
import Network
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "YoruSessionProxy") {
      SessionProxy.register(messenger: registrar.messenger())
    }
  }
}

/// DNS over HTTPS for NSURLSession (extensions' requests through
/// cupertino_http): while the app's local DoH proxy runs, new session
/// configurations send their connections through it (iOS 17+). TLS still
/// runs between the session and the site.
enum SessionProxy {
  private static var port: UInt16?
  private static var installed = false

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "yoru/session_proxy", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "setPort" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard #available(iOS 17.0, *) else {
        result(false)
        return
      }
      port = (call.arguments as? NSNumber).map { UInt16(truncating: $0) }
      install()
      result(true)
    }
  }

  @available(iOS 17.0, *)
  static func apply(to config: URLSessionConfiguration) {
    guard let port, let endpointPort = NWEndpoint.Port(rawValue: port) else { return }
    var proxy = ProxyConfiguration(
      httpCONNECTProxy: .hostPort(host: "127.0.0.1", port: endpointPort))
    proxy.excludedDomains = ["localhost", "127.0.0.1"]
    config.proxyConfigurations = [proxy]
  }

  /// Wraps `+defaultSessionConfiguration` and `+ephemeralSessionConfiguration`
  /// once; a configuration made while [port] is nil stays direct.
  private static func install() {
    guard !installed else { return }
    installed = true
    let cls: AnyClass = URLSessionConfiguration.self
    for (original, replacement) in [
      ("defaultSessionConfiguration", #selector(URLSessionConfiguration.yoru_default)),
      ("ephemeralSessionConfiguration", #selector(URLSessionConfiguration.yoru_ephemeral)),
    ] {
      guard let a = class_getClassMethod(cls, NSSelectorFromString(original)),
        let b = class_getClassMethod(cls, replacement)
      else { continue }
      method_exchangeImplementations(a, b)
    }
  }
}

extension URLSessionConfiguration {
  // After the exchange these names call the original implementations.
  @objc class func yoru_default() -> URLSessionConfiguration {
    let config = yoru_default()
    if #available(iOS 17.0, *) { SessionProxy.apply(to: config) }
    return config
  }

  @objc class func yoru_ephemeral() -> URLSessionConfiguration {
    let config = yoru_ephemeral()
    if #available(iOS 17.0, *) { SessionProxy.apply(to: config) }
    return config
  }
}
