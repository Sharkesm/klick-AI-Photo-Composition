//
//  PhotoDetailView.swift
//  Klick
//
//  Created by Manase on 03/08/2025.
//
import SwiftUI

struct PhotoDetailView: View {
    let photo: CapturedPhoto
    @ObservedObject var photoManager: PhotoManager
    @Binding var isPresented: Bool
    let onDismiss: (() -> Void)?
    @State private var showDeleteAlert = false
    @State private var fullResolutionImage: UIImage?
    @State private var isLoadingFullResolution = false
    
    init(photo: CapturedPhoto, photoManager: PhotoManager, isPresented: Binding<Bool>, onDismiss: (() -> Void)? = nil) {
        self.photo = photo
        self.photoManager = photoManager
        self._isPresented = isPresented
        self.onDismiss = onDismiss
    }
    
        var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    // Main content with scroll-based photo scaling
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 0) {
                                // Photo section that scales based on scroll
                                VStack {
                                    ZStack {
                                        // Always show thumbnail as base layer
                                        Image(uiImage: photo.thumbnail)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(maxWidth: .infinity)
                                            .frame(maxHeight: geometry.size.height * 0.75)
                                            .cornerRadius(12)
                                    
                                        // Show high-res image on top when loaded
                                        if let fullResImage = fullResolutionImage {
                                            Image(uiImage: fullResImage)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(maxWidth: .infinity)
                                                .frame(maxHeight: geometry.size.height * 0.75)
                                                .cornerRadius(12)
                                                .transition(.opacity)
                                        }
                                        
                                        // Loading indicator overlay - only show when actively loading
                                        if isLoadingFullResolution && fullResolutionImage == nil {
                                            VStack {
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                    .scaleEffect(1.2)
                                            }
                                            .padding()
                                            .background(Color.black.opacity(0.3))
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, minHeight: geometry.size.height * 0.8)
                                .id("photoSection")
                                .onAppear {
                                    print("📷 PhotoDetailView appeared for photo: \(photo.id)")
                                    print("📷 Thumbnail size: \(photo.thumbnail.size)")
                                    // Reset state and load full resolution image when view appears
                                    fullResolutionImage = nil
                                    isLoadingFullResolution = false
                                    loadFullResolutionImage()
                                }
                                
                                // Metadata section (20% of screen at bottom)
                                VStack(spacing: 8) {
                                    // Handle bar
                                    RoundedRectangle(cornerRadius: 2.5)
                                        .fill(Color.white.opacity(0.3))
                                        .frame(width: 36, height: 5)
                                        .padding(.top, 12)
                                    
                                    // Horizontal Scrollable Basic Details Section
                                    VStack(alignment: .leading, spacing: 12) {
                                        // Description Section
                                        VStack(alignment: .leading, spacing: 8) {
                                            Group {
                                                Text("Captured with ")
                                                    .font(.system(size: 16, weight: .medium))
                                                    .foregroundColor(.gray.opacity(0.85))
                                                +
                                                Text(photo.basicInfo.description)
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundColor(.white)
                                            }
                                            
                                            Text(photo.basicInfo.compositionStyle)
                                                .font(.system(size: 13))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.blue)
                                                .clipShape(Capsule())
                                                .padding(.vertical, 8)
                                             
                                            Group {
                                                Text("Captured on ")
                                                +
                                                Text("\(formatFriendlyDate(photo.basicInfo.capturedOn))")
                                            }
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.7))
                                            
                                            Text(photo.basicInfo.framingEvaluation)
                                                .font(.system(size: 12))
                                                .foregroundColor(.white.opacity(0.7))
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 16)
                                        
                                        // 3-column grid layout for basic details
                                        let columns = [
                                            GridItem(.flexible(), spacing: 12),
                                            GridItem(.flexible(), spacing: 12),
                                            GridItem(.flexible(), spacing: 12)
                                        ]
                                        
                                        LazyVGrid(columns: columns, spacing: 16) {
                                            BasicDetailCard(
                                                icon: "grid",
                                                value: photo.basicInfo.compositionStyle
                                            )
                                            
                                            BasicDetailCard(
                                                icon: "brain.head.profile",
                                                value: getFramingScore(photo.basicInfo.framingEvaluation)
                                            )
                                            
                                            BasicDetailCard(
                                                icon: "camera.fill",
                                                value: "Wide"
                                            )
                                            
                                            BasicDetailCard(
                                                icon: "ruler",
                                                value: formatResolution(photo.metadata.resolution)
                                            )
                                            
                                            if let focalLength = photo.metadata.focalLength {
                                                BasicDetailCard(
                                                    icon: "magnifyingglass",
                                                    value: focalLength
                                                )
                                            }
                                            
                                            if let iso = photo.metadata.iso {
                                                BasicDetailCard(
                                                    icon: "sun.max",
                                                    value: iso
                                                )
                                            }
                                            
                                            BasicDetailCard(
                                                icon: "bolt",
                                                value: photo.metadata.flash
                                            )
                                            
                                            BasicDetailCard(
                                                icon: "externaldrive",
                                                value: photo.metadata.fileSize
                                            )
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.bottom, 20)
                                    }
                                    
                                    Spacer()
                                }
                                .frame(minHeight: geometry.size.height * 0.65)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(.ultraThinMaterial)
                                        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: -5)
                                )
                                .id("metadataSection")
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func loadFullResolutionImage() {
        // Don't start loading if we already have the full resolution image
        guard fullResolutionImage == nil else {
            print("📷 Full resolution image already loaded for photo: \(photo.id)")
            isLoadingFullResolution = false
            return
        }
        
        // Don't start loading if already loading
        guard !isLoadingFullResolution else {
            print("📷 Already loading full resolution image for photo: \(photo.id)")
            return
        }
        
        print("📷 Starting to load full resolution image for photo: \(photo.id)")
        isLoadingFullResolution = true
        
        photoManager.loadFullResolutionImage(for: photo) { image in
            DispatchQueue.main.async {
                withAnimation(.easeOut(duration: 0.3)) {
                    if let image = image {
                        print("✅ Full resolution image loaded successfully for photo: \(self.photo.id), size: \(image.size)")
                        self.fullResolutionImage = image
                    } else {
                        print("❌ Failed to load full resolution image for photo: \(self.photo.id)")
                    }
                    self.isLoadingFullResolution = false
                }
            }
        }
    }
    
    private func formatFriendlyDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    private func getFramingScore(_ evaluation: String) -> String {
        if evaluation.contains("Excellent") {
            return "Great"
        } else if evaluation.contains("Great") {
            return "Good"
        } else if evaluation.contains("Good") {
            return "OK"
        } else {
            return "Fair"
        }
    }
    
    private func formatResolution(_ size: CGSize) -> String {
        let width = Int(size.width)
        let height = Int(size.height)
        
        if width >= 4000 || height >= 4000 {
            return "4K"
        } else if width >= 1920 || height >= 1920 {
            return "HD"
        } else {
            return "SD"
        }
    }
}
