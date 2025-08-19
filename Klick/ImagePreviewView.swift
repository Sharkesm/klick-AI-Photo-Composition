import SwiftUI
import UIKit
import Social

struct ImagePreviewView: View {
    @Binding var image: UIImage?
    let originalImage: UIImage?
    @Binding var isProcessing: Bool
    
    let onSave: () -> Void
    let onDiscard: () -> Void
    
    @State private var showingShareSheet = false
    @State private var showingInstagramAlert = false
    
    var body: some View {
        ZStack {
            // Black background
            Color.black
                .ignoresSafeArea()
            
            VStack {
                // Top bar with close button
                HStack {
                    Button(action: onDiscard) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                    
                    Text("Preview")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Invisible button for balance
                    Button(action: {}) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.clear)
                            .frame(width: 44, height: 44)
                    }
                    .disabled(true)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer()
                
                // Image preview
                if let previewImage = image {
                    Image(uiImage: previewImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .overlay(
                            // Processing indicator
                            Group {
                                if isProcessing {
                                    ZStack {
                                        Color.black.opacity(0.3)
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(1.5)
                                    }
                                }
                            }
                        )
                        .animation(.easeInOut(duration: 0.3), value: isProcessing)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .overlay(
                            Text("No Image")
                                .foregroundColor(.gray)
                        )
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 20) {
                    // Transform buttons
                    HStack(spacing: 20) {
                        // Grayscale button
                        Button(action: applyGrayscale) {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(width: 60, height: 60)
                                    
                                    Image(systemName: "camera.filters")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                }
                                
                                Text("Grayscale")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                        }
                        .disabled(isProcessing)
                        
                        // Reset button
                        Button(action: resetToOriginal) {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(width: 60, height: 60)
                                    
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                }
                                
                                Text("Reset")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                        }
                        .disabled(isProcessing)
                        
                        // Instagram Stories button
                        Button(action: shareToInstagramStories) {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(width: 60, height: 60)
                                    
                                    Image(systemName: "camera.circle")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                }
                                
                                Text("Stories")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                        }
                        .disabled(isProcessing)
                    }
                    
                    // Main action buttons
                    HStack(spacing: 15) {
                        // Discard button
                        Button(action: onDiscard) {
                            Text("Discard")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.red.opacity(0.8))
                                .cornerRadius(25)
                        }
                        .disabled(isProcessing)
                        
                        // Save button
                        Button(action: onSave) {
                            Text("Save Photo")
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.white)
                                .cornerRadius(25)
                        }
                        .disabled(isProcessing)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .alert("Instagram Not Available", isPresented: $showingInstagramAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Instagram is not installed on this device or Instagram Stories sharing is not available.")
        }
    }
    
    // MARK: - Image Processing Functions
    
    private func applyGrayscale() {
        guard let originalImage = originalImage else { return }
        
        isProcessing = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let grayscaleImage = originalImage.toGrayscale()
            
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.image = grayscaleImage
                    self.isProcessing = false
                }
            }
        }
    }
    
    private func resetToOriginal() {
        guard let originalImage = originalImage else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            image = originalImage
        }
    }
    
    private func shareToInstagramStories() {
        guard let imageToShare = image else { return }
        
        // Check if Instagram is installed
        guard let instagramURL = URL(string: "instagram-stories://share"), UIApplication.shared.canOpenURL(instagramURL) else {
            showingInstagramAlert = true
            return
        }
        
        // Convert image to data
        guard let imageData = imageToShare.jpegData(compressionQuality: 0.9) else {
            print("Failed to convert image to data")
            return
        }
        
        // Create pasteboard items for Instagram Stories
        let pasteboardItems: [String: Any] = [
            "com.instagram.sharedSticker.stickerImage": imageData,
            "com.instagram.sharedSticker.backgroundTopColor": "#000000",
            "com.instagram.sharedSticker.backgroundBottomColor": "#000000"
        ]
        
        // Set pasteboard data
        UIPasteboard.general.setItems([pasteboardItems], options: [.expirationDate: Date().addingTimeInterval(60 * 5)])
        
        // Open Instagram Stories
        UIApplication.shared.open(instagramURL, options: [:]) { success in
            if success {
                print("✅ Successfully opened Instagram Stories")
            } else {
                print("❌ Failed to open Instagram Stories")
                DispatchQueue.main.async {
                    showingInstagramAlert = true
                }
            }
        }
    }
}

// MARK: - UIImage Extensions

extension UIImage {
    func toGrayscale() -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }
        
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let width = cgImage.width
        let height = cgImage.height
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let grayscaleCGImage = context.makeImage() else { return nil }
        
        return UIImage(cgImage: grayscaleCGImage)
    }
}

#Preview {
    ImagePreviewView(
        image: .constant(UIImage(systemName: "photo")),
        originalImage: UIImage(systemName: "photo"),
        isProcessing: .constant(false),
        onSave: {},
        onDiscard: {}
    )
}
