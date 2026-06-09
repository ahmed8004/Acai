package com.ac.ai.services

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.accessibilityservice.GestureDescription
import android.graphics.Path
import android.graphics.Rect
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class ACAIAccessibilityService : AccessibilityService() {
    companion object {
        private const val TAG = "AccessibilityService"
        private const val CHANNEL = "com.ac.ai/accessibility"
        
        var instance: ACAIAccessibilityService? = null
            private set
        
        var currentPackageName: String = ""
            private set
        var currentWindowClass: String = ""
            private set
        var currentText: String = ""
            private set
    }

    private var methodChannel: MethodChannel? = null

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        Log.d(TAG, "Accessibility Service connected")
        
        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                    AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED or
                    AccessibilityEvent.TYPE_VIEW_CLICKED or
                    AccessibilityEvent.TYPE_VIEW_SCROLLED or
                    AccessibilityEvent.TYPE_NOTIFICATION_STATE_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS or
                    AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                    AccessibilityServiceInfo.FLAG_REQUEST_TOUCH_EXPLORATION_MODE
            notificationTimeout = 100
        }
        serviceInfo = info
        
        methodChannel?.invokeMethod("onServiceConnected", null)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        event?.let {
            when (it.eventType) {
                AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                    currentPackageName = it.packageName?.toString() ?: ""
                    currentWindowClass = it.className?.toString() ?: ""
                    Log.d(TAG, "Window changed: $currentPackageName / $currentWindowClass")
                    
                    methodChannel?.invokeMethod("onWindowChanged", JSONObject().apply {
                        put("packageName", currentPackageName)
                        put("className", currentWindowClass)
                    }.toString())
                }
                
                AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> {
                    val root = rootInActiveWindow
                    root?.let { node ->
                        val content = extractContent(node)
                        methodChannel?.invokeMethod("onContentChanged", JSONObject().apply {
                            put("packageName", currentPackageName)
                            put("content", content)
                        }.toString())
                    }
                }
                
                AccessibilityEvent.TYPE_VIEW_CLICKED -> {
                    val node = it.source
                    node?.let { source ->
                        methodChannel?.invokeMethod("onViewClicked", JSONObject().apply {
                            put("text", source.text?.toString() ?: "")
                            put("contentDescription", source.contentDescription?.toString() ?: "")
                            put("className", source.className?.toString() ?: "")
                        }.toString())
                    }
                }
                else -> {
                    // Handle other event types if needed
                }
            }
        }
    }

    override fun onInterrupt() {
        Log.d(TAG, "Accessibility Service interrupted")
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        Log.d(TAG, "Accessibility Service destroyed")
    }

    private fun extractContent(node: AccessibilityNodeInfo): String {
        val builder = StringBuilder()
        extractNodeText(node, builder)
        return builder.toString()
    }

    private fun extractNodeText(node: AccessibilityNodeInfo?, builder: StringBuilder) {
        node?.let {
            it.text?.let { text ->
                builder.append(text).append(" ")
            }
            
            for (i in 0 until it.childCount) {
                extractNodeText(it.getChild(i), builder)
            }
        }
    }

    fun performClick(x: Float, y: Float): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val path = Path().apply {
                moveTo(x, y)
            }
            
            val gesture = GestureDescription.Builder()
                .addStroke(GestureDescription.StrokeDescription(path, 0, 100))
                .build()
            
            return dispatchGesture(gesture, null, null)
        }
        return false
    }

    fun performSwipe(startX: Float, startY: Float, endX: Float, endY: Float, duration: Long = 300): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val path = Path().apply {
                moveTo(startX, startY)
                lineTo(endX, endY)
            }
            
            val gesture = GestureDescription.Builder()
                .addStroke(GestureDescription.StrokeDescription(path, 0, duration))
                .build()
            
            return dispatchGesture(gesture, null, null)
        }
        return false
    }

    fun performScroll(node: AccessibilityNodeInfo, direction: Int): Boolean {
        return node.performAction(AccessibilityNodeInfo.ACTION_SCROLL_FORWARD) ||
               node.performAction(AccessibilityNodeInfo.ACTION_SCROLL_BACKWARD)
    }

    fun findAndClick(text: String): Boolean {
        val root = rootInActiveWindow ?: return false
        return findNodeByText(root, text)?.let { node ->
            node.performAction(AccessibilityNodeInfo.ACTION_CLICK)
        } ?: false
    }

    fun findAndClickById(id: String): Boolean {
        val root = rootInActiveWindow ?: return false
        return findNodeById(root, id)?.let { node ->
            node.performAction(AccessibilityNodeInfo.ACTION_CLICK)
        } ?: false
    }

    fun inputText(node: AccessibilityNodeInfo, text: String): Boolean {
        val arguments = Bundle().apply {
            putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, text)
        }
        return node.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, arguments)
    }

    private fun findNodeByText(node: AccessibilityNodeInfo, text: String): AccessibilityNodeInfo? {
        if (node.text?.toString()?.contains(text, ignoreCase = true) == true ||
            node.contentDescription?.toString()?.contains(text, ignoreCase = true) == true) {
            return node
        }
        
        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            val result = findNodeByText(child, text)
            if (result != null) return result
        }
        
        return null
    }

    private fun findNodeById(node: AccessibilityNodeInfo, id: String): AccessibilityNodeInfo? {
        if (node.viewIdResourceName == id) {
            return node
        }
        
        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            val result = findNodeById(child, id)
            if (result != null) return result
        }
        
        return null
    }

    fun getCurrentAppInfo(): String {
        return JSONObject().apply {
            put("packageName", currentPackageName)
            put("className", currentWindowClass)
            put("currentText", currentText)
        }.toString()
    }

    fun setMethodChannel(channel: MethodChannel) {
        this.methodChannel = channel
    }
}
