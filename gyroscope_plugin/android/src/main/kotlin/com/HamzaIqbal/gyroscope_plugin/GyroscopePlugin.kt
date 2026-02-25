package com.HamzaIqbal.gyroscope_plugin

import android.content.Context
import android.content.Intent
import android.hardware.SensorManager
import com.earnscape.gyroscopesdk.GyroscopeSDK
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class GyroscopePlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var methodChannel: MethodChannel
    private lateinit var overlayChannel: MethodChannel
    private lateinit var eventChannel: EventChannel

    private var gyroscopeSDK: GyroscopeSDK? = null
    private var gyroscopeBridge: GyroscopeBridge? = null
    private var streamingBridge: StreamingBridge? = null
    private var gyroscopeReceiver: GyroscopeReceiver? = null
    private var eventSink: EventChannel.EventSink? = null
    private var context: Context? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext

        gyroscopeSDK = GyroscopeSDK(binding.applicationContext)
        gyroscopeBridge = GyroscopeBridge(binding.applicationContext)
        streamingBridge = StreamingBridge(binding.applicationContext, gyroscopeSDK!!)

        // Main method channel
        methodChannel = MethodChannel(binding.binaryMessenger, "gyroscope_plugin/methods")
        methodChannel.setMethodCallHandler(this)

        // Event channel
        eventChannel = EventChannel(binding.binaryMessenger, "gyroscope_plugin/events")
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(args: Any?, sink: EventChannel.EventSink?) { eventSink = sink }
            override fun onCancel(args: Any?) { eventSink = null }
        })

        // ✅ Overlay channel — Flutter se overlay start/stop karo
        overlayChannel = MethodChannel(binding.binaryMessenger, "gyroscope_plugin/overlay")
        overlayChannel.setMethodCallHandler { call, result ->
            when (call.method) {

                // ✅ Check permission
                "checkOverlayPermission" -> {
                    val hasPermission = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                        android.provider.Settings.canDrawOverlays(context)
                    } else true
                    result.success(hasPermission)
                }

                // ✅ Open settings
                "requestOverlayPermission" -> {
                    context?.let { ctx ->
                        try {
                            val intent = Intent(
                                android.provider.Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                android.net.Uri.parse("package:${ctx.packageName}")
                            )
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            ctx.startActivity(intent)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("OVERLAY_ERROR", e.message, null)
                        }
                    } ?: result.error("OVERLAY_ERROR", "Context is null", null)
                }

                "startOverlay" -> {
                    val startTimeMs = call.argument<Long>("startTimeMs")
                        ?: System.currentTimeMillis()
                    try {
                        val intent = Intent(context, StreamingOverlayService::class.java).apply {
                            action = StreamingOverlayService.ACTION_START
                            putExtra("startTimeMs", startTimeMs)
                        }
                        context?.startService(intent)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("OVERLAY_ERROR", e.message, null)
                    }
                }

                "stopOverlay" -> {
                    try {
                        val intent = Intent(context, StreamingOverlayService::class.java).apply {
                            action = StreamingOverlayService.ACTION_STOP
                        }
                        context?.startService(intent)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("OVERLAY_ERROR", e.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }

        // EarnSpace pattern receivers
        gyroscopeReceiver = GyroscopeReceiver(methodChannel)
        gyroscopeReceiver?.registerReceivers(binding.applicationContext)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {

            // ── Gyroscope ──────────────────────────────────────────────────────
            "start", "stop", "hasGyroscope", "isGyroActive" ->
                gyroscopeBridge?.handleMethodCall(call, result)
                    ?: result.error("NOT_INIT", "GyroscopeBridge not ready", null)

            // ── Streaming ──────────────────────────────────────────────────────
            "startSession", "stopSession",
            "isSessionActive", "getSessionId",
            "getBufferedReadings" ->
                streamingBridge?.handleMethodCall(call, result)
                    ?: result.error("NOT_INIT", "StreamingBridge not ready", null)

            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        overlayChannel.setMethodCallHandler(null)
        gyroscopeBridge?.dispose()
        streamingBridge?.dispose()
        gyroscopeReceiver?.unregisterReceivers(binding.applicationContext)
        gyroscopeReceiver = null
        gyroscopeBridge = null
        streamingBridge = null
        gyroscopeSDK = null
        context = null
    }
}