package com.ac.ai.bridge

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.DataOutputStream
import java.io.File
import java.io.InputStreamReader

class TermuxBridge(private val context: Context) {
    companion object {
        private const val TAG = "TermuxBridge"
        private const val TERMUX_PACKAGE = "com.termux"
        private const val TERMUX_API_PACKAGE = "com.termux.api"
        const val CHANNEL = "com.ac.ai/termux"
        
        const val ACTION_TERMUX_READY = "com.ac.ai.TERMUX_READY"
        const val ACTION_TERMUX_RESULT = "com.ac.ai.TERMUX_RESULT"
        const val ACTION_TERMUX_ERROR = "com.ac.ai.TERMUX_ERROR"
    }

    private var methodChannel: MethodChannel? = null
    private val resultReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                ACTION_TERMUX_RESULT -> {
                    val stdout = intent.getStringExtra("stdout") ?: ""
                    val stderr = intent.getStringExtra("stderr") ?: ""
                    val exitCode = intent.getIntExtra("exitCode", 0)
                    
                    methodChannel?.invokeMethod("onTermuxResult", mapOf(
                        "stdout" to stdout,
                        "stderr" to stderr,
                        "exitCode" to exitCode
                    ))
                }
                ACTION_TERMUX_ERROR -> {
                    val error = intent.getStringExtra("error") ?: "Unknown error"
                    methodChannel?.invokeMethod("onTermuxError", error)
                }
            }
        }
    }

    init {
        val filter = IntentFilter().apply {
            addAction(ACTION_TERMUX_RESULT)
            addAction(ACTION_TERMUX_ERROR)
        }
        context.registerReceiver(resultReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
    }

    fun isTermuxInstalled(): Boolean {
        return try {
            context.packageManager.getPackageInfo(TERMUX_PACKAGE, 0)
            true
        } catch (e: Exception) {
            false
        }
    }

    fun isTermuxApiInstalled(): Boolean {
        return try {
            context.packageManager.getPackageInfo(TERMUX_API_PACKAGE, 0)
            true
        } catch (e: Exception) {
            false
        }
    }

    fun executeCommand(command: String, workingDirectory: String? = null): Map<String, Any> {
        return try {
            val processBuilder = ProcessBuilder("sh", "-c", command)
            
            workingDirectory?.let {
                processBuilder.directory(File(it))
            }
            
            processBuilder.environment().apply {
                put("TERM", "xterm-256color")
                put("HOME", "/data/data/com.termux/files/home")
                put("PREFIX", "/data/data/com.termux/files/usr")
                put("PATH", "/data/data/com.termux/files/usr/bin:/data/data/com.termux/files/usr/bin/applets")
            }
            
            val process = processBuilder.start()
            
            val stdout = StringBuilder()
            BufferedReader(InputStreamReader(process.inputStream)).use { reader ->
                var line: String?
                while (reader.readLine().also { line = it } != null) {
                    stdout.appendLine(line)
                }
            }
            
            val stderr = StringBuilder()
            BufferedReader(InputStreamReader(process.errorStream)).use { reader ->
                var line: String?
                while (reader.readLine().also { line = it } != null) {
                    stderr.appendLine(line)
                }
            }
            
            val exitCode = process.waitFor()
            
            mapOf(
                "stdout" to stdout.toString(),
                "stderr" to stderr.toString(),
                "exitCode" to exitCode
            )
        } catch (e: Exception) {
            Log.e(TAG, "Failed to execute command", e)
            mapOf(
                "stdout" to "",
                "stderr" to e.message,
                "exitCode" to -1
            )
        }
    }

    fun executePythonScript(script: String, arguments: List<String>? = null): Map<String, Any> {
        val pythonCommand = buildString {
            append("python3 -c '")
            append(script.replace("'", "'\"'\"'"))
            append("'")
            arguments?.forEach { arg ->
                append(" ")
                append(arg)
            }
        }
        return executeCommand(pythonCommand)
    }

    fun executeWithRoot(command: String): Map<String, Any> {
        return try {
            val process = Runtime.getRuntime().exec("su")
            val outputStream = DataOutputStream(process.outputStream)
            
            outputStream.writeBytes("$command\n")
            outputStream.writeBytes("exit\n")
            outputStream.flush()
            
            val stdout = StringBuilder()
            BufferedReader(InputStreamReader(process.inputStream)).use { reader ->
                var line: String?
                while (reader.readLine().also { line = it } != null) {
                    stdout.appendLine(line)
                }
            }
            
            val stderr = StringBuilder()
            BufferedReader(InputStreamReader(process.errorStream)).use { reader ->
                var line: String?
                while (reader.readLine().also { line = it } != null) {
                    stderr.appendLine(line)
                }
            }
            
            val exitCode = process.waitFor()
            
            mapOf(
                "stdout" to stdout.toString(),
                "stderr" to stderr.toString(),
                "exitCode" to exitCode
            )
        } catch (e: Exception) {
            Log.e(TAG, "Failed to execute root command", e)
            mapOf(
                "stdout" to "",
                "stderr" to e.message,
                "exitCode" to -1
            )
        }
    }

    fun installPackage(packageName: String): Map<String, Any> {
        return executeCommand("pkg install -y $packageName")
    }

    fun updatePackages(): Map<String, Any> {
        return executeCommand("pkg update -y && pkg upgrade -y")
    }

    fun getInstalledPackages(): List<String> {
        val result = executeCommand("pkg list-installed")
        return if (result["exitCode"] == 0) {
            (result["stdout"] as String).lines()
                .filter { it.isNotBlank() }
                .map { it.split("/").firstOrNull() ?: it }
        } else {
            emptyList()
        }
    }

    fun runShellScript(scriptPath: String, arguments: List<String>? = null): Map<String, Any> {
        return try {
            val file = File(scriptPath)
            if (!file.exists()) {
                return mapOf(
                    "stdout" to "",
                    "stderr" to "Script not found: $scriptPath",
                    "exitCode" to -1
                )
            }
            
            val command = buildString {
                append("bash ")
                append(scriptPath)
                arguments?.forEach { arg ->
                    append(" ")
                    append(arg)
                }
            }
            executeCommand(command)
        } catch (e: Exception) {
            mapOf(
                "stdout" to "",
                "stderr" to e.message,
                "exitCode" to -1
            )
        }
    }

    fun getTermuxInfo(): Map<String, Any> {
        return mapOf(
            "isInstalled" to isTermuxInstalled(),
            "isApiInstalled" to isTermuxApiInstalled(),
            "homeDirectory" to "/data/data/com.termux/files/home",
            "prefix" to "/data/data/com.termux/files/usr"
        )
    }

    fun setMethodChannel(channel: MethodChannel) {
        this.methodChannel = channel
    }

    fun destroy() {
        try {
            context.unregisterReceiver(resultReceiver)
        } catch (e: Exception) {
            Log.w(TAG, "Receiver not registered")
        }
    }
}
