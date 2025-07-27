import SwiftUI
import Photos
import CoreLocation
import ImageIO
import MobileCoreServices

// MARK: - Enhanced Photo Metadata Structures

struct PhotoMetadata {
    let resolution: CGSize
    let focalLength: String?
    let iso: String?
    let exposureTime: String?
    let flash: String
    let fileSize: String
    let fileFormat: String
}

struct PhotoBasicInfo {
    let label: String
    let description: String
    let capturedOn: Date
    let compositionStyle: String
    let compositionHint: String
    let framingEvaluation: String
    let cameraUsed: String
    let location: String?
}

class PhotoManager: ObservableObject {
    @Published var capturedPhotos: [CapturedPhoto] = []
    
    private let photosDirectory: URL = {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let photosDir = documentsPath.appendingPathComponent("CapturedPhotos")
        
        // Create directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: photosDir.path) {
            try? FileManager.default.createDirectory(at: photosDir, withIntermediateDirectories: true, attributes: nil)
        }
        
        return photosDir
    }()
    
    init() {
        loadPhotos()
        requestPhotoLibraryPermission()
    }
    
    func savePhoto(_ image: UIImage, compositionType: String = "Rule of Thirds", compositionScore: Double = 0.8) {
        let photoId = UUID().uuidString
        let fileName = "\(photoId).jpg"
        let fileURL = photosDirectory.appendingPathComponent(fileName)
        
        // Convert image to JPEG data with metadata preservation
        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            print("❌ Failed to convert image to JPEG data")
            return
        }
        
        do {
            // Save to documents directory
            try imageData.write(to: fileURL)
            
            // Extract metadata from image
            let metadata = extractMetadata(from: imageData, fileURL: fileURL)
            let basicInfo = generateBasicInfo(compositionType: compositionType, compositionScore: compositionScore)
            
            // Create captured photo object with enhanced metadata
            let capturedPhoto = CapturedPhoto(
                id: photoId,
                fileName: fileName,
                fileURL: fileURL,
                dateCaptured: Date(),
                image: image,
                metadata: metadata,
                basicInfo: basicInfo
            )
            
            // Add to array (newest first)
            DispatchQueue.main.async {
                self.capturedPhotos.insert(capturedPhoto, at: 0)
            }
            
            print("✅ Photo saved successfully: \(fileName)")
            
            // Also save to photo library if permission granted
            saveToPhotoLibrary(image)
            
        } catch {
            print("❌ Failed to save photo: \(error)")
        }
    }
    
    private func extractMetadata(from imageData: Data, fileURL: URL) -> PhotoMetadata {
        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
              let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] else {
            return createDefaultMetadata(fileURL: fileURL)
        }
        
        // Get basic image info
        let pixelWidth = imageProperties[kCGImagePropertyPixelWidth as String] as? Int ?? 0
        let pixelHeight = imageProperties[kCGImagePropertyPixelHeight as String] as? Int ?? 0
        let resolution = CGSize(width: pixelWidth, height: pixelHeight)
        
        // Get EXIF data if available
        let exifDict = imageProperties[kCGImagePropertyExifDictionary as String] as? [String: Any]
        
        // Extract camera settings
        let focalLength = extractFocalLength(from: exifDict)
        let iso = extractISO(from: exifDict)
        let exposureTime = extractExposureTime(from: exifDict)
        let flash = extractFlashInfo(from: exifDict)
        
        // Calculate file size
        let fileSize = formatFileSize(fileURL: fileURL)
        
        return PhotoMetadata(
            resolution: resolution,
            focalLength: focalLength,
            iso: iso,
            exposureTime: exposureTime,
            flash: flash,
            fileSize: fileSize,
            fileFormat: "JPEG"
        )
    }
    
    private func createDefaultMetadata(fileURL: URL) -> PhotoMetadata {
        return PhotoMetadata(
            resolution: CGSize(width: 3024, height: 4032), // Default iPhone resolution
            focalLength: "26mm (wide angle)",
            iso: nil,
            exposureTime: nil,
            flash: "Off",
            fileSize: formatFileSize(fileURL: fileURL),
            fileFormat: "JPEG"
        )
    }
    
    private func extractFocalLength(from exifDict: [String: Any]?) -> String? {
        guard let exif = exifDict,
              let focalLength = exif[kCGImagePropertyExifFocalLength as String] as? Double else {
            return "26mm (wide angle)" // Default for iPhone wide camera
        }
        
        let focalLengthMM = Int(focalLength)
        if focalLengthMM <= 15 {
            return "\(focalLengthMM)mm (ultra wide)"
        } else if focalLengthMM <= 30 {
            return "\(focalLengthMM)mm (wide angle)"
        } else {
            return "\(focalLengthMM)mm (telephoto)"
        }
    }
    
    private func extractISO(from exifDict: [String: Any]?) -> String? {
        guard let exif = exifDict,
              let iso = exif[kCGImagePropertyExifISOSpeedRatings as String] as? [Int],
              let isoValue = iso.first else {
            return nil
        }
        return "ISO \(isoValue)"
    }
    
    private func extractExposureTime(from exifDict: [String: Any]?) -> String? {
        guard let exif = exifDict,
              let exposureTime = exif[kCGImagePropertyExifExposureTime as String] as? Double else {
            return nil
        }
        
        if exposureTime < 1.0 {
            let denominator = Int(1.0 / exposureTime)
            return "1/\(denominator) sec"
        } else {
            return String(format: "%.1f sec", exposureTime)
        }
    }
    
    private func extractFlashInfo(from exifDict: [String: Any]?) -> String {
        guard let exif = exifDict,
              let flash = exif[kCGImagePropertyExifFlash as String] as? Int else {
            return "Off"
        }
        
        switch flash {
        case 0: return "Off"
        case 1: return "Fired"
        case 5: return "Fired (no return detected)"
        case 7: return "Fired (return detected)"
        case 9: return "Auto – Fired"
        case 13: return "Auto – Fired (no return)"
        case 15: return "Auto – Fired (return detected)"
        case 16: return "Off (compulsory)"
        case 24: return "Auto – Off"
        case 25: return "Auto – Fired (red-eye reduction)"
        default: return "Unknown"
        }
    }
    
    private func formatFileSize(fileURL: URL) -> String {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            if let fileSize = attributes[.size] as? Int64 {
                let formatter = ByteCountFormatter()
                formatter.allowedUnits = [.useMB, .useKB]
                formatter.countStyle = .file
                return formatter.string(fromByteCount: fileSize)
            }
        } catch {
            print("❌ Failed to get file size: \(error)")
        }
        return "Unknown"
    }
    
    private func generateBasicInfo(compositionType: String, compositionScore: Double) -> PhotoBasicInfo {
        let compositionHints = [
            "Rule of Thirds": "Subject aligned on intersection points",
            "Center Framing": "Subject positioned in center frame",
            "Symmetry": "Balanced composition with symmetrical elements"
        ]
        
        let framingEvaluations = [
            "Excellent framing! Perfect composition alignment.",
            "Great framing! Well-positioned subject.",
            "Good framing with room for improvement.",
            "Consider repositioning for better composition."
        ]
        
        let evaluation = compositionScore >= 0.8 ? framingEvaluations[0] :
                        compositionScore >= 0.6 ? framingEvaluations[1] :
                        compositionScore >= 0.4 ? framingEvaluations[2] : framingEvaluations[3]
        
        return PhotoBasicInfo(
            label: "Photo",
            description: "Klick composition analysis",
            capturedOn: Date(),
            compositionStyle: compositionType,
            compositionHint: compositionHints[compositionType] ?? "Creative composition style",
            framingEvaluation: evaluation,
            cameraUsed: "Rear Camera – Wide",
            location: nil // TODO: Implement location if needed
        )
    }
    
    private func saveToPhotoLibrary(_ image: UIImage) {
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .authorized, .limited:
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, error in
                if success {
                    print("✅ Photo saved to photo library")
                } else if let error = error {
                    print("❌ Failed to save to photo library: \(error)")
                }
            }
        case .denied, .restricted:
            print("⚠️ Photo library access denied")
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    self.saveToPhotoLibrary(image)
                }
            }
        @unknown default:
            print("❓ Unknown photo library authorization status")
        }
    }
    
    private func loadPhotos() {
        guard FileManager.default.fileExists(atPath: photosDirectory.path) else {
            return
        }
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: photosDirectory, includingPropertiesForKeys: [.creationDateKey], options: [])
            
            let photoFiles = fileURLs.filter { $0.pathExtension.lowercased() == "jpg" }
            
            var loadedPhotos: [CapturedPhoto] = []
            
            for fileURL in photoFiles {
                let fileName = fileURL.lastPathComponent
                let photoId = String(fileName.dropLast(4)) // Remove .jpg extension
                
                // Get creation date
                let resourceValues = try fileURL.resourceValues(forKeys: [.creationDateKey])
                let dateCaptured = resourceValues.creationDate ?? Date()
                
                // Load image
                if let imageData = try? Data(contentsOf: fileURL),
                   let image = UIImage(data: imageData) {
                    
                    // Extract metadata for existing photos
                    let metadata = extractMetadata(from: imageData, fileURL: fileURL)
                    let basicInfo = generateBasicInfo(compositionType: "Rule of Thirds", compositionScore: 0.7)
                    
                    let capturedPhoto = CapturedPhoto(
                        id: photoId,
                        fileName: fileName,
                        fileURL: fileURL,
                        dateCaptured: dateCaptured,
                        image: image,
                        metadata: metadata,
                        basicInfo: basicInfo
                    )
                    
                    loadedPhotos.append(capturedPhoto)
                }
            }
            
            // Sort by date (newest first)
            loadedPhotos.sort { $0.dateCaptured > $1.dateCaptured }
            
            DispatchQueue.main.async {
                self.capturedPhotos = loadedPhotos
                print("✅ Loaded \(loadedPhotos.count) photos from storage")
            }
            
        } catch {
            print("❌ Failed to load photos: \(error)")
        }
    }
    
    func deletePhoto(_ photo: CapturedPhoto) {
        do {
            try FileManager.default.removeItem(at: photo.fileURL)
            
            DispatchQueue.main.async {
                self.capturedPhotos.removeAll { $0.id == photo.id }
            }
            
            print("✅ Photo deleted: \(photo.fileName)")
        } catch {
            print("❌ Failed to delete photo: \(error)")
        }
    }
    
    func requestPhotoLibraryPermission() {
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized:
                print("✅ Photo library access granted")
            case .limited:
                print("⚠️ Photo library access limited")
            case .denied, .restricted:
                print("❌ Photo library access denied")
            case .notDetermined:
                print("❓ Photo library access not determined")
            @unknown default:
                print("❓ Unknown photo library authorization status")
            }
        }
    }
}

struct CapturedPhoto: Identifiable, Equatable {
    let id: String
    let fileName: String
    let fileURL: URL
    let dateCaptured: Date
    let image: UIImage
    let metadata: PhotoMetadata
    let basicInfo: PhotoBasicInfo
    
    static func == (lhs: CapturedPhoto, rhs: CapturedPhoto) -> Bool {
        return lhs.id == rhs.id
    }
} 
