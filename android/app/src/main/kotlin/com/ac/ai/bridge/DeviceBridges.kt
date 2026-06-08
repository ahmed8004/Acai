package com.ac.ai.bridge

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.CalendarContract
import android.telephony.SmsManager
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class CalendarBridge(private val context: Context) {
    companion object {
        private const val TAG = "CalendarBridge"
        const val CHANNEL = "com.ac.ai/calendar"
    }

    private var methodChannel: MethodChannel? = null

    fun setMethodChannel(channel: MethodChannel) {
        this.methodChannel = channel
        setupMethodCallHandler()
    }

    private fun setupMethodCallHandler() {
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "addEvent" -> {
                    val title = call.argument<String>("title") ?: ""
                    val description = call.argument<String>("description") ?: ""
                    val location = call.argument<String>("location") ?: ""
                    val startTime = call.argument<Long>("startTime") ?: 0
                    val endTime = call.argument<Long>("endTime") ?: 0
                    val isAllDay = call.argument<Boolean>("isAllDay") ?: false
                    
                    val success = addEvent(title, description, location, startTime, endTime, isAllDay)
                    result.success(success)
                }
                "openCalendar" -> {
                    openCalendar()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    fun addEvent(
        title: String,
        description: String,
        location: String,
        startTime: Long,
        endTime: Long,
        isAllDay: Boolean
    ): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_INSERT).apply {
                data = CalendarContract.Events.CONTENT_URI
                putExtra(CalendarContract.Events.TITLE, title)
                putExtra(CalendarContract.Events.DESCRIPTION, description)
                putExtra(CalendarContract.Events.EVENT_LOCATION, location)
                putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, startTime)
                putExtra(CalendarContract.EXTRA_EVENT_END_TIME, endTime)
                putExtra(CalendarContract.Events.ALL_DAY, isAllDay)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            context.startActivity(intent)
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to add calendar event", e)
            false
        }
    }

    fun openCalendar() {
        try {
            val intent = Intent(Intent.ACTION_VIEW).apply {
                data = CalendarContract.CONTENT_URI.buildUpon()
                    .appendPath("time")
                    .build()
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            context.startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open calendar", e)
        }
    }
}

class SMSBridge(private val context: Context) {
    companion object {
        private const val TAG = "SMSBridge"
        const val CHANNEL = "com.ac.ai/sms"
    }

    private var methodChannel: MethodChannel? = null

    fun setMethodChannel(channel: MethodChannel) {
        this.methodChannel = channel
        setupMethodCallHandler()
    }

    private fun setupMethodCallHandler() {
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "sendSMS" -> {
                    val phoneNumber = call.argument<String>("phoneNumber") ?: ""
                    val message = call.argument<String>("message") ?: ""
                    val success = sendSMS(phoneNumber, message)
                    result.success(success)
                }
                "sendSilentSMS" -> {
                    val phoneNumber = call.argument<String>("phoneNumber") ?: ""
                    val message = call.argument<String>("message") ?: ""
                    val success = sendSilentSMS(phoneNumber, message)
                    result.success(success)
                }
                "getInboxMessages" -> {
                    val limit = call.argument<Int>("limit") ?: 10
                    val messages = getInboxMessages(limit)
                    result.success(messages)
                }
                else -> result.notImplemented()
            }
        }
    }

    fun sendSMS(phoneNumber: String, message: String): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_VIEW).apply {
                data = Uri.parse("smsto:$phoneNumber")
                putExtra("sms_body", message)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            context.startActivity(intent)
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to send SMS", e)
            false
        }
    }

    fun sendSilentSMS(phoneNumber: String, message: String): Boolean {
        return try {
            val smsManager = SmsManager.getDefault()
            val parts = smsManager.divideMessage(message)
            smsManager.sendMultipartTextMessage(phoneNumber, null, parts, null, null)
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to send silent SMS", e)
            false
        }
    }

    fun getInboxMessages(limit: Int): String {
        return "[]" // Requires READ_SMS permission
    }
}

class TorchBridge(private val context: Context) {
    companion object {
        private const val TAG = "TorchBridge"
        const val CHANNEL = "com.ac.ai/torch"
    }

    private var methodChannel: MethodChannel? = null

    fun setMethodChannel(channel: MethodChannel) {
        this.methodChannel = channel
        setupMethodCallHandler()
    }

    private fun setupMethodCallHandler() {
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "toggleTorch" -> {
                    val success = toggleTorch()
                    result.success(success)
                }
                "turnOnTorch" -> {
                    val success = turnOnTorch()
                    result.success(success)
                }
                "turnOffTorch" -> {
                    val success = turnOffTorch()
                    result.success(success)
                }
                "isTorchAvailable" -> {
                    result.success(isTorchAvailable())
                }
                "isTorchOn" -> {
                    result.success(isTorchOn())
                }
                else -> result.notImplemented()
            }
        }
    }

    private var isTorchEnabled = false

    fun toggleTorch(): Boolean {
        return if (isTorchEnabled) {
            turnOffTorch()
        } else {
            turnOnTorch()
        }
    }

    fun turnOnTorch(): Boolean {
        return try {
            val cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as android.hardware.camera2.CameraManager
            val cameraId = cameraManager.cameraIdList.firstOrNull { id ->
                cameraManager.getCameraCharacteristics(id)
                    .get(android.hardware.camera2.CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
            }
            
            cameraId?.let {
                cameraManager.setTorchMode(it, true)
                isTorchEnabled = true
                true
            } ?: false
        } catch (e: Exception) {
            Log.e(TAG, "Failed to turn on torch", e)
            false
        }
    }

    fun turnOffTorch(): Boolean {
        return try {
            val cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as android.hardware.camera2.CameraManager
            val cameraId = cameraManager.cameraIdList.firstOrNull { id ->
                cameraManager.getCameraCharacteristics(id)
                    .get(android.hardware.camera2.CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
            }
            
            cameraId?.let {
                cameraManager.setTorchMode(it, false)
                isTorchEnabled = false
                true
            } ?: false
        } catch (e: Exception) {
            Log.e(TAG, "Failed to turn off torch", e)
            false
        }
    }

    fun isTorchAvailable(): Boolean {
        return try {
            val cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as android.hardware.camera2.CameraManager
            cameraManager.cameraIdList.any { id ->
                cameraManager.getCameraCharacteristics(id)
                    .get(android.hardware.camera2.CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
            }
        } catch (e: Exception) {
            false
        }
    }

    fun isTorchOn(): Boolean {
        return isTorchEnabled
    }
}

class BluetoothBridge(private val context: Context) {
    companion object {
        private const val TAG = "BluetoothBridge"
        const val CHANNEL = "com.ac.ai/bluetooth"
    }

    private var methodChannel: MethodChannel? = null

    fun setMethodChannel(channel: MethodChannel) {
        this.methodChannel = channel
        setupMethodCallHandler()
    }

    private fun setupMethodCallHandler() {
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isBluetoothAvailable" -> result.success(isBluetoothAvailable())
                "isBluetoothEnabled" -> result.success(isBluetoothEnabled())
                "enableBluetooth" -> result.success(enableBluetooth())
                "disableBluetooth" -> result.success(disableBluetooth())
                "getPairedDevices" -> result.success(getPairedDevices())
                "startDiscovery" -> result.success(startDiscovery())
                "cancelDiscovery" -> result.success(cancelDiscovery())
                else -> result.notImplemented()
            }
        }
    }

    fun isBluetoothAvailable(): Boolean {
        val bluetoothAdapter = android.bluetooth.BluetoothAdapter.getDefaultAdapter()
        return bluetoothAdapter != null
    }

    fun isBluetoothEnabled(): Boolean {
        val bluetoothAdapter = android.bluetooth.BluetoothAdapter.getDefaultAdapter()
        return bluetoothAdapter?.isEnabled == true
    }

    fun enableBluetooth(): Boolean {
        return try {
            val bluetoothAdapter = android.bluetooth.BluetoothAdapter.getDefaultAdapter()
            bluetoothAdapter?.enable() == true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to enable Bluetooth", e)
            false
        }
    }

    fun disableBluetooth(): Boolean {
        return try {
            val bluetoothAdapter = android.bluetooth.BluetoothAdapter.getDefaultAdapter()
            bluetoothAdapter?.disable() == true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to disable Bluetooth", e)
            false
        }
    }

    fun getPairedDevices(): String {
        return try {
            val bluetoothAdapter = android.bluetooth.BluetoothAdapter.getDefaultAdapter()
            val devices = bluetoothAdapter?.bondedDevices?.map { device ->
                mapOf(
                    "name" to (device.name ?: "Unknown"),
                    "address" to device.address,
                    "type" to device.type
                )
            } ?: emptyList()
            org.json.JSONArray(devices).toString()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get paired devices", e)
            "[]"
        }
    }

    fun startDiscovery(): Boolean {
        return try {
            val bluetoothAdapter = android.bluetooth.BluetoothAdapter.getDefaultAdapter()
            bluetoothAdapter?.cancelDiscovery()
            bluetoothAdapter?.startDiscovery() == true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start discovery", e)
            false
        }
    }

    fun cancelDiscovery(): Boolean {
        return try {
            val bluetoothAdapter = android.bluetooth.BluetoothAdapter.getDefaultAdapter()
            bluetoothAdapter?.cancelDiscovery() == true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to cancel discovery", e)
            false
        }
    }
}

class WiFiBridge(private val context: Context) {
    companion object {
        private const val TAG = "WiFiBridge"
        const val CHANNEL = "com.ac.ai/wifi"
    }

    private var methodChannel: MethodChannel? = null

    fun setMethodChannel(channel: MethodChannel) {
        this.methodChannel = channel
        setupMethodCallHandler()
    }

    private fun setupMethodCallHandler() {
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isWiFiEnabled" -> result.success(isWiFiEnabled())
                "enableWiFi" -> result.success(enableWiFi())
                "disableWiFi" -> result.success(disableWiFi())
                "getWiFiInfo" -> result.success(getWiFiInfo())
                "getConfiguredNetworks" -> result.success(getConfiguredNetworks())
                else -> result.notImplemented()
            }
        }
    }

    fun isWiFiEnabled(): Boolean {
        return try {
            val wifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as android.net.wifi.WifiManager
            wifiManager.isWifiEnabled
        } catch (e: Exception) {
            Log.e(TAG, "Failed to check WiFi status", e)
            false
        }
    }

    fun enableWiFi(): Boolean {
        return try {
            val wifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as android.net.wifi.WifiManager
            wifiManager.setWifiEnabled(true)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to enable WiFi", e)
            false
        }
    }

    fun disableWiFi(): Boolean {
        return try {
            val wifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as android.net.wifi.WifiManager
            wifiManager.setWifiEnabled(false)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to disable WiFi", e)
            false
        }
    }

    fun getWiFiInfo(): String {
        return try {
            val wifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as android.net.wifi.WifiManager
            val connectionInfo = wifiManager.connectionInfo
            
            val info = mapOf(
                "ssid" to (connectionInfo.ssid ?: ""),
                "bssid" to (connectionInfo.bssid ?: ""),
                "ipAddress" to android.text.format.Formatter.formatIpAddress(connectionInfo.ipAddress),
                "linkSpeed" to connectionInfo.linkSpeed,
                "rssi" to connectionInfo.rssi,
                "networkId" to connectionInfo.networkId
            )
            org.json.JSONObject(info).toString()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get WiFi info", e)
            "{}"
        }
    }

    fun getConfiguredNetworks(): String {
        return try {
            val wifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as android.net.wifi.WifiManager
            val networks = wifiManager.configuredNetworks?.map { network ->
                mapOf(
                    "networkId" to network.networkId,
                    "ssid" to (network.SSID ?: ""),
                    "status" to network.status
                )
            } ?: emptyList()
            org.json.JSONArray(networks).toString()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get configured networks", e)
            "[]"
        }
    }
}
