package com.example.flutter_native_image_new

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Bitmap.CompressFormat
import android.graphics.BitmapFactory
import android.media.ExifInterface
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileNotFoundException
import java.io.FileOutputStream
import java.io.IOException
import java.io.OutputStream
import java.util.Locale
import androidx.core.graphics.scale
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch


/** FlutterNativeImageNewPlugin */
class FlutterNativeImageNewPlugin : FlutterPlugin, MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_native_image_new")
        context = flutterPluginBinding.applicationContext
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "getPlatformVersion") {
            result.success("Android ${android.os.Build.VERSION.RELEASE}")
        } else if (call.method.equals("compressImage")) {
            val dataMap: Map<*, *> = call.arguments as Map<*, *>
            println("dataMap $dataMap");

            val fileName: String = dataMap["file"] as String
            val resizePercentage: Int = dataMap["percentage"] as Int
            val targetWidth: Int = dataMap["targetWidth"] as Int
            val targetHeight: Int = dataMap["targetHeight"] as Int
            val quality: Int = dataMap["quality"] as Int

            val file = File(fileName)

            if (!file.exists()) {
                result.error("file does not exist", fileName, null)
                return
            }

            // var bmp = BitmapFactory.decodeFile(fileName)
            println("file.absolutePath: ${file.path}")
            var bmp = BitmapFactory.decodeFile(file.path)
            println("bmp: $bmp")

            if (bmp == null) {
                result.error("bmp null", fileName, null)
                return
            }
            val bos = ByteArrayOutputStream()

            val newWidth =
                if (targetWidth == 0) (bmp.width / 100 * resizePercentage) else targetWidth
            val newHeight =
                if (targetHeight == 0) (bmp.height / 100 * resizePercentage) else targetHeight

            bmp = bmp.scale(newWidth, newHeight)

            // reconfigure bitmap to use RGB_565 before compressing
            // fixes https://github.com/btastic/flutter_native_image/issues/47
            val newBmp = bmp.copy(Bitmap.Config.RGB_565, false)
            CoroutineScope(Dispatchers.IO).launch {
                newBmp.compress(CompressFormat.JPEG, quality, bos)
            }

            try {
                val outputFileName = File.createTempFile(
                    getFilenameWithoutExtension(file) + "_compressed",
                    ".jpg",
                    context.externalCacheDir
                ).path

                val outputStream: OutputStream = FileOutputStream(outputFileName)
                bos.writeTo(outputStream)

                copyExif(fileName, outputFileName)

                result.success(outputFileName)
            } catch (e: FileNotFoundException) {
                e.printStackTrace()
                result.error("file does not exist", fileName, null)
            } catch (e: IOException) {
                e.printStackTrace()
                result.error("something went wrong", fileName, null)
            }

            return
        } else if (call.method.equals("getImageProperties")) {
            val dataMap: Map<*, *> = call.arguments as Map<*, *>

            val fileName: String = dataMap["file"] as String
            val file = File(fileName)

            if (!file.exists()) {
                result.error("file does not exist", fileName, null)
                return
            }

            val options = BitmapFactory.Options()
            options.inJustDecodeBounds = true
            BitmapFactory.decodeFile(fileName, options)
            val properties = HashMap<String, Int>()
            properties["width"] = options.outWidth
            properties["height"] = options.outHeight

            var orientation = ExifInterface.ORIENTATION_UNDEFINED
            try {
                val exif = ExifInterface(fileName!!)
                orientation =
                    exif.getAttributeInt(
                        ExifInterface.TAG_ORIENTATION,
                        ExifInterface.ORIENTATION_UNDEFINED
                    )
            } catch (ex: IOException) {
                // EXIF could not be read from the file; ignore
            }
            properties["orientation"] = orientation

            result.success(properties)
            return
        } else if (call.method.equals("cropImage")) {
            val dataMap: Map<*, *> = call.arguments as Map<*, *>

            val fileName: String = dataMap["file"] as String
            val originX: Int = dataMap["originX"] as Int
            val originY: Int = dataMap["originY"] as Int
            val width: Int = dataMap["width"] as Int
            val height: Int = dataMap["height"] as Int

            val file = File(fileName)

            if (!file.exists()) {
                result.error("file does not exist", fileName, null)
                return
            }
            val isPNG = fileName.lowercase(Locale.getDefault()).endsWith(".png")
            val format = if (isPNG) CompressFormat.PNG else CompressFormat.JPEG
            val extension = if (isPNG) ".png" else ".jpg"

            var bmp = BitmapFactory.decodeFile(fileName)
            val bos = ByteArrayOutputStream()
            try {
                bmp = Bitmap.createBitmap(bmp, originX, originY, width, height)
            } catch (e: IllegalArgumentException) {
                e.printStackTrace()
                result.error(
                    "bounds are outside of the dimensions of the source image",
                    fileName,
                    null
                )
            }

            CoroutineScope(Dispatchers.IO).launch {
                bmp.compress(format, 100, bos)
            }
            bmp.recycle()
            var outputStream: OutputStream? = null
            try {
                val outputFileName = File.createTempFile(
                    getFilenameWithoutExtension(file) + "_cropped",
                    extension,
                    context.externalCacheDir
                ).path
                println("outputFileName: $outputFileName")


                outputStream = FileOutputStream(outputFileName)
                bos.writeTo(outputStream)

                copyExif(fileName, outputFileName)

                result.success(outputFileName)
            } catch (e: FileNotFoundException) {
                e.printStackTrace()
                result.error("file does not exist", fileName, null)
            } catch (e: IOException) {
                e.printStackTrace()
                result.error("something went wrong", fileName, null)
            } finally {
                if (outputStream != null) {
                    try {
                        outputStream.close()
                    } catch (e: IOException) {
                        e.printStackTrace()
                    }
                }
            }

            return
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private fun copyExif(filePathOri: String, filePathDest: String) {
        try {
            // Check if source file exists and is a supported format
            val sourceFile = File(filePathOri)
            val destFile = File(filePathDest)

            if (!sourceFile.exists()) {
                Log.w("NativeImagePluginNew", "Source file does not exist: $filePathOri")
                return
            }

            if (!destFile.exists()) {
                Log.w("NativeImagePluginNew", "Destination file does not exist: $filePathDest")
                return
            }

            // Check if files are supported formats (JPEG, WEBP, etc.)
            if (!isSupportedExifFormat(filePathOri) || !isSupportedExifFormat(filePathDest)) {
                Log.w("NativeImagePluginNew", "Unsupported format for EXIF data. Source: $filePathOri, Dest: $filePathDest")
                return
            }

            println("filePathOri: $filePathOri")
            println("filePathDest: $filePathDest")

            val oldExif = ExifInterface(filePathOri)
            val newExif = ExifInterface(filePathDest)

            val attributes = listOf(
                ExifInterface.TAG_F_NUMBER,
                ExifInterface.TAG_EXPOSURE_TIME,
                ExifInterface.TAG_ISO_SPEED_RATINGS,
                ExifInterface.TAG_GPS_ALTITUDE,
                ExifInterface.TAG_GPS_ALTITUDE_REF,
                ExifInterface.TAG_FOCAL_LENGTH,
                ExifInterface.TAG_GPS_DATESTAMP,
                ExifInterface.TAG_WHITE_BALANCE,
                ExifInterface.TAG_GPS_PROCESSING_METHOD,
                ExifInterface.TAG_GPS_TIMESTAMP,
                ExifInterface.TAG_DATETIME,
                ExifInterface.TAG_FLASH,
                ExifInterface.TAG_GPS_LATITUDE,
                ExifInterface.TAG_GPS_LATITUDE_REF,
                ExifInterface.TAG_GPS_LONGITUDE,
                ExifInterface.TAG_GPS_LONGITUDE_REF,
                ExifInterface.TAG_MAKE,
                ExifInterface.TAG_MODEL,
                ExifInterface.TAG_ORIENTATION
            )

            for (attribute in attributes) {
                setIfNotNull(oldExif, newExif, attribute)
            }

            newExif.saveAttributes()

        } catch (ex: IOException) {
            Log.e("NativeImagePluginNew", "IOException while copying EXIF data: ${ex.message}")
        } catch (ex: Exception) {
            Log.e("NativeImagePluginNew", "Error preserving EXIF data: ${ex.message}")
        }
    }

    private fun isSupportedExifFormat(filePath: String): Boolean {
        val extension = File(filePath).extension.lowercase()
        return when (extension) {
            "jpg", "jpeg", "webp", "dng", "cr2", "nef", "nrw", "arw", "rw2", "orf", "raf", "srw", "pef" -> true
            else -> false
        }
    }

    private fun setIfNotNull(oldExif: ExifInterface, newExif: ExifInterface, tag: String) {
        try {
            val value = oldExif.getAttribute(tag)
            if (value != null) {
                newExif.setAttribute(tag, value)
            }
        } catch (ex: Exception) {
            Log.w("NativeImagePluginNew", "Could not copy EXIF attribute $tag: ${ex.message}")
        }
    }

//    private fun copyExif(filePathOri: String, filePathDest: String) {
//        try {
//            val oldExif = ExifInterface(filePathOri)
//            val newExif = ExifInterface(filePathDest)
//
//            val attributes: List<String> = mutableListOf(
//                "FNumber",
//                "ExposureTime",
//                "ISOSpeedRatings",
//                "GPSAltitude",
//                "GPSAltitudeRef",
//                "FocalLength",
//                "GPSDateStamp",
//                "WhiteBalance",
//                "GPSProcessingMethod",
//                "GPSTimeStamp",
//                "DateTime",
//                "Flash",
//                "GPSLatitude",
//                "GPSLatitudeRef",
//                "GPSLongitude",
//                "GPSLongitudeRef",
//                "Make",
//                "Model",
//                "Orientation"
//            )
//            for (attribute in attributes) {
//                setIfNotNull(oldExif, newExif, attribute)
//            }
//
//            newExif.saveAttributes()
//        } catch (ex: Exception) {
//            Log.e(
//                "NativeImagePluginNew",
//                "Error preserving Exif data on selected image: $ex"
//            )
//        }
//    }
//
//    private fun setIfNotNull(oldExif: ExifInterface, newExif: ExifInterface, property: String) {
//        if (oldExif.getAttribute(property) != null) {
//            newExif.setAttribute(property, oldExif.getAttribute(property))
//        }
//    }

    private fun pathComponent(filename: String): String {
        val i = filename.lastIndexOf(File.separator)
        return if (i > -1) filename.substring(0, i) else filename
    }

    private fun getFilenameWithoutExtension(file: File): String {
        val fileName = file.name

        return if (fileName.indexOf(".") > 0) {
            fileName.substring(0, fileName.lastIndexOf("."))
        } else {
            fileName
        }
    }
}
