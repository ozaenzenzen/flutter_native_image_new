import Flutter
import UIKit
import UniformTypeIdentifiers

public class FlutterNativeImageNewPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_native_image_new", binaryMessenger: registrar.messenger())
        let instance = FlutterNativeImageNewPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        case "compressImage1":
            guard let dataMap = call.arguments as? [String: Any] else {
                result("Invalid arguments")
                return
            }
            
            guard let fileName = dataMap["file"] as? String else {
                result("file parameter missing or invalid")
                return
            }
            
            guard let resizePercentage = dataMap["percentage"] as? Int,
                  let targetWidth = dataMap["targetWidth"] as? Int,
                  let targetHeight = dataMap["targetHeight"] as? Int,
                  let quality = dataMap["quality"] as? Int else {
                result("Missing or invalid parameters")
                return
            }
            
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: fileName) {
                result(fileName)
                return
            }
            
            guard var image = UIImage(contentsOfFile: fileName) else {
                result("Failed to load image")
                return
            }
            
            let newWidth = targetWidth == 0 ? Int(image.size.width) * resizePercentage / 100 : targetWidth
            let newHeight = targetHeight == 0 ? Int(image.size.height) * resizePercentage / 100 : targetHeight
            
            // Scale the image
            let newSize = CGSize(width: newWidth, height: newHeight)
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            if let scaledImage = UIGraphicsGetImageFromCurrentImageContext() {
                image = scaledImage
            }
            UIGraphicsEndImageContext()
            
            // Compress the image
            guard let imageData = image.jpegData(compressionQuality: CGFloat(quality) / 100.0) else {
                result("Failed to compress image")
                return
            }
            
            do {
                let tempDirectory = FileManager.default.temporaryDirectory
                let originalFileName = URL(fileURLWithPath: fileName).deletingPathExtension().lastPathComponent
                let outputFileName = tempDirectory.appendingPathComponent("\(originalFileName)_compressed.jpg")
                
                try imageData.write(to: outputFileName)
                
                // Note: EXIF handling would need additional implementation in Swift
                // copyExif(fileName, outputFileName.path)
                
                result(outputFileName.path)
            } catch let error as NSError {
                print(error.localizedDescription)
                if error.domain == NSCocoaErrorDomain && error.code == 4 {
                    result("file does not exist")
                } else {
                    result("something went wrong")
                }
            }
        case "compressImage":
            guard let dataMap = call.arguments as? [String: Any],
                  let fileName = dataMap["file"] as? String,
                  let resizePercentage = dataMap["percentage"] as? Int,
                  let targetWidth = dataMap["targetWidth"] as? Int,
                  let targetHeight = dataMap["targetHeight"] as? Int,
                  let quality = dataMap["quality"] as? Int else {
                result(FlutterError(code: "invalid_arguments", message: "Missing or invalid arguments", details: nil))
                return
            }
            
            let fileUrl = URL(fileURLWithPath: fileName)
            
            guard FileManager.default.fileExists(atPath: fileUrl.path) else {
                result(FlutterError(code: "file_does_not_exist", message: fileName, details: nil))
                return
            }
            
            guard let originalImage = UIImage(contentsOfFile: fileUrl.path) else {
                result(FlutterError(code: "invalid_image", message: "Failed to load image", details: nil))
                return
            }
            
            // Calculate new dimensions
            let newWidth = targetWidth == 0 ? Int(CGFloat(originalImage.size.width) * CGFloat(resizePercentage) / 100.0) : targetWidth
            let newHeight = targetHeight == 0 ? Int(CGFloat(originalImage.size.height) * CGFloat(resizePercentage) / 100.0) : targetHeight
            
            // Resize image
            UIGraphicsBeginImageContextWithOptions(CGSize(width: newWidth, height: newHeight), false, 1.0)
            originalImage.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            guard let finalImage = resizedImage else {
                result(FlutterError(code: "resize_failed", message: "Could not resize image", details: nil))
                return
            }
            
            // Compress image
            guard let imageData = finalImage.jpegData(compressionQuality: CGFloat(quality) / 100.0) else {
                result(FlutterError(code: "compression_failed", message: "Failed to compress image", details: nil))
                return
            }
            
            // Save to temp file
            do {
                let tempDir = FileManager.default.temporaryDirectory
                let outputFileName = tempDir.appendingPathComponent("\((fileUrl.deletingPathExtension().lastPathComponent))_compressed.jpg")
                
                try imageData.write(to: outputFileName)
                
                // You can implement copyExif if needed, or skip it
                // copyExif(from: fileUrl.path, to: outputFileName.path)
                
                result(outputFileName.path)
            } catch {
                result(FlutterError(code: "io_error", message: error.localizedDescription, details: nil))
            }
        case "cropImage":
            guard let dataMap = call.arguments as? [String: Any],
                  let fileName = dataMap["file"] as? String,
                  let originX = dataMap["originX"] as? Int,
                  let originY = dataMap["originY"] as? Int,
                  let width = dataMap["width"] as? Int,
                  let height = dataMap["height"] as? Int else {
                result(FlutterError(code: "invalid_arguments", message: "Missing or invalid arguments", details: nil))
                return
            }

            let fileUrl = URL(fileURLWithPath: fileName)

            guard FileManager.default.fileExists(atPath: fileUrl.path) else {
                result(FlutterError(code: "file_does_not_exist", message: fileName, details: nil))
                return
            }

            let isPNG = fileName.lowercased().hasSuffix(".png")
            let fileExtension = isPNG ? ".png" : ".jpg"

            // Load the original image
            guard let originalImage = UIImage(contentsOfFile: fileUrl.path),
                  let cgImage = originalImage.cgImage else {
                result(FlutterError(code: "load_failed", message: "Failed to load image", details: nil))
                return
            }

            // Ensure crop bounds are valid
            guard originX >= 0, originY >= 0,
                  originX + width <= cgImage.width,
                  originY + height <= cgImage.height else {
                result(FlutterError(code: "crop_bounds_invalid", message: "Crop bounds are outside source image", details: nil))
                return
            }

            // Crop the image
            guard let croppedCGImage = cgImage.cropping(to: CGRect(x: originX, y: originY, width: width, height: height)) else {
                result(FlutterError(code: "crop_failed", message: "Failed to crop image", details: nil))
                return
            }

            let croppedImage = UIImage(cgImage: croppedCGImage)

            // Save to temporary file in background
            DispatchQueue.global(qos: .userInitiated).async {
                guard let imageData = isPNG
                        ? croppedImage.pngData()
                        : croppedImage.jpegData(compressionQuality: 1.0) else {
                    result(FlutterError(code: "compression_failed", message: "Failed to compress image", details: nil))
                    return
                }

                let tempDir = FileManager.default.temporaryDirectory
                let baseName = fileUrl.deletingPathExtension().lastPathComponent
                let outputFileName = "\(baseName)_cropped\(fileExtension)"
                let outputFileURL = tempDir.appendingPathComponent(outputFileName)

                do {
                    try imageData.write(to: outputFileURL)

                    // Optional: Copy EXIF data (implement if needed)
                    // copyExif(from: fileUrl.path, to: outputFileURL.path)

                    result(outputFileURL.path)
                } catch {
                    result(FlutterError(code: "file_write_error", message: error.localizedDescription, details: nil))
                }
            }

        case "getImageProperties":
            guard let dataMap = call.arguments as? [String: Any],
                  let fileName = dataMap["file"] as? String, !fileName.isEmpty else {
                result(FlutterError(code: "invalid_arguments", message: "Missing or invalid 'file' argument", details: nil))
                return
            }
            
            let fileUrl = URL(fileURLWithPath: fileName)
            
            guard FileManager.default.fileExists(atPath: fileUrl.path) else {
                result(FlutterError(code: "file_does_not_exist", message: fileName, details: nil))
                return
            }
            
            guard let imageSource = CGImageSourceCreateWithURL(fileUrl as CFURL, nil),
                  let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any] else {
                result(FlutterError(code: "image_read_error", message: "Unable to read image metadata", details: nil))
                return
            }
            
            var resultMap: [String: Int] = [:]
            
            // Extract width and height
            if let width = properties[kCGImagePropertyPixelWidth] as? Int {
                resultMap["width"] = width
            }
            if let height = properties[kCGImagePropertyPixelHeight] as? Int {
                resultMap["height"] = height
            }
            
            // Extract orientation
            let orientation = properties[kCGImagePropertyOrientation] as? Int ?? -1
            resultMap["orientation"] = orientation
            
            result(resultMap)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
