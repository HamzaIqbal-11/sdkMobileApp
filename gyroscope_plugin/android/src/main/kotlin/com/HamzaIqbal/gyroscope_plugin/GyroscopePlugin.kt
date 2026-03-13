package com.HamzaIqbal.gyroscope_plugin

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.Log
import com.earnscape.gyroscopesdk.GyroscopeSDK
import com.earnscape.gyroscopesdk.TransactionService
import com.earnscape.gyroscopesdk.DeviceService
import com.earnscape.gyroscopesdk.StreamingSDK
import com.example.gyroscope.kyc.FaceRecognitionActivity
import com.example.gyroscope.kyc.KycActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

class GyroscopePlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    PluginRegistry.ActivityResultListener, PluginRegistry.RequestPermissionsResultListener {

    companion object {
        private const val TAG = "GyroscopePlugin"
        private const val MEDIA_PROJECTION_REQUEST_CODE = 2001
        private const val FACE_RECOGNITION_REQUEST_CODE = 2004
        private const val KYC_REQUEST_CODE = 2005
    }

    private lateinit var methodChannel: MethodChannel
    private lateinit var overlayChannel: MethodChannel
    private lateinit var eventChannel: EventChannel

    private var gyroscopeSDK: GyroscopeSDK? = null
    private var gyroscopeBridge: GyroscopeBridge? = null
    private var streamingBridge: StreamingBridge? = null
    private var gyroscopeReceiver: GyroscopeReceiver? = null
    private var eventSink: EventChannel.EventSink? = null
    private var context: Context? = null

    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null

    // Pending results
    private var pendingResult: Result? = null
    private var pendingFaceResult: Result? = null
    private var pendingKycResult: Result? = null

    // Pending stream config (stored until permission granted)
    private var pendingGameId: String? = null
    private var pendingStreamUrl: String? = null
    private var pendingTargetPackage: String? = null
    private var pendingStreamTitle: String? = null
    private var pendingPlayerId: String? = null
    private var pendingAudio: String? = null
    private var pendingVideoEnabled: String? = null
    private var pendingStreamKey: String? = null
    private var pendingPlayerName: String? = null
    private var pendingGameName: String? = null
    private var pendingMinStreamSpeed: String? = null
    private var pendingBadConnectionTimeout: String? = null

    // ── FlutterPlugin ─────────────────────────────────────────────────────────

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext

        gyroscopeSDK = GyroscopeSDK(binding.applicationContext)
        gyroscopeBridge = GyroscopeBridge(binding.applicationContext)
        streamingBridge = StreamingBridge(binding.applicationContext, gyroscopeSDK!!)

        methodChannel = MethodChannel(binding.binaryMessenger, "gyroscope_plugin/methods")
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(binding.binaryMessenger, "gyroscope_plugin/events")
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(args: Any?, sink: EventChannel.EventSink?) { eventSink = sink }
            override fun onCancel(args: Any?) { eventSink = null }
        })

        overlayChannel = MethodChannel(binding.binaryMessenger, "gyroscope_plugin/overlay")
        overlayChannel.setMethodCallHandler { call, result ->
            when (call.method) {

                // ── Overlay Permission ──
                "checkOverlayPermission" -> {
                    val has = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                        android.provider.Settings.canDrawOverlays(context) else true
                    result.success(has)
                }

                "requestOverlayPermission" -> {
                    context?.let { ctx ->
                        try {
                            val intent = Intent(
                                android.provider.Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                android.net.Uri.parse("package:${ctx.packageName}")
                            ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            ctx.startActivity(intent)
                            result.success(null)
                        } catch (e: Exception) { result.error("OVERLAY_ERROR", e.message, null) }
                    } ?: result.error("OVERLAY_ERROR", "Context is null", null)
                }

                // ── Overlay Start/Stop ──
                "startOverlay" -> {
                    try {
                        val intent = Intent(context, StreamingOverlayService::class.java).apply {
                            action = StreamingOverlayService.ACTION_START
                            putExtra("startTimeMs", call.argument<Long>("startTimeMs") ?: System.currentTimeMillis())
                        }
                        context?.startService(intent)
                        result.success(null)
                    } catch (e: Exception) { result.error("OVERLAY_ERROR", e.message, null) }
                }

                "stopOverlay" -> {
                    try {
                        context?.startService(Intent(context, StreamingOverlayService::class.java).apply {
                            action = StreamingOverlayService.ACTION_STOP
                        })
                        result.success(null)
                    } catch (e: Exception) { result.error("OVERLAY_ERROR", e.message, null) }
                }

                // ── Face Recognition (just capture, return path) ──────────
                "openFaceRecognition" -> {
                    Log.d(TAG, "openFaceRecognition called")

                    if (activity == null) {
                        result.error("NO_ACTIVITY", "Activity not available", null)
                        return@setMethodCallHandler
                    }

                    pendingFaceResult = result
                    try {
                        val intent = Intent(activity, FaceRecognitionActivity::class.java)
                        activity!!.startActivityForResult(intent, FACE_RECOGNITION_REQUEST_CODE)
                    } catch (e: Exception) {
                        pendingFaceResult = null
                        result.error("LAUNCH_ERROR", e.message, null)
                    }
                }

                // ── KYC (opens home screen with doc + video cards) ──
                "openKyc" -> {
                    Log.d(TAG, "openKyc called")
                    if (activity == null) {
                        result.error("NO_ACTIVITY", "Activity not available", null)
                        return@setMethodCallHandler
                    }
                    pendingKycResult = result
                    try {
                        val intent = Intent(activity, KycActivity::class.java)
                        activity!!.startActivityForResult(intent, KYC_REQUEST_CODE)
                    } catch (e: Exception) {
                        pendingKycResult = null
                        result.error("LAUNCH_ERROR", e.message, null)
                    }
                }

                // ── Transaction (validate + structure only, API on Dart side) ──
                "validateTransaction" -> {
                    Log.d(TAG, "validateTransaction called")
                    val fieldsMap = call.argument<Map<String, String>>("fields") ?: emptyMap()
                    val txResult = TransactionService.validateTransaction(fieldsMap)
                    result.success(txResult)
                }

                // ── Device Info (ID + details + location) ──
                "getDeviceInfo" -> {
                    Log.d(TAG, "getDeviceInfo called")
                    if (context == null) {
                        result.error("NO_CONTEXT", "Context not available", null)
                        return@setMethodCallHandler
                    }
                    DeviceService.getFullDeviceInfo(context!!) { info ->
                        result.success(info)
                    }
                }

                "getDeviceId" -> {
                    Log.d(TAG, "getDeviceId called")
                    if (context == null) {
                        result.error("NO_CONTEXT", "Context not available", null)
                        return@setMethodCallHandler
                    }
                    result.success(mapOf("deviceId" to DeviceService.getOrCreateDeviceId(context!!)))
                }

                "getLocation" -> {
                    Log.d(TAG, "getLocation called")
                    if (context == null) {
                        result.error("NO_CONTEXT", "Context not available", null)
                        return@setMethodCallHandler
                    }
                    DeviceService.getLocation(context!!) { location ->
                        result.success(location)
                    }
                }

                // ── MediaProjection (direct request) ──
                "requestMediaProjection" -> {
                    Log.d(TAG, "requestMediaProjection called")

                    if (activity == null) {
                        result.error("NO_ACTIVITY", "Activity not available", null)
                        return@setMethodCallHandler
                    }

                    pendingResult = result

                    // Store stream config
                    pendingGameId = call.argument<String>("gameId") ?: "unknown"
                    pendingStreamUrl = call.argument<String>("streamUrl")
                    pendingTargetPackage = call.argument<String>("targetPackageName") ?: ""
                    pendingStreamTitle = call.argument<String>("streamTitle") ?: ""
                    pendingPlayerId = call.argument<String>("playerId") ?: ""
                    pendingAudio = call.argument<String>("audio") ?: "true"
                    pendingVideoEnabled = call.argument<String>("videoEnabled") ?: "false"
                    pendingStreamKey = call.argument<String>("streamKey") ?: ""
                    pendingPlayerName = call.argument<String>("playerName") ?: ""
                    pendingGameName = call.argument<String>("gameName") ?: ""
                    pendingMinStreamSpeed = call.argument<String>("minimumStreamSpeed") ?: "1"
                    pendingBadConnectionTimeout = call.argument<String>("badConnectionTimeout") ?: "30"

                    // Direct MediaProjection request
                  // SDK handles permission (Android 14+ entire screen only)
                    StreamingSDK.requestMediaProjectionPermission(activity!!, MEDIA_PROJECTION_REQUEST_CODE)
                }

                // ── Stop Streaming ──
                "stopStreaming" -> {
                    try {
                        context?.startService(Intent(context, ScreenRecordingService::class.java).apply {
                            action = ScreenRecordingService.ACTION_STOP
                        })
                        result.success(null)
                    } catch (e: Exception) { result.error("STOP_ERROR", e.message, null) }
                }

                "isStreaming" -> result.success(ScreenRecordingService.isRunning)

                else -> result.notImplemented()
            }
        }

        gyroscopeReceiver = GyroscopeReceiver(methodChannel)
        gyroscopeReceiver?.registerReceivers(binding.applicationContext)
    }

    // ── Start ScreenRecordingService (called after SDK grants permissions) ────

    private fun startStreamingService(resultCode: Int, data: Intent?) {
        val intent = Intent(context, ScreenRecordingService::class.java).apply {
            action = ScreenRecordingService.ACTION_START
            putExtra(ScreenRecordingService.EXTRA_RESULT_CODE, resultCode)
            putExtra(ScreenRecordingService.EXTRA_DATA, data)
            putExtra(ScreenRecordingService.EXTRA_GAME_ID, pendingGameId)
            putExtra(ScreenRecordingService.EXTRA_STREAM_URL, pendingStreamUrl)
            putExtra("targetPackageName", pendingTargetPackage)
            putExtra("streamTitle", pendingStreamTitle)
            putExtra("playerId", pendingPlayerId)
            putExtra("audio", pendingAudio)
            putExtra("videoEnabled", pendingVideoEnabled)
            putExtra("streamKey", pendingStreamKey)
            putExtra("playerName", pendingPlayerName)
            putExtra("gameName", pendingGameName)
            putExtra("minimumStreamSpeed", pendingMinStreamSpeed)
            putExtra("badConnectionTimeout", pendingBadConnectionTimeout)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context?.startForegroundService(intent)
        } else {
            context?.startService(intent)
        }

        pendingResult?.success("recording_started")
        pendingResult = null
    }

    // ── Activity Results ─────────────────────────────────────────────────────

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {

        // MediaProjection result
        if (requestCode == MEDIA_PROJECTION_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                Log.d(TAG, "✅ MediaProjection granted")
                startStreamingService(resultCode, data)
            } else {
                Log.e(TAG, "❌ MediaProjection denied")
                pendingResult?.error("DENIED", "MediaProjection permission denied", null)
                pendingResult = null
            }
            return true
        }

        // Face Recognition result
        if (requestCode == FACE_RECOGNITION_REQUEST_CODE) {
            val faceResult = pendingFaceResult
            pendingFaceResult = null

            if (faceResult != null) {
                if (resultCode == Activity.RESULT_OK && data != null) {
                    faceResult.success(mapOf(
                        "success" to true,
                        "imagePath" to (data.getStringExtra("imagePath") ?: "")
                    ))
                } else {
                    faceResult.success(mapOf("success" to false, "error" to "cancelled"))
                }
            }
            return true
        }

        // KYC result
        if (requestCode == KYC_REQUEST_CODE) {
            val r = pendingKycResult
            pendingKycResult = null
            if (r != null) {
                if (resultCode == Activity.RESULT_OK && data != null) {
                    r.success(mapOf(
                        "success" to true,
                        "docType" to (data.getStringExtra(KycActivity.RESULT_DOC_TYPE) ?: ""),
                        "frontPhoto" to (data.getStringExtra(KycActivity.RESULT_FRONT_PHOTO) ?: ""),
                        "backPhoto" to (data.getStringExtra(KycActivity.RESULT_BACK_PHOTO) ?: ""),
                        "selfieVideo" to (data.getStringExtra(KycActivity.RESULT_SELFIE_VIDEO) ?: "")
                    ))
                } else {
                    r.success(mapOf("success" to false, "error" to "cancelled"))
                }
            }
            return true
        }

        return false
    }

    // ── Permission Results ──────────────────────────────────────────────────

    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<out String>, grantResults: IntArray
    ): Boolean {
        return false
    }

    // ── MethodCallHandler (main channel) ──

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "start", "stop", "hasGyroscope", "isGyroActive" ->
                gyroscopeBridge?.handleMethodCall(call, result) ?: result.error("NOT_INIT", "GyroscopeBridge not ready", null)
            "startSession", "stopSession", "isSessionActive", "getSessionId", "getBufferedReadings" ->
                streamingBridge?.handleMethodCall(call, result) ?: result.error("NOT_INIT", "StreamingBridge not ready", null)
            else -> result.notImplemented()
        }
    }

    // ── ActivityAware ─────────────────────────────────────────────────────────

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity; activityBinding = binding
        binding.addActivityResultListener(this); binding.addRequestPermissionsResultListener(this)
    }
    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeActivityResultListener(this); activityBinding?.removeRequestPermissionsResultListener(this)
        activity = null; activityBinding = null
    }
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity; activityBinding = binding
        binding.addActivityResultListener(this); binding.addRequestPermissionsResultListener(this)
    }
    override fun onDetachedFromActivity() {
        activityBinding?.removeActivityResultListener(this); activityBinding?.removeRequestPermissionsResultListener(this)
        activity = null; activityBinding = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null); overlayChannel.setMethodCallHandler(null)
        gyroscopeBridge?.dispose(); streamingBridge?.dispose()
        gyroscopeReceiver?.unregisterReceivers(binding.applicationContext)
        gyroscopeReceiver = null; gyroscopeBridge = null; streamingBridge = null
        gyroscopeSDK = null; context = null
    }
}