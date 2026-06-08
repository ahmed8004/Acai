package com.ac.ai.services

import android.app.Notification
import android.content.Context
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

class ACAINotificationListener : NotificationListenerService() {
    companion object {
        private const val TAG = "NotificationListener"
        private const val CHANNEL = "com.ac.ai/notifications"
    }

    private var methodChannel: MethodChannel? = null
    private val activeNotifications = mutableMapOf<String, StatusBarNotification>()

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Notification Listener created")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        sbn?.let {
            val key = it.key
            activeNotifications[key] = it
            
            val notificationData = extractNotificationData(it)
            Log.d(TAG, "Notification posted: ${it.packageName}")
            
            methodChannel?.invokeMethod("onNotificationPosted", notificationData)
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        super.onNotificationRemoved(sbn)
        sbn?.let {
            activeNotifications.remove(it.key)
            
            val notificationData = extractNotificationData(it)
            Log.d(TAG, "Notification removed: ${it.packageName}")
            
            methodChannel?.invokeMethod("onNotificationRemoved", notificationData)
        }
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d(TAG, "Notification Listener connected")
        
        val notifications = activeNotifications
        val notificationsJson = JSONArray()
        notifications.values.forEach { sbn ->
            notificationsJson.put(extractNotificationData(sbn))
        }
        
        methodChannel?.invokeMethod("onListenerConnected", notificationsJson.toString())
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.d(TAG, "Notification Listener disconnected")
        methodChannel?.invokeMethod("onListenerDisconnected", null)
    }

    private fun extractNotificationData(sbn: StatusBarNotification): String {
        val notification = sbn.notification
        val extras = notification.extras
        
        return JSONObject().apply {
            put("key", sbn.key)
            put("packageName", sbn.packageName)
            put("postTime", sbn.postTime)
            put("id", sbn.id)
            put("tag", sbn.tag ?: JSONObject.NULL)
            put("isClearable", sbn.isClearable)
            put("isOngoing", sbn.isOngoing)
            put("title", extras?.getString(Notification.EXTRA_TITLE) ?: "")
            put("text", extras?.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: "")
            put("bigText", extras?.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString() ?: "")
            put("summaryText", extras?.getCharSequence(Notification.EXTRA_SUMMARY_TEXT)?.toString() ?: "")
            put("subText", extras?.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString() ?: "")
            put("tickerText", notification.tickerText?.toString() ?: "")
        }.toString()
    }

    fun getActiveNotificationsList(): String {
        val notificationsJson = JSONArray()
        activeNotifications.values.forEach { sbn ->
            notificationsJson.put(extractNotificationData(sbn))
        }
        return notificationsJson.toString()
    }

    fun clearNotification(key: String) {
        cancelNotification(key)
        activeNotifications.remove(key)
    }

    fun clearAllNotifications() {
        cancelAllNotifications()
        activeNotifications.clear()
    }

    fun setMethodChannel(channel: MethodChannel) {
        this.methodChannel = channel
    }
}
