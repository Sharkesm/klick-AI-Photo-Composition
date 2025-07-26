import SwiftUI

// MARK: - Animated Intro View Component
struct AnimatedIntroView: View {
    let onCaptureButtonTap: () -> Void
    
    @State private var scaleImages = false
    @State private var showLeftImage = false
    @State private var showRightImage = false
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var showCaptureButton = false
    
    // Animation values
    @State private var leftImageOffset: CGFloat = 0
    @State private var rightImageOffset: CGFloat = 0
    @State private var leftImageRotation: Double = 0
    @State private var rightImageRotation: Double = 0
    
    var body: some View {
        VStack(spacing: 35) {
            Spacer()
            
            // Stacked images with animations
            ZStack {
                // Left image (Rectangle_8) - behind and to the left
                Image("Rectangle_13")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 140, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    .scaleEffect(scaleImages ? 1.0 : 0.1)
                    .offset(x: leftImageOffset, y: 0)
                    .rotationEffect(.degrees(leftImageRotation))
                    .opacity(showLeftImage ? 1.0 : 0.8)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7, blendDuration: 0.3), value: scaleImages)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.2).delay(0.4), value: showLeftImage)
                
                // Right image (Rectangle_3) - behind and to the right
                Image("Rectangle_12")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 140, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    .scaleEffect(scaleImages ? 1.0 : 0.1)
                    .offset(x: rightImageOffset, y: 0)
                    .rotationEffect(.degrees(rightImageRotation))
                    .opacity(showRightImage ? 1.0 : 0.8)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7, blendDuration: 0.3), value: scaleImages)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.2).delay(0.5), value: showRightImage)
                
                // Center image (Rectangle_7) - front and center
                Image("Rectangle_11")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 140, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)
                    .scaleEffect(scaleImages ? 1.0 : 0.1)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7, blendDuration: 0.3), value: scaleImages)
            }
            .frame(height: 180)
            
            VStack(spacing: 12) {
                // Animated title
                Text("No Photos")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .opacity(showTitle ? 1.0 : 0.0)
                    .offset(y: showTitle ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.8), value: showTitle)
                
                // Animated subtitle
                Text("Capture your first photo to get started")
                    .font(.system(size: 16))
                    .foregroundColor(.black.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .opacity(showSubtitle ? 1.0 : 0.0)
                    .offset(y: showSubtitle ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(1.2), value: showSubtitle)
            }
            .padding(.top, 20)
            
            // Animated capture button
            Button(action: onCaptureButtonTap) {
                Text("Capture")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 32)
                    .background(Color.black)
                    .clipShape(Capsule())
            }
            .opacity(showCaptureButton ? 1.0 : 0.0)
            .scaleEffect(showCaptureButton ? 1.0 : 0.8)
            .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.2).delay(1.6), value: showCaptureButton)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            startAnimationSequence()
        }
    }
    
    private func startAnimationSequence() {
        // Start with scaling in the images
        withAnimation {
            scaleImages = true
        }
        
        // After scaling is almost complete, tilt and reveal the side images
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation {
                showLeftImage = true
                leftImageOffset = -100
                leftImageRotation = -13
                
                showRightImage = true
                rightImageOffset = 100
                rightImageRotation = 13
            }
        }
        
        // Show title
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation {
                showTitle = true
            }
        }
        
        // Show subtitle
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation {
                showSubtitle = true
            }
        }
        
        // Show capture button
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation {
                showCaptureButton = true
            }
        }
    }
}

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
                                Button(action: onTap) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 16, weight: .medium))
                                    }
                                    .foregroundColor(.black)
                                }
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
                        AnimatedIntroView {
                            onTap()
                        }
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(photoManager.capturedPhotos) { photo in
                                    PhotoThumbnailView(
                                        photo: photo,
                                        isSelectionMode: isSelectionMode,
                                        isSelected: selectedPhotos.contains(photo.id)
                                    ) {
                                        if isSelectionMode {
                                            togglePhotoSelection(photo)
                                        } else {
                                            selectedPhoto = photo
                                            showPhotoDetail = true
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, isFullScreen && !photoManager.capturedPhotos.isEmpty ? 120 : 100) // Extra padding for floating buttons
                        }
                    }
                }
                
                // Floating bottom bar with Select and Delete buttons
                if isFullScreen && !photoManager.capturedPhotos.isEmpty {
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
        .alert("Delete Photos", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                deleteSelectedPhotos()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete \(selectedPhotos.count) photo\(selectedPhotos.count == 1 ? "" : "s")? This action cannot be undone.")
        }
    }
    
    private func togglePhotoSelection(_ photo: CapturedPhoto) {
        if selectedPhotos.contains(photo.id) {
            selectedPhotos.remove(photo.id)
        } else {
            selectedPhotos.insert(photo.id)
        }
    }
    
    private func deleteSelectedPhotos() {
        let photosToDelete = photoManager.capturedPhotos.filter { selectedPhotos.contains($0.id) }
        for photo in photosToDelete {
            photoManager.deletePhoto(photo)
        }
        selectedPhotos.removeAll()
        isSelectionMode = false
    }
}

struct PhotoThumbnailView: View {
    let photo: CapturedPhoto
    let isSelectionMode: Bool
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
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
                
                // Selection circle overlay
                if isSelectionMode {
                    VStack {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(isSelected ? Color.white : Color.clear)
                                    .frame(width: 18, height: 18)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                            .frame(width: 18, height: 18)
                                    )
                                
                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.black)
                                }
                            }
                            .padding(.leading, 8)
                            .padding(.top, 8)
                            
                            Spacer()
                        }
                        
                        Spacer()
                    }
                }
            }
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
