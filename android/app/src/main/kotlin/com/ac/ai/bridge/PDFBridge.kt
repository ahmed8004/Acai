package com.ac.ai.bridge

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.util.Log
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodChannel
import java.io.File

class PDFBridge(private val context: Context) {
    companion object {
        private const val TAG = "PDFBridge"
        const val CHANNEL = "com.ac.ai/pdf"
        const val FILE_PROVIDER_AUTHORITY = "com.ac.ai.fileprovider"
    }

    private var methodChannel: MethodChannel? = null

    fun setMethodChannel(channel: MethodChannel) {
        this.methodChannel = channel
        setupMethodCallHandler()
    }

    private fun setupMethodCallHandler() {
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "openPDF" -> {
                    val filePath = call.argument<String>("filePath") ?: ""
                    val success = openPDF(filePath)
                    result.success(success)
                }
                "openPDFWithNativeReader" -> {
                    val filePath = call.argument<String>("filePath") ?: ""
                    val success = openPDFWithNativeReader(filePath)
                    result.success(success)
                }
                "isPDFAvailable" -> {
                    val filePath = call.argument<String>("filePath") ?: ""
                    result.success(isPDFAvailable(filePath))
                }
                "getPDFInfo" -> {
                    val filePath = call.argument<String>("filePath") ?: ""
                    val info = getPDFInfo(filePath)
                    result.success(info)
                }
                else -> result.notImplemented()
            }
        }
    }

    fun openPDF(filePath: String): Boolean {
        return try {
            val file = File(filePath)
            if (!file.exists()) {
                Log.e(TAG, "PDF file not found: $filePath")
                return false
            }

            val uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                FileProvider.getUriForFile(context, FILE_PROVIDER_AUTHORITY, file)
            } else {
                Uri.fromFile(file)
            }

            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/pdf")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
            }

            context.startActivity(intent)
            true
        } catch (e: Exception) {
            Log.e(TAG, "Error opening PDF", e)
            false
        }
    }

    fun openPDFWithNativeReader(filePath: String): Boolean {
        return try {
            val file = File(filePath)
            if (!file.exists()) {
                Log.e(TAG, "PDF file not found: $filePath")
                return false
            }

            val uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                FileProvider.getUriForFile(context, FILE_PROVIDER_AUTHORITY, file)
            } else {
                Uri.fromFile(file)
            }

            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/pdf")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
            }

            val packageManager = context.packageManager
            val activities = packageManager.queryIntentActivities(intent, 0)
            
            if (activities.isNotEmpty()) {
                context.startActivity(intent)
                true
            } else {
                Log.e(TAG, "No PDF reader found")
                false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error opening PDF with native reader", e)
            false
        }
    }

    fun isPDFAvailable(filePath: String): Boolean {
        return try {
            val file = File(filePath)
            file.exists() && file.extension.equals("pdf", ignoreCase = true)
        } catch (e: Exception) {
            false
        }
    }

    fun getPDFInfo(filePath: String): String {
        return try {
            val file = File(filePath)
            val info = mapOf(
                "path" to file.absolutePath,
                "fileName" to file.name,
                "extension" to file.extension,
                "size" to file.length(),
                "exists" to file.exists(),
                "isPDF" to file.extension.equals("pdf", ignoreCase = true),
                "lastModified" to file.lastModified()
            )
            org.json.JSONObject(info).toString()
        } catch (e: Exception) {
            Log.e(TAG, "Error getting PDF info", e)
            "{}"
        }
    }
}
