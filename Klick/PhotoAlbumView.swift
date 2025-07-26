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
    @State private var showPhotoDetail = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top section with "Slide to view" text or close button
                VStack {
                    if isFullScreen {
                        HStack {
                            Button(action: onTap) {
                                HStack(spacing: 8) {
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Close")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .foregroundColor(.black)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.black.opacity(0.15))
                            .clipShape(Capsule())
                            
                            Spacer()
                            
                            // Photo count
                            Text("\(photoManager.capturedPhotos.count) photos")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.black.opacity(0.7))
                        }
                        .padding(.top, 60) // Account for safe area
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    } else {
                        VStack(spacing: 4) {
                            Text("Tap to view")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.black)
                            
                            if !photoManager.capturedPhotos.isEmpty && glipseRevealStarted {
                                Text("\(photoManager.capturedPhotos.count) photos")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.black.opacity(0.7))
                            }
                        }
                        .padding(.top, 10)
                        Spacer()
                    }
                }
                
                // Photo grid section
                if photoManager.capturedPhotos.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Spacer()
                        
                        Image(systemName: "camera.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.black.opacity(0.3))
                        
                        Text("No photos yet")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.black.opacity(0.6))
                        
                        Text("Capture your first photo to get started")
                            .font(.system(size: 14))
                            .foregroundColor(.black.opacity(0.5))
                            .multilineTextAlignment(.center)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(photoManager.capturedPhotos) { photo in
                                PhotoThumbnailView(photo: photo) {
                                    selectedPhoto = photo
                                    showPhotoDetail = true
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100) // Extra padding for bottom safe area
                    }
                }
            }
        }
        .background(Color.yellow)
        .clipShape(
            RoundedCorners(topLeading: 30, topTrailing: 30, bottomLeading: 0, bottomTrailing: 0)
        )
        .onTapGesture {
            if !isFullScreen {
                onTap()
            }
        }
        .sheet(isPresented: $showPhotoDetail) {
            if let photo = selectedPhoto {
                PhotoDetailView(photo: photo, photoManager: photoManager, isPresented: $showPhotoDetail)
            }
        }
    }
}

struct PhotoThumbnailView: View {
    let photo: CapturedPhoto
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Image(uiImage: photo.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(minHeight: 120)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PhotoDetailView: View {
    let photo: CapturedPhoto
    @ObservedObject var photoManager: PhotoManager
    @Binding var isPresented: Bool
    @State private var showDeleteAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    // Main photo
                    Image(uiImage: photo.image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipped()
                    
                    Spacer()
                    
                    // Photo info
                    VStack(spacing: 8) {
                        Text("Captured \(photo.dateCaptured, style: .date) at \(photo.dateCaptured, style: .time)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        isPresented = false
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .alert("Delete Photo", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                photoManager.deletePhoto(photo)
                isPresented = false
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this photo? This action cannot be undone.")
        }
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
