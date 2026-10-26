#include "flutter_window.h"

#include <flutter/standard_method_codec.h>

#include <cstring>
#include <optional>
#include <string>

#include "flutter/generated_plugin_registrant.h"

namespace {

// A movable global block holding a copy of |size| bytes at |data|, as the
// clipboard takes them; null when it cannot be allocated.
HGLOBAL GlobalCopy(const void* data, size_t size) {
  HGLOBAL block = GlobalAlloc(GMEM_MOVEABLE, size);
  if (block == nullptr) return nullptr;
  void* target = GlobalLock(block);
  if (target == nullptr) {
    GlobalFree(block);
    return nullptr;
  }
  std::memcpy(target, data, size);
  GlobalUnlock(block);
  return block;
}

// Hands |block| to the clipboard as |format|, or frees it.
bool SetClipboardBlock(UINT format, HGLOBAL block) {
  if (block == nullptr) return false;
  if (SetClipboardData(format, block) != nullptr) return true;
  GlobalFree(block);
  return false;
}

// Puts UTF-8 |text| and |html| (already in the "HTML Format" layout, see
// lib/src/clipboard/rich_clipboard.dart) on the clipboard.
bool SetClipboardHtml(HWND window, const std::string& text,
                      const std::string& html) {
  static const UINT html_format = RegisterClipboardFormatW(L"HTML Format");
  // The length counts the terminating null, which the clipboard wants.
  int wide_length =
      MultiByteToWideChar(CP_UTF8, 0, text.c_str(), -1, nullptr, 0);
  if (wide_length <= 0 || html_format == 0) return false;
  std::wstring wide(wide_length, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, text.c_str(), -1, wide.data(), wide_length);
  if (!OpenClipboard(window)) return false;
  EmptyClipboard();
  bool ok = SetClipboardBlock(
      CF_UNICODETEXT, GlobalCopy(wide.c_str(), wide.size() * sizeof(wchar_t)));
  ok = SetClipboardBlock(html_format,
                         GlobalCopy(html.c_str(), html.size() + 1)) &&
       ok;
  CloseClipboard();
  return ok;
}

// The string argument |key| of |call|, or null.
const std::string* StringArgument(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    const char* key) {
  const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
  if (args == nullptr) return nullptr;
  auto it = args->find(flutter::EncodableValue(key));
  return it == args->end() ? nullptr : std::get_if<std::string>(&it->second);
}

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  clipboard_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "dev.shireitou.shireitou/clipboard",
          &flutter::StandardMethodCodec::GetInstance());
  clipboard_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        if (call.method_name() != "setHtml") {
          result->NotImplemented();
          return;
        }
        const std::string* text = StringArgument(call, "text");
        const std::string* html = StringArgument(call, "html");
        if (text == nullptr || html == nullptr) {
          result->Error("bad_arguments", "no text or html");
        } else if (!SetClipboardHtml(GetHandle(), *text, *html)) {
          result->Error("clipboard_failed", "could not set the clipboard");
        } else {
          result->Success();
        }
      });
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  clipboard_channel_ = nullptr;
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
