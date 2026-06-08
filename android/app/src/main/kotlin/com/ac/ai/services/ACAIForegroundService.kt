package com.ac.ai.services

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.ac.ai.MainActivity
import com.ac.ai.R
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class ACAIForegroundService : Service() {
    companion object {
        private const val TAG = "ACAIForegroundService"
        private const val CHANNEL_ID = "ac_ai_foreground_channel"
        private const val NOTIFICATION_ID = 1001
        private const val WAKE_WORD_CHANNEL = "com.ac.ai/wakeword"
        
        const val ACTION_START = "com.ac.ai.action.START"
        const val ACTION_PAUSE = "com.ac.ai.action.PAUSE"
        const val ACTION_STOP = "com.ac.ai.action.STOP"
        const val ACTION_EMERGENCY_STOP = "com.ac.ai.action.EMERGENCY_STOP"
    }

    private var wakeWordService: WakeWordService? = null
    private var isRunning = false
    private var isPaused = false
    private lateinit var flutterEngine: FlutterEngine
    private lateinit var methodChannel: MethodChannel

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "AC AI Foreground Service created")
        createNotificationChannel()
        initializeServices()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> startService()
            ACTION_PAUSE -> pauseService()
            ACTION_STOP -> stopService()
            ACTION_EMERGENCY_STOP -> emergencyStop()
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "AC AI Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "AC AI Assistant Running"
                setSound(null, null)
                enableVibration(false)
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        val mainIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, mainIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val pauseIntent = Intent(this, ACAIForegroundService::class.java).apply {
            action = ACTION_PAUSE
        }
        val pausePendingIntent = PendingIntent.getService(
            this, 1, pauseIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val stopIntent = Intent(this, ACAIForegroundService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPendingIntent = PendingIntent.getService(
            this, 2, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val statusText = when {
            isPaused -> "Paused"
            isRunning -> "Listening..."
            else -> "Ready"
        }

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("AC AI Running")
            .setContentText(statusText)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .addAction(
                if (isPaused) R.drawable.ic_play else R.drawable.ic_pause,
                if (isPaused) "Resume" else "Pause",
                pausePendingIntent
            )
            .addAction(R.drawable.ic_stop, "Stop", stopPendingIntent)
            .build()
    }

    private fun initializeServices() {
        wakeWordService = WakeWordService(this).apply {
            onWakeWordDetected = { wakeWord ->
                onWakeWordTriggered(wakeWord)
            }
        }
    }

    private fun startService() {
        if (!isRunning) {
            isRunning = true
            isPaused = false
            
            val notification = createNotification()
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE or
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
            
            wakeWordService?.startListening()
            updateNotification()
            Log.d(TAG, "AC AI Service started")
        }
    }

    private fun pauseService() {
        if (isRunning) {
            isPaused = !isPaused
            
            if (isPaused) {
                wakeWordService?.stopListening()
                Log.d(TAG, "AC AI Service paused")
            } else {
                wakeWordService?.startListening()
                Log.d(TAG, "AC AI Service resumed")
            }
            
            updateNotification()
        }
    }

    private fun stopService() {
        isRunning = false
        isPaused = false
        
        wakeWordService?.stopListening()
        wakeWordService?.destroy()
        
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
        Log.d(TAG, "AC AI Service stopped")
    }

    private fun emergencyStop() {
        isRunning = false
        isPaused = false
        
        wakeWordService?.stopListening()
        wakeWordService?.destroy()
        
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
        Log.d(TAG, "AC AI Emergency Stop triggered")
    }

    private fun updateNotification() {
        val notification = createNotification()
        val notificationManager = getSystemService(NotificationManager::class.java)
        notificationManager.notify(NOTIFICATION_ID, notification)
    }

    private fun onWakeWordTriggered(wakeWord: String) {
        Log.d(TAG, "Wake word detected: $wakeWord")
        
        methodChannel.invokeMethod("onWakeWordDetected", mapOf(
            "wakeWord" to wakeWord,
            "timestamp" to System.currentTimeMillis()
        ))
        
        val vibrator = getSystemService(VIBRATOR_SERVICE) as android.os.Vibrator
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(android.os.VibrationEffect.createOneShot(100, android.os.VibrationEffect.DEFAULT_AMPLITUDE))
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(100)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        wakeWordService?.destroy()
    }
}
