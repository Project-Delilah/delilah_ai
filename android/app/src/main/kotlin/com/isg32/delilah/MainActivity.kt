package com.isg32.delilah

import android.app.WallpaperManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.app.ActivityManager
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "delilah/wallpaper"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "setWallpaper") {
                val filePath = call.argument<String>("filePath")
                if (filePath != null) {
                    try {
                        val wallpaperManager = WallpaperManager.getInstance(applicationContext)
                        var bitmap = BitmapFactory.decodeFile(filePath)
                        
                        // Get screen dimensions
                        val windowManager = getSystemService(Context.WINDOW_SERVICE) as android.view.WindowManager
                        val display = windowManager.defaultDisplay
                        val screenWidth = display.width
                        val screenHeight = display.height
                        
                        // Center crop the bitmap to match screen aspect ratio
                        bitmap = centerCropBitmap(bitmap, screenWidth, screenHeight)
                        
                        // Set with FLAG_SYSTEM to ensure it shows properly on home screen
                        wallpaperManager.setBitmap(bitmap, null, true, WallpaperManager.FLAG_SYSTEM)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("WALLPAPER_ERROR", e.message, null)
                    }
                } else {
                    result.error("INVALID_ARGUMENT", "File path is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
    
    private fun centerCropBitmap(bitmap: Bitmap, targetWidth: Int, targetHeight: Int): Bitmap {
        val bitmapWidth = bitmap.width
        val bitmapHeight = bitmap.height
        
        val scale = maxOf(
            targetWidth.toFloat() / bitmapWidth,
            targetHeight.toFloat() / bitmapHeight
        )
        
        val scaledWidth = (bitmapWidth * scale).toInt()
        val scaledHeight = (bitmapHeight * scale).toInt()
        
        val scaledBitmap = Bitmap.createScaledBitmap(bitmap, scaledWidth, scaledHeight, true)
        
        val xOffset = (scaledWidth - targetWidth) / 2
        val yOffset = (scaledHeight - targetHeight) / 2
        
        return Bitmap.createBitmap(scaledBitmap, xOffset, yOffset, targetWidth, targetHeight)
    }
}