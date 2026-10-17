package my.minned.bajet

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.window.SplashScreenView
import androidx.activity.result.contract.ActivityResultContract
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * A fragment activity because local_auth shows Android's fingerprint prompt
 * as a fragment.
 *
 * It also answers three channels. ChannelRecentsPrivacy: while the app lock
 * is on, the app switcher gets no picture of bajet, so it cannot show the
 * balance; unlike FLAG_SECURE, the owner's own screenshots still work.
 * ChannelSplashHandOver: Android 12 and later play the opening's deal on
 * their splash screen (res/drawable-v31/splash_deal.xml), which stays up
 * until the deal has finished and bajet has drawn the same fan, so the
 * hand-over shows no seam. ChannelFiles: Save on a report or backup opens
 * Android's own "Save to" screen and writes the file where the owner picks,
 * which needs no storage permission on any version bajet supports.
 */
class MainActivity : FlutterFragmentActivity() {
  private val main = Handler(Looper.getMainLooper())
  private var splash: SplashScreenView? = null
  private var dealEndsAt = 0L
  private var waiting: MethodChannel.Result? = null
  private var saving: Pending? = null

  private class Pending(val bytes: ByteArray, val result: MethodChannel.Result)

  /** The "Save to" screen, given the file name and its type. */
  private val createDocument = registerForActivityResult(object : ActivityResultContract<Pair<String, String>, Uri?>() {
    override fun createIntent(context: Context, input: Pair<String, String>) =
      Intent(Intent.ACTION_CREATE_DOCUMENT).addCategory(Intent.CATEGORY_OPENABLE).setType(input.second).putExtra(Intent.EXTRA_TITLE, input.first)

    override fun parseResult(resultCode: Int, intent: Intent?): Uri? = if (resultCode == RESULT_OK) intent?.data else null
  }) { uri -> write(uri) }

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return
    splashScreen.setOnExitAnimationListener { view ->
      val start = view.iconAnimationStart
      val length = view.iconAnimationDuration
      val left = if (start == null || length == null) 0L else start.plus(length).toEpochMilli() - System.currentTimeMillis()
      dealEndsAt = SystemClock.uptimeMillis() + maxOf(0L, left)
      splash = view
      answer()
      // Never leave the splash up for ever if bajet does not ask.
      main.postDelayed({ removeSplash() }, maxOf(0L, left) + 4000)
    }
  }

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    val messenger = flutterEngine.dartExecutor.binaryMessenger
    MethodChannel(messenger, "my.minned.bajet/privacy").setMethodCallHandler { call, result ->
      if (call.method != "hideFromRecents") return@setMethodCallHandler result.notImplemented()
      // setRecentsScreenshotEnabled arrived in Android 13; older phones keep the picture.
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) setRecentsScreenshotEnabled(call.arguments != true)
      result.success(null)
    }
    MethodChannel(messenger, "my.minned.bajet/files").setMethodCallHandler { call, result ->
      if (call.method != "save") return@setMethodCallHandler result.notImplemented()
      if (saving != null) return@setMethodCallHandler result.error("busy", "Already saving a file", null)
      saving = Pending(call.argument<ByteArray>("bytes")!!, result)
      try {
        createDocument.launch(Pair(call.argument<String>("name")!!, call.argument<String>("mime")!!))
      } catch (e: Exception) {
        saving = null
        result.error("unavailable", e.message, null)
      }
    }
    MethodChannel(messenger, "my.minned.bajet/launch").setMethodCallHandler { call, result ->
      when (call.method) {
        "splashReady" -> {
          // No animated splash before Android 12: bajet plays the deal itself.
          if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return@setMethodCallHandler result.success(false)
          waiting = result
          answer()
        }
        "removeSplash" -> {
          removeSplash()
          result.success(null)
        }
        else -> result.notImplemented()
      }
    }
  }

  /** Writes the pending file to [uri], off the main thread; null means the owner cancelled. */
  private fun write(uri: Uri?) {
    val pending = saving ?: return
    saving = null
    if (uri == null) return pending.result.success(false)
    Thread {
      try {
        val out = contentResolver.openOutputStream(uri) ?: throw java.io.IOException("No stream for $uri")
        out.use { it.write(pending.bytes) }
        main.post { pending.result.success(true) }
      } catch (e: Exception) {
        main.post { pending.result.error("write", e.message, null) }
      }
    }.start()
  }

  /** Once the splash is known and bajet has asked, answers when the deal ends. */
  private fun answer() {
    val result = waiting ?: return
    if (splash == null) return
    waiting = null
    main.postAtTime({ result.success(true) }, dealEndsAt)
  }

  private fun removeSplash() {
    splash?.remove()
    splash = null
  }
}
