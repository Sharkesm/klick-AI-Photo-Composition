import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var isGridVisible = true
    @State private var feedbackMessage: String?
    @State private var showFeedback = false
    @State private var showEducationalContent = false
    @State private var hasCameraPermission = false
    @State private var detectedFaceBoundingBox: CGRect?
    
    var body: some View {
        ZStack {
            // Camera view
            CameraView(
                isGridVisible: $isGridVisible,
                feedbackMessage: $feedbackMessage,
                showFeedback: $showFeedback,
                detectedFaceBoundingBox: $detectedFaceBoundingBox
            )
            .ignoresSafeArea()
            
            // Grid overlay
            GridOverlayView(isVisible: isGridVisible)
                .ignoresSafeArea()
            
            // Face highlight overlay
            FaceHighlightOverlayView(faceBoundingBox: detectedFaceBoundingBox)
                .ignoresSafeArea()
            
            // Feedback overlay
            if showFeedback, let message = feedbackMessage {
                VStack {
                    Spacer()
                    
                    Text(message)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(25)
                        .padding(.bottom, 100)
                }
                .transition(.opacity.combined(with: .scale))
                .animation(.easeInOut(duration: 0.3), value: showFeedback)
            }
            
            // Bottom controls
            VStack {
                Spacer()
                
                HStack(spacing: 40) {
                    // Info button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showEducationalContent = true
                        }
                    }) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    
                    // Capture button
                    Button(action: {
                        // Capture functionality (optional for MVP)
                    }) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Circle()
                                    .stroke(Color.black, lineWidth: 4)
                                    .frame(width: 70, height: 70)
                            )
                    }
                    
                    // Grid toggle button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isGridVisible.toggle()
                        }
                    }) {
                        Image(systemName: isGridVisible ? "grid" : "grid.slash")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .sheet(isPresented: $showEducationalContent) {
            EducationalContentView(isPresented: $showEducationalContent)
                .presentationDetents([.medium])
        }
        .onAppear {
            requestCameraPermission()
        }
    }
    
    private func requestCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            hasCameraPermission = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    hasCameraPermission = granted
                }
            }
        case .denied, .restricted:
            hasCameraPermission = false
        @unknown default:
            hasCameraPermission = false
        }
    }
}

#Preview {
    ContentView()
} 