import Cocoa
import FlutterMacOS
import window_manager

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    RichClipboard.register(messenger: flutterViewController.engine.binaryMessenger)

    // The app draws its own title bar (AV-091, lib/src/title_bar/): the
    // native one is transparent and the content runs under it. An empty
    // compact toolbar makes the title bar as tall as the app's (38 pt), so
    // the traffic lights sit centred in it.
    self.titlebarAppearsTransparent = true
    self.titleVisibility = .hidden
    self.styleMask.insert(.fullSizeContentView)
    self.toolbar = NSToolbar(identifier: "shireitou.titlebar")
    self.toolbarStyle = .unifiedCompact

    super.awakeFromNib()
  }

  // Keep the window hidden until Dart has restored its size and position
  // (window_manager's waitUntilReadyToShow).
  override public func order(_ place: NSWindow.OrderingMode, relativeTo otherWin: Int) {
    super.order(place, relativeTo: otherWin)
    hiddenWindowAtLaunch()
  }
}

/// Rich copy (`lib/src/clipboard/rich_clipboard.dart`): `setHtml` on
/// `dev.shireitou.shireitou/clipboard` puts `html` and `text` on the
/// general pasteboard.
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
      let pasteboard = NSPasteboard.general
      pasteboard.clearContents()
      pasteboard.setString(html, forType: .html)
      pasteboard.setString(text, forType: .string)
      result(nil)
    }
  }
}
