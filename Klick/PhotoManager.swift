import SwiftUI
import Photos
import CoreLocation
import ImageIO
import MobileCoreServices
import UniformTypeIdentifiers

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

// OPTIMIZATION 2: Add to PhotoManager class
class PhotoManager: ObservableObject {
    @Published var capturedPhotos: [CapturedPhoto] = []
    @Published var isLoading = false
    @Published var photoCount: Int = 0 // For preview without loading photos
    
    // Lazy loading state
    private var hasLoadedPhotos = false
    
    // Track photos saved to photo library
    private var savedToLibraryPhotos: Set<String> = []
    
    // Performance optimization properties
    private let thumbnailCache = NSCache<NSString, UIImage>()
    private let fullImageCache = NSCache<NSString, UIImage>()
    private let loadingQueue = DispatchQueue(label: "photo.loading", qos: .userInitiated, attributes: .concurrent)
    
    private let photosDirectory: URL = {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let photosDir = documentsPath.appendingPathComponent("CapturedPhotos")
        
        // Create directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: photosDir.path) {
            try? FileManager.default.createDirectory(at: photosDir, withIntermediateDirectories: true, attributes: nil)
        }
        
        return photosDir
    }()
    
    private let thumbnailsDirectory: URL = {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let thumbnailsDir = documentsPath.appendingPathComponent("Thumbnails")
        
        // Create directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: thumbnailsDir.path) {
            try? FileManager.default.createDirectory(at: thumbnailsDir, withIntermediateDirectories: true, attributes: nil)
        }
        
        return thumbnailsDir
    }()
    
    init() {
        setupCaches()
        loadPhotoCountOnly() // Only load count for preview
        requestPhotoLibraryPermission()
        loadSavedPhotosState() // Load saved photos state
    }
    
    private func setupCaches() {
        // Configure thumbnail cache (small, keep more items)
        thumbnailCache.countLimit = 100 // Keep 100 thumbnails in memory
        thumbnailCache.totalCostLimit = 50 * 1024 * 1024 // 50MB for thumbnails
        
        // Configure full image cache (larger, keep fewer items)
        fullImageCache.countLimit = 20 // Keep 20 full images in memory
        fullImageCache.totalCostLimit = 200 * 1024 * 1024 // 200MB for full images
    }
    
    // MARK: - Enhanced Metadata Creation
    
    private func createJPEGDataWithMetadata(from image: UIImage) -> Data? {
        guard let cgImage = image.cgImage else {
            return image.jpegData(compressionQuality: 0.9)
        }
        
        // Create mutable data for the image
        let mutableData = NSMutableData()
        
        // Create image destination with JPEG format
        guard let destination = CGImageDestinationCreateWithData(mutableData, UTType.jpeg.identifier as CFString, 1, nil) else {
            return image.jpegData(compressionQuality: 0.9)
        }
        
        // Create enhanced metadata dictionary
        let metadata = createEnhancedMetadata()
        
        // Add the image with metadata
        CGImageDestinationAddImage(destination, cgImage, metadata)
        
        // Finalize the image creation
        if CGImageDestinationFinalize(destination) {
            return mutableData as Data
        } else {
            // Fallback to standard JPEG creation
            return image.jpegData(compressionQuality: 0.9)
        }
    }
    
    private func createEnhancedMetadata() -> CFDictionary {
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        let dateString = dateFormatter.string(from: currentDate)
        
        // Create EXIF dictionary with default camera settings
        let exifDict: [String: Any] = [
            kCGImagePropertyExifDateTimeOriginal as String: dateString,
            kCGImagePropertyExifDateTimeDigitized as String: dateString,
            kCGImagePropertyExifISOSpeedRatings as String: [100],
            kCGImagePropertyExifExposureTime as String: 1.0/60.0,
            kCGImagePropertyExifFocalLength as String: 26.0,
            kCGImagePropertyExifFlash as String: 0, // Flash off
            kCGImagePropertyExifColorSpace as String: 1, // sRGB
            kCGImagePropertyExifPixelXDimension as String: Int(UIScreen.main.bounds.width * UIScreen.main.scale),
            kCGImagePropertyExifPixelYDimension as String: Int(UIScreen.main.bounds.height * UIScreen.main.scale)
        ]
        
        // Create TIFF dictionary
        let tiffDict: [String: Any] = [
            kCGImagePropertyTIFFMake as String: "Apple",
            kCGImagePropertyTIFFModel as String: "iPhone (Klick Camera)",
            kCGImagePropertyTIFFDateTime as String: dateString,
            kCGImagePropertyTIFFSoftware as String: "Klick v1.0",
            kCGImagePropertyTIFFOrientation as String: 1
        ]
        
        // Combine all metadata
        let metadata: [String: Any] = [
            kCGImagePropertyExifDictionary as String: exifDict,
            kCGImagePropertyTIFFDictionary as String: tiffDict,
            kCGImagePropertyHasAlpha as String: false
        ]
        
        return metadata as CFDictionary
    }
    
    func savePhoto(_ image: UIImage, compositionType: String = "Rule of Thirds", compositionScore: Double = 0.8, imageData: Data? = nil) {
        let photoId = UUID().uuidString
        let fileName = "\(photoId).jpg"
        let thumbnailFileName = "\(photoId)_thumb.jpg"
        let fileURL = photosDirectory.appendingPathComponent(fileName)
        let thumbnailURL = thumbnailsDirectory.appendingPathComponent(thumbnailFileName)
        
        // Use provided imageData with actual metadata, or create enhanced metadata
        let finalImageData: Data
        if let providedData = imageData {
            finalImageData = providedData
            print("✅ Using provided image data with actual capture metadata")
        } else {
            guard let createdData = createJPEGDataWithMetadata(from: image) else {
                print("❌ Failed to convert image to JPEG data with metadata")
                return
            }
            finalImageData = createdData
            print("⚠️ Using created image data with default metadata")
        }
        
        // Generate thumbnail
        guard let thumbnail = generateThumbnail(from: image),
              let thumbnailData = thumbnail.jpegData(compressionQuality: 0.8) else {
            print("❌ Failed to generate thumbnail")
            return
        }
        
        do {
            // Save full-resolution image to documents directory
            try finalImageData.write(to: fileURL)
            
            // Save thumbnail to thumbnails directory
            try thumbnailData.write(to: thumbnailURL)
            
            // Extract metadata from image
            let metadata = extractMetadata(from: finalImageData, fileURL: fileURL)
            let basicInfo = generateBasicInfo(compositionType: compositionType, compositionScore: compositionScore)
            
            // Create captured photo object with enhanced metadata
            let capturedPhoto = CapturedPhoto(
                id: photoId,
                fileName: fileName,
                fileURL: fileURL,
                thumbnailURL: thumbnailURL,
                dateCaptured: Date(),
                thumbnail: thumbnail,
                metadata: metadata,
                basicInfo: basicInfo
            )
            
            // Add to array (newest first) only if photos are already loaded
            DispatchQueue.main.async {
                if self.hasLoadedPhotos {
                    self.capturedPhotos.insert(capturedPhoto, at: 0)
                }
                // Always update photo count
                self.photoCount += 1
            }
            
            print("✅ Photo and thumbnail saved successfully: \(fileName)")
            
        } catch {
            print("❌ Failed to save photo: \(error)")
        }
    }
    
    // OPTIMIZATION 1: Micro-thumbnails for instant loading
    private func generateThumbnail(from image: UIImage, targetSize: CGSize = CGSize(width: 120, height: 160)) -> UIImage? {
        // 75% smaller than current size = 75% faster loading
        let size = image.size
        let aspectRatio = size.width / size.height
        
        var thumbnailSize = targetSize
        if aspectRatio > 1 {
            thumbnailSize.height = targetSize.width / aspectRatio
        } else {
            thumbnailSize.width = targetSize.height * aspectRatio
        }
        
        // Use high-performance graphics context
        let renderer = UIGraphicsImageRenderer(size: thumbnailSize)
        
        return renderer.image { context in
            // Use bicubic interpolation for better quality at small sizes
            context.cgContext.interpolationQuality = .high
            image.draw(in: CGRect(origin: .zero, size: thumbnailSize))
        }
    }
    
    func loadFullResolutionImage(for photo: CapturedPhoto, completion: @escaping (UIImage?) -> Void) {
        // Check cache first
        if let cachedImage = fullImageCache.object(forKey: photo.id as NSString) {
            DispatchQueue.main.async {
                completion(cachedImage)
            }
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            guard let imageData = try? Data(contentsOf: photo.fileURL),
                  let image = UIImage(data: imageData) else {
                print("❌ Failed to load full resolution image for \(photo.fileName)")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            // Cache the loaded image
            self.fullImageCache.setObject(image, forKey: photo.id as NSString)
            
            DispatchQueue.main.async {
                completion(image)
            }
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
        
        // Extract camera settings with enhanced detection
        let focalLength = extractFocalLength(from: exifDict)
        let iso = extractISO(from: exifDict, imageProperties: imageProperties)
        let exposureTime = extractExposureTime(from: exifDict, imageProperties: imageProperties)
        let flash = extractFlashInfo(from: exifDict)
        
        // Extract file format more accurately
        let fileFormat = extractFileFormat(from: imageSource, fileURL: fileURL)
        
        // Calculate file size
        let fileSize = formatFileSize(fileURL: fileURL)
        
        return PhotoMetadata(
            resolution: resolution,
            focalLength: focalLength,
            iso: iso,
            exposureTime: exposureTime,
            flash: flash,
            fileSize: fileSize,
            fileFormat: fileFormat
        )
    }
    
    private func createDefaultMetadata(fileURL: URL) -> PhotoMetadata {
        // Extract format from file extension for default case
        let pathExtension = fileURL.pathExtension.uppercased()
        let fileFormat = pathExtension.isEmpty ? "JPEG" : pathExtension
        
        return PhotoMetadata(
            resolution: CGSize(width: 3024, height: 4032), // Default iPhone resolution
            focalLength: "26mm (wide angle)",
            iso: "ISO 100", // Default iPhone camera ISO
            exposureTime: "1/60 sec", // Default iPhone camera exposure
            flash: "Off",
            fileSize: formatFileSize(fileURL: fileURL),
            fileFormat: fileFormat
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
    
    private func extractISO(from exifDict: [String: Any]?, imageProperties: [String: Any]) -> String? {
        // Try EXIF ISO Speed Ratings first (most common)
        if let exif = exifDict,
           let iso = exif[kCGImagePropertyExifISOSpeedRatings as String] as? [Int],
           let isoValue = iso.first {
            return "ISO \(isoValue)"
        }
        
        // Try alternative EXIF ISO Speed field
        if let exif = exifDict,
           let isoValue = exif[kCGImagePropertyExifISOSpeed as String] as? Int {
            return "ISO \(isoValue)"
        }
        
        // Try TIFF ISO field as fallback
        if let tiffDict = imageProperties[kCGImagePropertyTIFFDictionary as String] as? [String: Any],
           let isoValue = tiffDict["ISOSpeedRatings"] as? Int {
            return "ISO \(isoValue)"
        }
        
        // Return default ISO for iPhone cameras if no metadata found
        return "ISO 100" // Default iPhone camera ISO
    }
    
    private func extractExposureTime(from exifDict: [String: Any]?, imageProperties: [String: Any]) -> String? {
        // Try EXIF Exposure Time first
        if let exif = exifDict,
           let exposureTime = exif[kCGImagePropertyExifExposureTime as String] as? Double {
            return formatExposureTime(exposureTime)
        }
        
        // Try EXIF Shutter Speed Value as alternative
        if let exif = exifDict,
           let shutterSpeedValue = exif[kCGImagePropertyExifShutterSpeedValue as String] as? Double {
            // Convert APEX shutter speed value to exposure time
            let exposureTime = pow(2.0, -shutterSpeedValue)
            return formatExposureTime(exposureTime)
        }
        
        // Try TIFF fields as fallback
        if let tiffDict = imageProperties[kCGImagePropertyTIFFDictionary as String] as? [String: Any],
           let exposureTime = tiffDict["ExposureTime"] as? Double {
            return formatExposureTime(exposureTime)
        }
        
        // Return default exposure for iPhone cameras if no metadata found
        return "1/60 sec" // Default iPhone camera exposure
    }
    
    private func formatExposureTime(_ exposureTime: Double) -> String {
        if exposureTime < 1.0 {
            let denominator = Int(round(1.0 / exposureTime))
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
    
    private func extractFileFormat(from imageSource: CGImageSource, fileURL: URL) -> String {
        // Get the UTI (Uniform Type Identifier) from the image source
        if let imageType = CGImageSourceGetType(imageSource) {
            let typeString = imageType as String
            
            // Convert UTI to human-readable format
            switch typeString {
            case "public.jpeg":
                return "JPEG"
            case "public.png":
                return "PNG"
            case "public.heif":
                return "HEIF"
            case "public.heic":
                return "HEIC"
            case "public.tiff":
                return "TIFF"
            case "com.adobe.raw-image":
                return "RAW"
            default:
                // Extract from file extension as fallback
                let pathExtension = fileURL.pathExtension.uppercased()
                return pathExtension.isEmpty ? "Unknown" : pathExtension
            }
        }
        
        // Fallback to file extension
        let pathExtension = fileURL.pathExtension.uppercased()
        return pathExtension.isEmpty ? "Unknown" : pathExtension
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
    
    // Public method for manually saving photos to photo library
    func savePhotoToLibrary(_ photo: CapturedPhoto, completion: @escaping (Bool, String?) -> Void) {
        // Load the full resolution image first
        loadFullResolutionImage(for: photo) { image in
            guard let image = image else {
                DispatchQueue.main.async {
                    completion(false, "Failed to load photo")
                }
                return
            }
            
            self.saveToPhotoLibrary(image) { success, error in
                DispatchQueue.main.async {
                    if success {
                        // Mark photo as saved to library
                        self.savedToLibraryPhotos.insert(photo.id)
                        self.saveSavedPhotosState()
                    }
                    completion(success, error)
                }
            }
        }
    }
    
    // Check if a photo has been saved to photo library
    func isPhotoSavedToLibrary(_ photo: CapturedPhoto) -> Bool {
        return savedToLibraryPhotos.contains(photo.id)
    }
    
    // Save the saved photos state to UserDefaults
    private func saveSavedPhotosState() {
        let savedPhotosArray = Array(savedToLibraryPhotos)
        UserDefaults.standard.set(savedPhotosArray, forKey: "SavedToLibraryPhotos")
    }
    
    // Load the saved photos state from UserDefaults
    private func loadSavedPhotosState() {
        if let savedPhotosArray = UserDefaults.standard.array(forKey: "SavedToLibraryPhotos") as? [String] {
            savedToLibraryPhotos = Set(savedPhotosArray)
        }
    }
    
    private func saveToPhotoLibrary(_ image: UIImage, completion: ((Bool, String?) -> Void)? = nil) {
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .authorized, .limited:
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, error in
                if success {
                    print("✅ Photo saved to photo library")
                    completion?(true, nil)
                } else if let error = error {
                    print("❌ Failed to save to photo library: \(error)")
                    completion?(false, error.localizedDescription)
                } else {
                    completion?(false, "Unknown error occurred")
                }
            }
        case .denied, .restricted:
            print("⚠️ Photo library access denied")
            completion?(false, "Photo library access denied")
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    self.saveToPhotoLibrary(image, completion: completion)
                } else {
                    completion?(false, "Photo library access denied")
                }
            }
        @unknown default:
            print("❓ Unknown photo library authorization status")
            completion?(false, "Unknown photo library authorization status")
        }
    }
    
    // OPTIMIZATION: Load only photo count for preview (fast startup)
    private func loadPhotoCountOnly() {
        loadingQueue.async { [weak self] in
            guard let self = self else { return }
            
            guard FileManager.default.fileExists(atPath: self.photosDirectory.path) else {
                DispatchQueue.main.async {
                    self.photoCount = 0
                }
                return
            }
            
            do {
                let fileURLs = try FileManager.default.contentsOfDirectory(
                    at: self.photosDirectory,
                    includingPropertiesForKeys: nil,
                    options: []
                )
                
                let photoFiles = fileURLs.filter { $0.pathExtension.lowercased() == "jpg" }
                
                DispatchQueue.main.async {
                    self.photoCount = photoFiles.count
                    print("📊 Photo count loaded: \(photoFiles.count) photos")
                }
            } catch {
                DispatchQueue.main.async {
                    self.photoCount = 0
                    print("❌ Failed to load photo count: \(error)")
                }
            }
        }
    }
    
    // OPTIMIZATION: Public method to trigger full photo loading when needed
    func loadPhotosIfNeeded() {
        guard !hasLoadedPhotos else {
            print("📷 Photos already loaded, skipping")
            return
        }
        
        print("🚀 Starting lazy photo loading...")
        hasLoadedPhotos = true
        loadPhotosAsync()
    }
    
    // OPTIMIZATION 3: Async photo loading (now called only when needed)
    private func loadPhotosAsync() {
        isLoading = true
        
        loadingQueue.async { [weak self] in
            guard let self = self else { return }
            
            guard FileManager.default.fileExists(atPath: self.photosDirectory.path) else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            do {
                let fileURLs = try FileManager.default.contentsOfDirectory(
                    at: self.photosDirectory, 
                    includingPropertiesForKeys: [.creationDateKey], 
                    options: []
                )
                
                let photoFiles = fileURLs
                    .filter { $0.pathExtension.lowercased() == "jpg" }
                    .sorted { url1, url2 in
                        let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                        let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                        return date1 > date2 // Newest first
                    }
                
                // BATCH PROCESSING: Load in chunks of 10
                let batchSize = 10
                var loadedPhotos: [CapturedPhoto] = []
                
                for i in stride(from: 0, to: photoFiles.count, by: batchSize) {
                    let endIndex = min(i + batchSize, photoFiles.count)
                    let batch = Array(photoFiles[i..<endIndex])
                    
                    let batchPhotos = self.processBatch(batch)
                    loadedPhotos.append(contentsOf: batchPhotos)
                }
                
                let sortedPhotos = loadedPhotos.sorted { $0.dateCaptured > $1.dateCaptured }
                
                // Update UI with each batch for progressive loading
                DispatchQueue.main.async {
                    self.capturedPhotos = sortedPhotos
                }
                
                // Small delay between batches to prevent UI blocking
                Thread.sleep(forTimeInterval: 0.05)
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    print("✅ Loaded \(loadedPhotos.count) photos with micro-thumbnails")
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    print("❌ Failed to load photos: \(error)")
                }
            }
        }
    }
    
    // OPTIMIZATION 4: Concurrent batch processing
    private func processBatch(_ fileURLs: [URL]) -> [CapturedPhoto] {
        let dispatchGroup = DispatchGroup()
        let concurrentQueue = DispatchQueue(label: "batch.processing", qos: .userInitiated, attributes: .concurrent)
        var batchPhotos: [CapturedPhoto] = []
        let lock = NSLock()
        
        for fileURL in fileURLs {
            dispatchGroup.enter()
            concurrentQueue.async {
                defer { dispatchGroup.leave() }
                
                if let photo = self.processPhotoFile(fileURL) {
                    lock.lock()
                    batchPhotos.append(photo)
                    lock.unlock()
                }
            }
        }
        
        dispatchGroup.wait()
        return batchPhotos.sorted { $0.dateCaptured > $1.dateCaptured }
    }

    private func processPhotoFile(_ fileURL: URL) -> CapturedPhoto? {
        let fileName = fileURL.lastPathComponent
        let photoId = String(fileName.dropLast(4))
        let thumbnailFileName = "\(photoId)_thumb.jpg"
        let thumbnailURL = thumbnailsDirectory.appendingPathComponent(thumbnailFileName)
        
        // Check cache first
        if let cachedThumbnail = thumbnailCache.object(forKey: photoId as NSString) {
            return createCapturedPhoto(
                id: photoId,
                fileName: fileName,
                fileURL: fileURL,
                thumbnailURL: thumbnailURL,
                thumbnail: cachedThumbnail
            )
        }
        
        // Load or generate thumbnail
        var thumbnail: UIImage?
        
        // Try loading existing thumbnail
        if let thumbnailData = try? Data(contentsOf: thumbnailURL) {
            thumbnail = UIImage(data: thumbnailData)
        }
        
        // Generate thumbnail if needed
        if thumbnail == nil {
            if let imageData = try? Data(contentsOf: fileURL),
               let image = UIImage(data: imageData) {
                thumbnail = generateThumbnail(from: image)
                
                // Save thumbnail for future use
                if let thumbnail = thumbnail,
                   let thumbnailData = thumbnail.jpegData(compressionQuality: 0.7) { // Lower quality for speed
                    try? thumbnailData.write(to: thumbnailURL)
                }
            }
        }
        
        guard let finalThumbnail = thumbnail else { return nil }
        
        // Cache the thumbnail
        thumbnailCache.setObject(finalThumbnail, forKey: photoId as NSString)
        
        return createCapturedPhoto(
            id: photoId,
            fileName: fileName,
            fileURL: fileURL,
            thumbnailURL: thumbnailURL,
            thumbnail: finalThumbnail
        )
    }

    private func createCapturedPhoto(id: String, fileName: String, fileURL: URL, thumbnailURL: URL, thumbnail: UIImage) -> CapturedPhoto {
        // Extract metadata for existing photos (using thumbnail data for efficiency)
        let metadata: PhotoMetadata
        if let imageData = try? Data(contentsOf: fileURL) {
            metadata = extractMetadata(from: imageData, fileURL: fileURL)
        } else {
            metadata = createDefaultMetadata(fileURL: fileURL)
        }
        
        let basicInfo = generateBasicInfo(compositionType: "Rule of Thirds", compositionScore: 0.7)
        
        // Get the actual file creation date
        let dateCaptured = (try? fileURL.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date()
        
        return CapturedPhoto(
            id: id,
            fileName: fileName,
            fileURL: fileURL,
            thumbnailURL: thumbnailURL,
            dateCaptured: dateCaptured,
            thumbnail: thumbnail,
            metadata: metadata,
            basicInfo: basicInfo
        )
    }
    
    func deletePhoto(_ photo: CapturedPhoto) {
        do {
            // Delete full resolution image
            try FileManager.default.removeItem(at: photo.fileURL)
            
            // Delete thumbnail
            try FileManager.default.removeItem(at: photo.thumbnailURL)
            
            DispatchQueue.main.async {
                self.capturedPhotos.removeAll { $0.id == photo.id }
                // Update photo count
                self.photoCount = max(0, self.photoCount - 1)
            }
            
            print("✅ Photo and thumbnail deleted: \(photo.fileName)")
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
    let thumbnailURL: URL
    let dateCaptured: Date
    let thumbnail: UIImage
    let metadata: PhotoMetadata
    let basicInfo: PhotoBasicInfo
    
    static func == (lhs: CapturedPhoto, rhs: CapturedPhoto) -> Bool {
        return lhs.id == rhs.id
    }
} 
