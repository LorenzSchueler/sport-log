package org.sport_log.sport_log_client

import android.annotation.SuppressLint
import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.PowerManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var proximityWakeLock: PowerManager.WakeLock? = null
    private var stepDetectorListener: SensorEventListener? = null

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
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "org.sport_log/step_detection")
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    if (!registerStepDetectorListener(events)) {
                        events.error("unavailable", "Step detector not available", null)
                    }
                }

                override fun onCancel(arguments: Any?) = unregisterStepDetectorListener()
            })
    }

    override fun onDestroy() {
        releaseProximityWakeLock()
        unregisterStepDetectorListener()
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

    /** Sends an event for every step the step detector sensor detects. */
    private fun registerStepDetectorListener(events: EventChannel.EventSink): Boolean {
        val sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        val sensor = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_DETECTOR) ?: return false
        val listener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent) = events.success(null)
            override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) {}
        }
        stepDetectorListener = listener
        sensorManager.registerListener(listener, sensor, SensorManager.SENSOR_DELAY_FASTEST)
        return true
    }

    private fun unregisterStepDetectorListener() {
        val sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        stepDetectorListener?.let(sensorManager::unregisterListener)
        stepDetectorListener = null
    }
}
