//
//  PhotoAlbumView.swift
//  Klick
//
//  Created by Manase on 03/08/2025.
//
import SwiftUI

struct PhotoAlbumView: View {
    let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    
    var glipseRevealStarted: Bool
    @Binding var isFullScreen: Bool
    @ObservedObject var photoManager: PhotoManager

    let onTap: () -> Void
    
    @State private var selectedPhoto: CapturedPhoto?
    @State private var isSelectionMode = false
    @State private var selectedPhotos: Set<String> = []
    @State private var showDeleteAlert = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    // Top section with "Slide to view" text or close button
                    VStack {
                        if isFullScreen {
                            HStack {
                                Button(action: {
                                    withAnimation(.easeOut) {
                                        clearSelectedPhoto()
                                    }
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                        onTap()
                                    }
                                }, label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 16, weight: .medium))
                                    }
                                    .foregroundColor(.black)
                                })
                                .padding(10)
                                .background(Color.black.opacity(0.15))
                                .clipShape(Capsule())
                                
                                Spacer()
                                
                                // Delete button (only show when in selection mode and photos are selected)
                                if isSelectionMode && !selectedPhotos.isEmpty {
                                    Button(action: {
                                        showDeleteAlert = true
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "trash")
                                                .font(.system(size: 16, weight: .medium))
                                            Text("\(selectedPhotos.count)")
                                                .font(.system(size: 16, weight: .medium))
                                        }
                                        .foregroundColor(.white)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(Color.red)
                                        .clipShape(Capsule())
                                    }
                                }
                            }
                            .frame(height: 20)
                            .padding(.top, 60)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        } else {
                            VStack(spacing: 4) {
                                Text("Tap to view")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.black)
                                
                                if photoManager.photoCount > 0 && glipseRevealStarted {
                                    Text("\(photoManager.photoCount) photos")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(.black.opacity(0.7))
                                }
                            }
                            .padding(.top, 10)
                            Spacer()
                        }
                    }
                    
                    // Photo grid section
                    if photoManager.photoCount == 0 {
                        AnimatedIntroView {
                            onTap()
                        }
                    } else if photoManager.isLoading {
                        // Loading state for lazy loading
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Loading photos...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.black.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 60)
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 12) {
                                // Add photo canvas at the beginning - only show when not in selection mode
                                if !isSelectionMode {
                                    AddPhotoCanvasView {
                                        // Close the photo album to go back to camera
                                        withAnimation(.easeOut) {
                                            clearSelectedPhoto()
                                        }
                                        
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                            onTap()
                                        }
                                    }
                                }
                                
                                // Sort photos by creation date in descending order (latest first)
                                ForEach(photoManager.capturedPhotos) { photo in
                                    PhotoThumbnailView(
                                        photo: photo,
                                        isSelectionMode: isSelectionMode,
                                        isSelected: selectedPhotos.contains(photo.id)
                                    ) {
                                        if isSelectionMode {
                                            togglePhotoSelection(photo)
                                        } else {
                                            print("🔍 Selecting photo: \(photo.id)")
                                            selectedPhoto = photo
                                            print("✅ Selected photo set to: \(photo.id)")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, isFullScreen && photoManager.photoCount > 0 && !photoManager.isLoading ? 100 : 20) // Bottom padding for floating button
                        }
                    }
                }
                
                // Floating bottom bar with Select button - positioned as overlay
                if isFullScreen && photoManager.photoCount > 0 && !photoManager.isLoading {
                    VStack {
                        Spacer()
                        
                        HStack(spacing: 16) {
                            Spacer()
                            
                            // Select/Cancel button
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isSelectionMode.toggle()
                                    if !isSelectionMode {
                                        selectedPhotos.removeAll()
                                    }
                                }
                            }) {
                                HStack(spacing: 8) {
                                    if isSelectionMode {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 16, weight: .medium))
                                    } else {
                                        Text("Select")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                }
                                .foregroundColor(.black)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 20)
                                .background(Color.white.opacity(0.9))
                                .clipShape(Capsule())
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40) // Safe area padding
                    }
                }
            }
            .background(Color.yellow)
            .clipShape(
                RoundedCorners(topLeading: 30, topTrailing: 30, bottomLeading: 0, bottomTrailing: 0)
            )
            .onTapGesture {
                if !isFullScreen {
                    // Trigger lazy loading when photo album is about to be opened
                    photoManager.loadPhotosIfNeeded()
                    onTap()
                }
            }
            .sheet(item: $selectedPhoto, onDismiss: {
                print("📱 Sheet dismissed, clearing selectedPhoto")
            }) { photo in
                PhotoDetailView(photo: photo, photoManager: photoManager, isPresented: .constant(true)) {
                    // Dismiss callback
                    selectedPhoto = nil
                }
            }
            .alert("Delete Photos", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    deleteSelectedPhotos()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete \(selectedPhotos.count) photo\(selectedPhotos.count == 1 ? "" : "s")? This action cannot be undone.")
            }
            .onAppear {
                // Trigger lazy loading when view appears in full screen mode
                if isFullScreen {
                    photoManager.loadPhotosIfNeeded()
                }
            }
            .onChange(of: isFullScreen) { newValue in
                // Trigger lazy loading when transitioning to full screen
                if newValue {
                    photoManager.loadPhotosIfNeeded()
                }
            }
        }
    }
    
    func togglePhotoSelection(_ photo: CapturedPhoto) {
        if selectedPhotos.contains(photo.id) {
            selectedPhotos.remove(photo.id)
        } else {
            selectedPhotos.insert(photo.id)
        }
    }
    
    func deleteSelectedPhotos() {
        let photosToDelete = photoManager.capturedPhotos.filter { selectedPhotos.contains($0.id) }
        for photo in photosToDelete {
            photoManager.deletePhoto(photo)
        }
        
        withAnimation(.easeOut) {
            selectedPhotos.removeAll()
            isSelectionMode = false
        }
    }
    
    func resetSelectionMode() {
        // Only reset selectedPhoto when we're actually closing the photo album
        // Don't reset it when just managing selection mode
        print("🔄 Resetting selection mode")
        isSelectionMode = false
        selectedPhotos.removeAll()
    }
    
    func clearSelectedPhoto() {
        print("🧹 Clearing selected photo")
        selectedPhoto = nil
        resetSelectionMode()
    }
}


// Custom shape for rounded top corners only
struct RoundedCorners: Shape {
    let topLeading: CGFloat
    let topTrailing: CGFloat
    let bottomLeading: CGFloat
    let bottomTrailing: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.size.width
        let height = rect.size.height
        
        // Start from top-leading corner
        path.move(to: CGPoint(x: topLeading, y: 0))
        
        // Top edge with top-trailing corner
        path.addLine(to: CGPoint(x: width - topTrailing, y: 0))
        path.addQuadCurve(to: CGPoint(x: width, y: topTrailing), control: CGPoint(x: width, y: 0))
        
        // Right edge with bottom-trailing corner
        path.addLine(to: CGPoint(x: width, y: height - bottomTrailing))
        path.addQuadCurve(to: CGPoint(x: width - bottomTrailing, y: height), control: CGPoint(x: width, y: height))
        
        // Bottom edge with bottom-leading corner
        path.addLine(to: CGPoint(x: bottomLeading, y: height))
        path.addQuadCurve(to: CGPoint(x: 0, y: height - bottomLeading), control: CGPoint(x: 0, y: height))
        
        // Left edge with top-leading corner
        path.addLine(to: CGPoint(x: 0, y: topLeading))
        path.addQuadCurve(to: CGPoint(x: topLeading, y: 0), control: CGPoint(x: 0, y: 0))
        
        return path
    }
}
