package com.ac.ai.bridge

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.util.Log
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class USBMonitor(private val context: Context) : BroadcastReceiver() {
    companion object {
        private const val TAG = "USBMonitor"
        private const val ACTION_USB_ATTACHED = "android.hardware.usb.action.USB_DEVICE_ATTACHED"
        private const val ACTION_USB_DETACHED = "android.hardware.usb.action.USB_DEVICE_DETACHED"
        const val ACTION_USB_PERMISSION = "com.ac.ai.USB_PERMISSION"
        
        val VENDOR_IDS = mapOf(
            0x0781 to "SanDisk",
            0x0951 to "Kingston",
            0x04E8 to "Samsung",
            0x058F to "Alcor Micro",
            0x090C to "Silicon Motion",
            0x13FE to "Kingston",
            0x154B to "PNY",
            0x18A5 to "Verbatim",
            0x1E3D to "Chipsbank",
            0x0483 to "STMicroelectronics"
        )
    }

    private var methodChannel: MethodChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private val usbManager = context.getSystemService(Context.USB_SERVICE) as UsbManager
    private val connectedDevices = mutableMapOf<String, UsbDevice>()

    init {
        scanConnectedDevices()
    }

    fun scanConnectedDevices() {
        val deviceList = usbManager.deviceList
        deviceList.values.forEach { device ->
            connectedDevices[device.deviceName] = device
            Log.d(TAG, "Found USB device: ${device.deviceName}")
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_USB_ATTACHED -> {
                val device = intent.getParcelableExtra<UsbDevice>(UsbManager.EXTRA_DEVICE)
                device?.let {
                    connectedDevices[it.deviceName] = it
                    Log.d(TAG, "USB device attached: ${it.deviceName}")
                    notifyDeviceAttached(it)
                }
            }
            
            ACTION_USB_DETACHED -> {
                val device = intent.getParcelableExtra<UsbDevice>(UsbManager.EXTRA_DEVICE)
                device?.let {
                    connectedDevices.remove(it.deviceName)
                    Log.d(TAG, "USB device detached: ${it.deviceName}")
                    notifyDeviceDetached(it)
                }
            }
            
            ACTION_USB_PERMISSION -> {
                val device = intent.getParcelableExtra<UsbDevice>(UsbManager.EXTRA_DEVICE)
                val granted = intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)
                device?.let {
                    Log.d(TAG, "USB permission for ${it.deviceName}: $granted")
                    notifyPermissionResult(it, granted)
                }
            }
        }
    }

    private fun notifyDeviceAttached(device: UsbDevice) {
        val deviceInfo = getDeviceInfo(device)
        methodChannel?.invokeMethod("onUsbDeviceAttached", deviceInfo)
        eventSink?.success(deviceInfo)
    }

    private fun notifyDeviceDetached(device: UsbDevice) {
        val deviceInfo = getDeviceInfo(device)
        methodChannel?.invokeMethod("onUsbDeviceDetached", deviceInfo)
        eventSink?.success(deviceInfo)
    }

    private fun notifyPermissionResult(device: UsbDevice, granted: Boolean) {
        val result = JSONObject().apply {
            put("deviceName", device.deviceName)
            put("granted", granted)
        }.toString()
        methodChannel?.invokeMethod("onUsbPermissionResult", result)
    }

    fun getDeviceInfo(device: UsbDevice): String {
        return JSONObject().apply {
            put("deviceName", device.deviceName)
            put("vendorId", device.vendorId)
            put("productId", device.productId)
            put("vendorName", VENDOR_IDS[device.vendorId] ?: "Unknown")
            put("productName", device.productName ?: "Unknown")
            put("manufacturerName", device.manufacturerName ?: "Unknown")
            put("serialNumber", device.serialNumber ?: "")
            put("deviceClass", device.deviceClass)
            put("deviceSubclass", device.deviceSubclass)
            put("deviceProtocol", device.deviceProtocol)
            put("interfaceCount", device.interfaceCount)
            put("isMassStorage", isMassStorageDevice(device))
        }.toString()
    }

    private fun isMassStorageDevice(device: UsbDevice): Boolean {
        return device.deviceClass == 0x08 || 
               (0 until device.interfaceCount).any { i ->
                   device.getInterface(i).interfaceClass == 0x08
               }
    }

    fun requestPermission(device: UsbDevice): Boolean {
        return if (usbManager.hasPermission(device)) {
            true
        } else {
            val intent = Intent(ACTION_USB_PERMISSION).apply {
                `package` = context.packageName
            }
            val pendingIntent = android.app.PendingIntent.getBroadcast(
                context, 0, intent, android.app.PendingIntent.FLAG_IMMUTABLE
            )
            usbManager.requestPermission(device, pendingIntent)
            false
        }
    }

    fun getConnectedDevices(): String {
        val devices = org.json.JSONArray()
        connectedDevices.values.forEach { device ->
            devices.put(JSONObject(getDeviceInfo(device)))
        }
        return devices.toString()
    }

    fun checkDeviceHealth(device: UsbDevice): String {
        return JSONObject().apply {
            put("deviceName", device.deviceName)
            put("hasPermission", usbManager.hasPermission(device))
            put("isMassStorage", isMassStorageDevice(device))
            put("interfaceCount", device.interfaceCount)
            put("status", if (usbManager.hasPermission(device)) "healthy" else "no_permission")
        }.toString()
    }

    fun setMethodChannel(channel: MethodChannel) {
        this.methodChannel = channel
    }

    fun setEventSink(sink: EventChannel.EventSink?) {
        this.eventSink = sink
    }
}
