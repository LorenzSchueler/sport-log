package org.sport_log.sport_log_client

import android.annotation.SuppressLint
import android.content.Context
import android.os.PowerManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var proximityWakeLock: PowerManager.WakeLock? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "org.sport_log/proximity_wake_lock")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "acquire" -> result.success(acquireProximityWakeLock())
                    "release" -> {
                        releaseProximityWakeLock()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        releaseProximityWakeLock()
        super.onDestroy()
    }

    /** Turns the screen off while the proximity sensor is covered. */
    @SuppressLint("WakelockTimeout")
    private fun acquireProximityWakeLock(): Boolean {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        if (!powerManager.isWakeLockLevelSupported(PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK)) {
            return false
        }
        val wakeLock = proximityWakeLock
            ?: powerManager.newWakeLock(PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK, "sport_log:proximity")
                .also { it.setReferenceCounted(false) }
        proximityWakeLock = wakeLock
        wakeLock.acquire()
        return true
    }

    private fun releaseProximityWakeLock() {
        proximityWakeLock?.takeIf { it.isHeld }?.release()
    }
}
