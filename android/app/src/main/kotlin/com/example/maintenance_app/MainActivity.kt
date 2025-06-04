package com.example.maintenance_app

import android.content.Intent
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import timber.log.Timber

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.maintenance_tracker/ar_viewer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "launchArViewer" -> {
                    val modelPath = call.argument<String>("modelPath")
                    Timber.tag("AR_MODEL").d("Received modelPath from Flutter: '$modelPath'")
                    launchArViewer(modelPath ?: "models/damaged_helmet.glb")
                    result.success("AR Viewer launched")
                }
                "checkArSupport" -> {
                    // Check if device supports ARCore
                    result.success(checkArCoreSupport())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun launchArViewer(modelPath: String) {
        Timber.tag("AR_MODEL").d("launchArViewer called with modelPath: '$modelPath'")
        val intent = Intent(this, ArModelViewerActivity::class.java)
        intent.putExtra("model_file", modelPath)
        startActivity(intent)
    }

    private fun checkArCoreSupport(): Boolean {
        return try {
            // Check if ARCore is supported on this device
            val availability = com.google.ar.core.ArCoreApk.getInstance().checkAvailability(this)
            availability.isSupported
        } catch (e: Exception) {
            false
        }
    }
}