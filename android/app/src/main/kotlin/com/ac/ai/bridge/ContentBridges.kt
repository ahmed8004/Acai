package com.ac.ai.bridge

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import android.provider.Browser

class WebViewBridge(private val context: Context) {
    companion object {
        private const val TAG = "WebViewBridge"
        const val CHANNEL = "com.ac.ai/webview"
    }

    private var methodChannel: MethodChannel? = null

    fun setMethodChannel(channel: MethodChannel) {
        this.methodChannel = channel
        setupMethodCallHandler()
    }

    private fun setupMethodCallHandler() {
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "openWebView" -> {
                    val url = call.argument<String>("url") ?: ""
                    val title = call.argument<String>("title") ?: ""
                    openWebView(url, title)
                    result.success(true)
                }
                "openBrowser" -> {
                    val url = call.argument<String>("url") ?: ""
                    openBrowser(url)
                    result.success(true)
                }
                "loadHTML" -> {
                    val html = call.argument<String>("html") ?: ""
                    val baseUrl = call.argument<String>("baseUrl") ?: ""
                    loadHTML(html, baseUrl)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    fun openWebView(url: String, title: String) {
        try {
            val intent = Intent(Intent.ACTION_VIEW).apply {
                data = Uri.parse(url)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            context.startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open WebView", e)
        }
    }

    fun openBrowser(url: String) {
        try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            context.startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open browser", e)
        }
    }

    fun loadHTML(html: String, baseUrl: String) {
        try {
            // For now, open in browser with data URI
            val dataUri = "data:text/html;base64,${android.util.Base64.encodeToString(
                html.toByteArray(), android.util.Base64.DEFAULT)}"
            openBrowser(dataUri)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to load HTML", e)
        }
    }
}

class DeepLinkBridge(private val context: Context) {
    companion object {
        private const val TAG = "DeepLinkBridge"
        const val CHANNEL = "com.ac.ai/deeplink"
    }

    private var methodChannel: MethodChannel? = null

    fun setMethodChannel(channel: MethodChannel) {
        this.methodChannel = channel
        setupMethodCallHandler()
    }

    private fun setupMethodCallHandler() {
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "handleDeepLink" -> {
                    val url = call.argument<String>("url") ?: ""
                    val success = handleDeepLink(url)
                    result.success(success)
                }
                "getInitialLink" -> {
                    result.success(getInitialLink())
                }
                "registerScheme" -> {
                    val scheme = call.argument<String>("scheme") ?: "acai"
                    registerScheme(scheme)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    fun handleDeepLink(url: String): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            context.startActivity(intent)
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to handle deep link", e)
            false
        }
    }

    fun getInitialLink(): String? {
        // Return the initial deep link that launched the app
        return null
    }

    fun registerScheme(scheme: String) {
        // Scheme registration is done in AndroidManifest.xml
        Log.d(TAG, "Scheme registered: $scheme")
    }
}

class DOCXBridge(private val context: Context) {
    companion object {
        private const val TAG = "DOCXBridge"
        const val CHANNEL = "com.ac.ai/docx"
    }

    private var methodChannel: MethodChannel? = null

    fun setMethodChannel(channel: MethodChannel) {
        this.methodChannel = channel
        setupMethodCallHandler()
    }

    private fun setupMethodCallHandler() {
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "extractTextFromDOCX" -> {
                    val filePath = call.argument<String>("filePath") ?: ""
                    val text = extractTextFromDOCX(filePath)
                    result.success(text)
                }
                "readDOCXMetadata" -> {
                    val filePath = call.argument<String>("filePath") ?: ""
                    val metadata = readDOCXMetadata(filePath)
                    result.success(metadata)
                }
                else -> result.notImplemented()
            }
        }
    }

    fun extractTextFromDOCX(filePath: String): String {
        return try {
            // DOCX is a ZIP file containing XML
            val file = java.io.File(filePath)
            if (!file.exists()) {
                return "File not found"
            }

            // For now, return a message that DOCX support is available
            // Full DOCX parsing requires additional libraries
            val documentXml = extractDocumentXml(filePath)
            if (documentXml != null) {
                parseDocumentXml(documentXml)
            } else {
                "DOCX file found but content extraction requires native implementation"
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to extract text from DOCX", e)
            "Error: ${e.message}"
        }
    }

    private fun extractDocumentXml(docxPath: String): String? {
        return try {
            val zipFile = java.util.zip.ZipFile(docxPath)
            val entry = zipFile.getEntry("word/document.xml")
            entry?.let {
                zipFile.getInputStream(it).use { stream ->
                    stream.bufferedReader().use { reader ->
                        reader.readText()
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to extract document.xml", e)
            null
        }
    }

    private fun parseDocumentXml(xml: String): String {
        // Simple text extraction - remove XML tags
        return xml
            .replace(Regex("<[^>]+>"), " ")
            .replace(Regex("\\s+"), " ")
            .trim()
    }

    fun readDOCXMetadata(filePath: String): String {
        return try {
            val file = java.io.File(filePath)
            val metadata = mapOf(
                "fileName" to file.name,
                "fileSize" to file.length(),
                "lastModified" to file.lastModified(),
                "exists" to file.exists()
            )
            org.json.JSONObject(metadata).toString()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to read DOCX metadata", e)
            "{}"
        }
    }
}
