import SwiftUI
import Photos

class PhotoManager: ObservableObject {
    @Published var capturedPhotos: [CapturedPhoto] = []
    
    private let documentsDirectory: URL
    private let photosDirectory: URL
    
    init() {
        // Set up directories
        documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        photosDirectory = documentsDirectory.appendingPathComponent("CapturedPhotos")
        
        // Create photos directory if it doesn't exist
        createPhotosDirectoryIfNeeded()
        
        // Load existing photos
        loadPhotos()
    }
    
    private func createPhotosDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: photosDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: photosDirectory, withIntermediateDirectories: true)
                print("✅ Created photos directory at: \(photosDirectory.path)")
            } catch {
                print("❌ Failed to create photos directory: \(error)")
            }
        }
    }
    
    func savePhoto(_ image: UIImage) {
        let photoId = UUID().uuidString
        let fileName = "\(photoId).jpg"
        let fileURL = photosDirectory.appendingPathComponent(fileName)
        
        // Convert image to JPEG data
        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            print("❌ Failed to convert image to JPEG data")
            return
        }
        
        do {
            // Save to documents directory
            try imageData.write(to: fileURL)
            
            // Create captured photo object
            let capturedPhoto = CapturedPhoto(
                id: photoId,
                fileName: fileName,
                fileURL: fileURL,
                dateCaptured: Date(),
                image: image
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
                    
                    let capturedPhoto = CapturedPhoto(
                        id: photoId,
                        fileName: fileName,
                        fileURL: fileURL,
                        dateCaptured: dateCaptured,
                        image: image
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
    
    static func == (lhs: CapturedPhoto, rhs: CapturedPhoto) -> Bool {
        return lhs.id == rhs.id
    }
} 