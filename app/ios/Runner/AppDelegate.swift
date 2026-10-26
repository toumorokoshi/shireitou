import AuthenticationServices
import Flutter
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
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "WebAuthPlugin") {
      WebAuthPlugin.register(with: registrar)
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "RichClipboard") {
      RichClipboard.register(messenger: registrar.messenger())
    }
  }
}

/// Rich copy (`lib/src/clipboard/rich_clipboard.dart`): `setHtml` on
/// `dev.shireitou.shireitou/clipboard` puts `html` and `text` on the
/// general pasteboard as one item.
enum RichClipboard {
  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "dev.shireitou.shireitou/clipboard", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "setHtml" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let args = call.arguments as? [String: Any],
        let text = args["text"] as? String, let html = args["html"] as? String
      else {
        result(FlutterError(code: "bad_arguments", message: "no text or html", details: nil))
        return
      }
      UIPasteboard.general.items = [["public.html": html, "public.utf8-plain-text": text]]
      result(nil)
    }
  }
}

/// OAuth sign-in for MCP servers (AHP-060): Dart calls `authenticate` on
/// `dev.shireitou.shireitou/web_auth` with the authorization URL and the
/// app's URL scheme; an `ASWebAuthenticationSession` shows it and answers
/// with the URL the authorization server redirected to, or a `cancelled`
/// error when the user closes the sheet.
class WebAuthPlugin: NSObject, FlutterPlugin, ASWebAuthenticationPresentationContextProviding {
  private var session: ASWebAuthenticationSession?

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "dev.shireitou.shireitou/web_auth", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(WebAuthPlugin(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "authenticate" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard let args = call.arguments as? [String: Any],
      let urlString = args["url"] as? String, let url = URL(string: urlString),
      let scheme = args["scheme"] as? String
    else {
      result(FlutterError(code: "bad_arguments", message: "no url or scheme", details: nil))
      return
    }
    session?.cancel()
    let session = ASWebAuthenticationSession(url: url, callbackURLScheme: scheme) {
      [weak self] callback, error in
      self?.session = nil
      if let callback = callback {
        result(callback.absoluteString)
      } else if let error = error as? ASWebAuthenticationSessionError,
        error.code == .canceledLogin
      {
        result(FlutterError(code: "cancelled", message: "sign-in was cancelled", details: nil))
      } else {
        result(
          FlutterError(
            code: "browser_failed", message: error?.localizedDescription, details: nil))
      }
    }
    session.presentationContextProvider = self
    // Share cookies with Safari, so an existing sign-in is reused.
    session.prefersEphemeralWebBrowserSession = false
    self.session = session
    if !session.start() {
      self.session = nil
      result(FlutterError(code: "browser_failed", message: "could not start sign-in", details: nil))
    }
  }

  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    return scenes.compactMap { $0.keyWindow }.first ?? scenes.first?.windows.first
      ?? ASPresentationAnchor()
  }
}
