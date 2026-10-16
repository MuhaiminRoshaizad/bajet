package my.minned.bajet

import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * A fragment activity because local_auth shows Android's fingerprint prompt
 * as a fragment. Also answers ChannelRecentsPrivacy: while the app lock is
 * on, the app switcher gets no picture of bajet, so it cannot show the
 * balance. Unlike FLAG_SECURE, the owner's own screenshots still work.
 */
class MainActivity : FlutterFragmentActivity() {
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "my.minned.bajet/privacy").setMethodCallHandler { call, result ->
      if (call.method != "hideFromRecents") return@setMethodCallHandler result.notImplemented()
      // setRecentsScreenshotEnabled arrived in Android 13; older phones keep the picture.
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) setRecentsScreenshotEnabled(call.arguments != true)
      result.success(null)
    }
  }
}
