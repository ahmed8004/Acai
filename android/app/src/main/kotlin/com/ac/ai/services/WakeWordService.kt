package com.ac.ai.services

import ai.picovoice.porcupine.Porcupine
import ai.picovoice.porcupine.PorcupineManager
import ai.picovoice.porcupine.PorcupineManagerCallback
import android.content.Context
import android.media.AudioRecord
import android.util.Log
import java.io.File
import java.io.FileOutputStream

class WakeWordService(private val context: Context) {
    companion object {
        private const val TAG = "WakeWordService"
        private const val ACCESS_KEY = "YOUR_PORCUPINE_ACCESS_KEY"
        private const val MODEL_FILE = "porcupine_params.pv"
        private const val KEYWORD_FILE_HEY_AC = "hey_ac_android.ppn"
        private const val KEYWORD_FILE_AC = "ac_android.ppn"
        private const val KEYWORD_FILE_OKAY_AC = "okay_ac_android.ppn"
        private const val SAMPLE_RATE = 16000
        private const val FRAME_LENGTH = 512
    }

    private var porcupineManager: PorcupineManager? = null
    private var audioRecord: AudioRecord? = null
    private var isListening = false
    private var isInitialized = false
    
    var onWakeWordDetected: ((String) -> Unit)? = null

    init {
        initializePorcupine()
    }

    private fun initializePorcupine() {
        try {
            val keywordPaths = arrayOf(
                getKeywordPath(KEYWORD_FILE_HEY_AC),
                getKeywordPath(KEYWORD_FILE_AC),
                getKeywordPath(KEYWORD_FILE_OKAY_AC)
            )
            
            val sensitivities = floatArrayOf(0.7f, 0.7f, 0.7f)
            
            porcupineManager = PorcupineManager.Builder()
                .setAccessKey(ACCESS_KEY)
                .setKeywordPaths(keywordPaths)
                .setSensitivities(sensitivities)
                .build(context) { keywordIndex ->
                    val detectedKeyword = when (keywordIndex) {
                        0 -> "hey_ac"
                        1 -> "ac"
                        2 -> "okay_ac"
                        else -> "unknown"
                    }
                    Log.d(TAG, "Wake word detected: $detectedKeyword")
                    onWakeWordDetected?.invoke(detectedKeyword)
                }
            
            isInitialized = true
            Log.d(TAG, "Porcupine initialized successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize Porcupine", e)
            isInitialized = false
        }
    }

    private fun getKeywordPath(filename: String): String {
        val file = File(context.filesDir, filename)
        if (!file.exists()) {
            context.assets.open(filename).use { input ->
                FileOutputStream(file).use { output ->
                    input.copyTo(output)
                }
            }
        }
        return file.absolutePath
    }

    fun startListening() {
        if (!isInitialized) {
            Log.e(TAG, "Porcupine not initialized")
            return
        }
        
        if (isListening) {
            return
        }
        
        try {
            porcupineManager?.start()
            isListening = true
            Log.d(TAG, "Wake word listening started")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start listening", e)
        }
    }

    fun stopListening() {
        if (!isListening) {
            return
        }
        
        try {
            porcupineManager?.stop()
            isListening = false
            Log.d(TAG, "Wake word listening stopped")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop listening", e)
        }
    }

    fun destroy() {
        stopListening()
        porcupineManager?.delete()
        porcupineManager = null
        audioRecord?.release()
        audioRecord = null
        isInitialized = false
        Log.d(TAG, "WakeWordService destroyed")
    }

    fun isListening(): Boolean = isListening
    fun isInitialized(): Boolean = isInitialized
}
