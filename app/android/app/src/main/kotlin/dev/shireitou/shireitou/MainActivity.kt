package dev.shireitou.shireitou

import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * The Flutter activity, plus OAuth sign-in for MCP servers (AHP-060): Dart
 * calls `authenticate` on [WEB_AUTH_CHANNEL] with the authorization URL,
 * the browser opens it, and the authorization server's redirect to
 * [APP_SCHEME] comes back to this (single-task) activity in
 * [onNewIntent], whose URL answers the call. Returning to the app without
 * a redirect answers null (cancelled).
 */
class MainActivity : FlutterActivity() {
    private var pending: MethodChannel.Result? = null
    private var browserOpened = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WEB_AUTH_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "authenticate") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val url = call.argument<String>("url")
                if (url == null) {
                    result.error("bad_arguments", "no url", null)
                    return@setMethodCallHandler
                }
                pending?.success(null)
                pending = result
                try {
                    startActivity(
                        Intent(Intent.ACTION_VIEW, Uri.parse(url))
                            .addCategory(Intent.CATEGORY_BROWSABLE),
                    )
                    browserOpened = true
                } catch (e: ActivityNotFoundException) {
                    pending = null
                    result.error("no_browser", e.message, null)
                }
            }
        // Rich copy (lib/src/clipboard/rich_clipboard.dart): `setHtml`
        // puts `html` and `text` on the clipboard as one clip.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CLIPBOARD_CHANNEL)
            .setMethodCallHandler { call, result ->
                val text = call.argument<String>("text")
                val html = call.argument<String>("html")
                if (call.method != "setHtml") {
                    result.notImplemented()
                } else if (text == null || html == null) {
                    result.error("bad_arguments", "no text or html", null)
                } else {
                    getSystemService(ClipboardManager::class.java)
                        .setPrimaryClip(ClipData.newHtmlText(null, text, html))
                    result.success(null)
                }
            }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val data = intent.data
        if (intent.action == Intent.ACTION_VIEW && data?.scheme == APP_SCHEME) {
            browserOpened = false
            pending?.success(data.toString())
            pending = null
        }
    }

    override fun onResume() {
        super.onResume()
        // Back from the browser without a redirect: the user gave up. The
        // redirect, when there is one, arrives in onNewIntent first.
        if (browserOpened && pending != null) {
            window.decorView.post {
                if (browserOpened) {
                    browserOpened = false
                    pending?.success(null)
                    pending = null
                }
            }
        }
    }

    private companion object {
        const val APP_SCHEME = "dev.shireitou.shireitou"
        const val WEB_AUTH_CHANNEL = "dev.shireitou.shireitou/web_auth"
        const val CLIPBOARD_CHANNEL = "dev.shireitou.shireitou/clipboard"
    }
}
