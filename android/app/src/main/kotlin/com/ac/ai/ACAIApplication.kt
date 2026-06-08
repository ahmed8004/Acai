package com.ac.ai

import android.app.Application
import android.content.Context
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

class ACAIApplication : Application() {
    companion object {
        private const val TAG = "ACAIApplication"
        private const val ENGINE_ID = "ac_ai_engine"
        lateinit var instance: ACAIApplication
            private set
    }

    var cachedFlutterEngine: FlutterEngine? = null
        private set

    override fun onCreate() {
        super.onCreate()
        instance = this
        initializeFlutterEngine()
    }

    private fun initializeFlutterEngine() {
        cachedFlutterEngine = FlutterEngine(this).apply {
            navigationChannel.setInitialRoute("/")
            dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault()
            )
        }
        FlutterEngineCache.getInstance().put(ENGINE_ID, cachedFlutterEngine)
    }

    override fun attachBaseContext(base: Context?) {
        super.attachBaseContext(base)
    }
}
