package com.ac.ai.bridge

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import org.json.JSONArray
import org.json.JSONObject
import com.ac.ai.services.ACAIForegroundService

class NativeChannels(private val context: Context, flutterEngine: FlutterEngine) {
    companion object {
        private const val TAG = "NativeChannels"
        
        const val CHANNEL_WAKEWORD = "com.ac.ai/wakeword"
        const val CHANNEL_NOTIFICATION = "com.ac.ai/notification"
        const val CHANNEL_ACCESSIBILITY = "com.ac.ai/accessibility"
        const val CHANNEL_DEVICE = "com.ac.ai/device"
        const val CHANNEL_USB = "com.ac.ai/usb"
        const val CHANNEL_TERMUX = "com.ac.ai/termux"
        const val CHANNEL_STT = "com.ac.ai/stt"
        const val CHANNEL_TTS = "com.ac.ai/tts"
        const val CHANNEL_SERVICE = "com.ac.ai/service"
        const val CHANNEL_CALENDAR = "com.ac.ai/calendar"
        const val CHANNEL_SMS = "com.ac.ai/sms"
        const val CHANNEL_TORCH = "com.ac.ai/torch"
        const val CHANNEL_BLUETOOTH = "com.ac.ai/bluetooth"
        const val CHANNEL_WIFI = "com.ac.ai/wifi"
        const val CHANNEL_WEBVIEW = "com.ac.ai/webview"
        const val CHANNEL_DOCX = "com.ac.ai/docx"
        const val CHANNEL_CONTACTS = "com.ac.ai/contacts"
        const val CHANNEL_PDF = "com.ac.ai/pdf"
    }

    private val wakeWordChannel: MethodChannel
    private val notificationChannel: MethodChannel
    private val accessibilityChannel: MethodChannel
    private val deviceChannel: MethodChannel
    private val usbChannel: MethodChannel
    private val termuxChannel: MethodChannel
    private val sttChannel: MethodChannel
    private val ttsChannel: MethodChannel
    private val serviceChannel: MethodChannel
    private val calendarChannel: MethodChannel
    private val smsChannel: MethodChannel
    private val torchChannel: MethodChannel
    private val bluetoothChannel: MethodChannel
    private val wifiChannel: MethodChannel
    private val webViewChannel: MethodChannel
    private val docxChannel: MethodChannel
    private val contactsChannel: MethodChannel
    private val pdfChannel: MethodChannel

    private val usbEventChannel: EventChannel
    private val notificationEventChannel: EventChannel

    private val usbMonitor: USBMonitor
    private val termuxBridge: TermuxBridge
    private val calendarBridge: CalendarBridge
    private val smsBridge: SMSBridge
    private val torchBridge: TorchBridge
    private val bluetoothBridge: BluetoothBridge
    private val wifiBridge: WiFiBridge
    private val webViewBridge: WebViewBridge
    private val docxBridge: DOCXBridge
    private val contactsBridge: ContactsBridge
    private val pdfBridge: PDFBridge

    init {
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        wakeWordChannel = MethodChannel(messenger, CHANNEL_WAKEWORD)
        notificationChannel = MethodChannel(messenger, CHANNEL_NOTIFICATION)
        accessibilityChannel = MethodChannel(messenger, CHANNEL_ACCESSIBILITY)
        deviceChannel = MethodChannel(messenger, CHANNEL_DEVICE)
        usbChannel = MethodChannel(messenger, CHANNEL_USB)
        termuxChannel = MethodChannel(messenger, CHANNEL_TERMUX)
        sttChannel = MethodChannel(messenger, CHANNEL_STT)
        ttsChannel = MethodChannel(messenger, CHANNEL_TTS)
        serviceChannel = MethodChannel(messenger, CHANNEL_SERVICE)
        calendarChannel = MethodChannel(messenger, CHANNEL_CALENDAR)
        smsChannel = MethodChannel(messenger, CHANNEL_SMS)
        torchChannel = MethodChannel(messenger, CHANNEL_TORCH)
        bluetoothChannel = MethodChannel(messenger, CHANNEL_BLUETOOTH)
        wifiChannel = MethodChannel(messenger, CHANNEL_WIFI)
        webViewChannel = MethodChannel(messenger, CHANNEL_WEBVIEW)
        docxChannel = MethodChannel(messenger, CHANNEL_DOCX)
        contactsChannel = MethodChannel(messenger, CHANNEL_CONTACTS)
        pdfChannel = MethodChannel(messenger, CHANNEL_PDF)

        usbEventChannel = EventChannel(messenger, "${CHANNEL_USB}_events")
        notificationEventChannel = EventChannel(messenger, "${CHANNEL_NOTIFICATION}_events")

        usbMonitor = USBMonitor(context)
        termuxBridge = TermuxBridge(context)
        calendarBridge = CalendarBridge(context)
        smsBridge = SMSBridge(context)
        torchBridge = TorchBridge(context)
        bluetoothBridge = BluetoothBridge(context)
        wifiBridge = WiFiBridge(context)
        webViewBridge = WebViewBridge(context)
        docxBridge = DOCXBridge(context)
        contactsBridge = ContactsBridge(context)
        pdfBridge = PDFBridge(context)

        setupWakeWordChannel()
        setupNotificationChannel()
        setupAccessibilityChannel()
        setupDeviceChannel()
        setupUsbChannel()
        setupTermuxChannel()
        setupSttChannel()
        setupTtsChannel()
        setupServiceChannel()
        setupCalendarChannel()
        setupSMSChannel()
        setupTorchChannel()
        setupBluetoothChannel()
        setupWiFiChannel()
        setupWebViewChannel()
        setupDOCXChannel()
        setupContactsChannel()
        setupPDFChannel()

        usbEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                usbMonitor.setEventSink(events)
            }
            override fun onCancel(arguments: Any?) {
                usbMonitor.setEventSink(null)
            }
        })

        notificationEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            }
            override fun onCancel(arguments: Any?) {
            }
        })
    }

    private fun setupWakeWordChannel() {
        wakeWordChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startWakeWord" -> {
                    result.success(true)
                }
                "stopWakeWord" -> {
                    result.success(true)
                }
                "isListening" -> {
                    result.success(false)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun setupNotificationChannel() {
        notificationChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getActiveNotifications" -> {
                    result.success(JSONArray().toString())
                }
                "clearNotification" -> {
                    val key = call.argument<String>("key")
                    result.success(true)
                }
                "clearAllNotifications" -> {
                    result.success(true)
                }
                "replyToNotification" -> {
                    result.success(false)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun setupAccessibilityChannel() {
        accessibilityChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "isEnabled" -> {
                    result.success(false)
                }
                "getCurrentApp" -> {
                    result.success(JSONObject().toString())
                }
                "performClick" -> {
                    val x = call.argument<Double>("x")?.toFloat() ?: 0f
                    val y = call.argument<Double>("y")?.toFloat() ?: 0f
                    result.success(false)
                }
                "performSwipe" -> {
                    result.success(false)
                }
                "findAndClick" -> {
                    val text = call.argument<String>("text") ?: ""
                    result.success(false)
                }
                "inputText" -> {
                    result.success(false)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun setupDeviceChannel() {
        deviceChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "toggleFlashlight" -> {
                    result.success(false)
                }
                "setVolume" -> {
                    result.success(false)
                }
                "setBrightness" -> {
                    result.success(false)
                }
                "toggleWifi" -> {
                    result.success(false)
                }
                "toggleBluetooth" -> {
                    result.success(false)
                }
                "openApp" -> {
                    val packageName = call.argument<String>("packageName") ?: ""
                    result.success(openApp(packageName))
                }
                "makeCall" -> {
                    val number = call.argument<String>("number") ?: ""
                    makeCall(number)
                    result.success(true)
                }
                "sendSMS" -> {
                    val number = call.argument<String>("number") ?: ""
                    val message = call.argument<String>("message") ?: ""
                    sendSMS(number, message)
                    result.success(true)
                }
                "getDeviceInfo" -> {
                    result.success(getDeviceInfo())
                }
                "getBatteryLevel" -> {
                    result.success(getBatteryLevel())
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun setupUsbChannel() {
        usbMonitor.setMethodChannel(usbChannel)
        usbChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getConnectedDevices" -> {
                    result.success(usbMonitor.getConnectedDevices())
                }
                "requestPermission" -> {
                    val deviceName = call.argument<String>("deviceName") ?: ""
                    result.success(false)
                }
                "checkDeviceHealth" -> {
                    result.success(JSONObject().toString())
                }
                "formatDevice" -> {
                    result.success(false)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun setupTermuxChannel() {
        termuxBridge.setMethodChannel(termuxChannel)
        termuxChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "isTermuxInstalled" -> {
                    result.success(termuxBridge.isTermuxInstalled())
                }
                "isTermuxApiInstalled" -> {
                    result.success(termuxBridge.isTermuxApiInstalled())
                }
                "executeCommand" -> {
                    val command = call.argument<String>("command") ?: ""
                    val workingDir = call.argument<String>("workingDirectory")
                    result.success(termuxBridge.executeCommand(command, workingDir))
                }
                "executePython" -> {
                    val script = call.argument<String>("script") ?: ""
                    val args = call.argument<List<String>>("arguments")
                    result.success(termuxBridge.executePythonScript(script, args))
                }
                "executeWithRoot" -> {
                    val command = call.argument<String>("command") ?: ""
                    result.success(termuxBridge.executeWithRoot(command))
                }
                "installPackage" -> {
                    val packageName = call.argument<String>("packageName") ?: ""
                    result.success(termuxBridge.installPackage(packageName))
                }
                "updatePackages" -> {
                    result.success(termuxBridge.updatePackages())
                }
                "getInstalledPackages" -> {
                    result.success(termuxBridge.getInstalledPackages())
                }
                "runScript" -> {
                    val scriptPath = call.argument<String>("scriptPath") ?: ""
                    val args = call.argument<List<String>>("arguments")
                    result.success(termuxBridge.runShellScript(scriptPath, args))
                }
                "getTermuxInfo" -> {
                    result.success(termuxBridge.getTermuxInfo())
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun setupSttChannel() {
        sttChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startListening" -> {
                    val language = call.argument<String>("language") ?: "en-US"
                    result.success(true)
                }
                "stopListening" -> {
                    result.success(true)
                }
                "isAvailable" -> {
                    result.success(true)
                }
                "getSupportedLanguages" -> {
                    result.success(listOf("en-US", "hi-IN", "en-IN"))
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun setupTtsChannel() {
        ttsChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "speak" -> {
                    val text = call.argument<String>("text") ?: ""
                    result.success(true)
                }
                "stop" -> {
                    result.success(true)
                }
                "setLanguage" -> {
                    result.success(true)
                }
                "setSpeechRate" -> {
                    result.success(true)
                }
                "setPitch" -> {
                    result.success(true)
                }
                "getEngines" -> {
                    result.success(listOf("com.google.android.tts", "com.svox.pico"))
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun setupServiceChannel() {
        serviceChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    startForegroundService()
                    result.success(true)
                }
                "pauseService" -> {
                    pauseService()
                    result.success(true)
                }
                "stopService" -> {
                    stopService()
                    result.success(true)
                }
                "emergencyStop" -> {
                    emergencyStop()
                    result.success(true)
                }
                "isRunning" -> {
                    result.success(false)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun openApp(packageName: String): Boolean {
        return try {
            val intent = context.packageManager.getLaunchIntentForPackage(packageName)
            intent?.let {
                it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(it)
                true
            } ?: false
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open app: $packageName", e)
            false
        }
    }

    private fun makeCall(number: String) {
        try {
            val intent = Intent(Intent.ACTION_CALL).apply {
                data = Uri.parse("tel:$number")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            context.startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to make call", e)
        }
    }

    private fun sendSMS(number: String, message: String) {
        try {
            val intent = Intent(Intent.ACTION_SENDTO).apply {
                data = Uri.parse("smsto:$number")
                putExtra("sms_body", message)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            context.startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to send SMS", e)
        }
    }

    private fun getDeviceInfo(): Map<String, Any> {
        return mapOf(
            "model" to Build.MODEL,
            "manufacturer" to Build.MANUFACTURER,
            "device" to Build.DEVICE,
            "androidVersion" to Build.VERSION.RELEASE,
            "sdkVersion" to Build.VERSION.SDK_INT,
            "product" to Build.PRODUCT,
            "hardware" to Build.HARDWARE,
            "id" to Build.ID,
            "user" to Build.USER,
            "host" to Build.HOST,
            "type" to Build.TYPE,
            "tags" to Build.TAGS,
            "fingerprint" to Build.FINGERPRINT
        )
    }

    private fun getBatteryLevel(): Int {
        val batteryIntent = context.registerReceiver(null, 
            android.content.IntentFilter(android.content.Intent.ACTION_BATTERY_CHANGED))
        val level = batteryIntent?.getIntExtra(android.os.BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale = batteryIntent?.getIntExtra(android.os.BatteryManager.EXTRA_SCALE, -1) ?: -1
        return if (level >= 0 && scale > 0) {
            (level * 100 / scale)
        } else {
            -1
        }
    }

    private fun startForegroundService() {
        val intent = Intent(context, ACAIForegroundService::class.java).apply {
            action = ACAIForegroundService.ACTION_START
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(intent)
        } else {
            context.startService(intent)
        }
    }

    private fun pauseService() {
        val intent = Intent(context, ACAIForegroundService::class.java).apply {
            action = ACAIForegroundService.ACTION_PAUSE
        }
        context.startService(intent)
    }

    private fun stopService() {
        val intent = Intent(context, ACAIForegroundService::class.java).apply {
            action = ACAIForegroundService.ACTION_STOP
        }
        context.startService(intent)
    }

    private fun emergencyStop() {
        val intent = Intent(context, ACAIForegroundService::class.java).apply {
            action = ACAIForegroundService.ACTION_EMERGENCY_STOP
        }
        context.startService(intent)
    }

    private fun setupCalendarChannel() {
        calendarBridge.setMethodChannel(calendarChannel)
    }

    private fun setupSMSChannel() {
        smsBridge.setMethodChannel(smsChannel)
    }

    private fun setupTorchChannel() {
        torchBridge.setMethodChannel(torchChannel)
    }

    private fun setupBluetoothChannel() {
        bluetoothBridge.setMethodChannel(bluetoothChannel)
    }

    private fun setupWiFiChannel() {
        wifiBridge.setMethodChannel(wifiChannel)
    }

    private fun setupWebViewChannel() {
        webViewBridge.setMethodChannel(webViewChannel)
    }

    private fun setupDOCXChannel() {
        docxBridge.setMethodChannel(docxBridge)
    }

    private fun setupContactsChannel() {
        contactsBridge.setMethodChannel(contactsChannel)
    }

    private fun setupPDFChannel() {
        pdfBridge.setMethodChannel(pdfChannel)
    }

    fun destroy() {
        termuxBridge.destroy()
    }
}
