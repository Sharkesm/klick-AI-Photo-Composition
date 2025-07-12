//
//  ContentView.swift
//  Klick
//
//  Created by Manase on 12/07/2025.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct ContentView: View {
    @StateObject private var queue = ImageAnalysisQueue()
    @State private var capturedImage: UIImage?
    @State private var showImagePicker = false
    @State private var showEducation = false
    @State private var showAnalysisResult = false
    @State private var showBlackWhite = false
    @State private var blackWhiteImage: UIImage?
    @State private var showQueueManagement = false
    @State private var showAddImageAlert = false
    @State private var pendingImage: UIImage?
    
    var body: some View {
        ZStack {
            // Main content
            if let image = capturedImage {
                // Image view with overlay
                GeometryReader { geometry in
                    ZStack {
                        // Display the image
                        Image(uiImage: showBlackWhite && blackWhiteImage != nil ? blackWhiteImage! : image)
                            .resizable()
                            .scaledToFill() // Change to scaledToFill to ensure full-screen
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped() // Clip to bounds to avoid overflow
                        
                        // Composition overlay
                        if case .completed(let result) = queue.analyzer.analysisState {
                            CompositionOverlayView(
                                imageSize: image.size,
                                analysisResult: result
                            )
                        }

                        // Progress overlay visible while analyzing
                        if case .analyzing = queue.analyzer.analysisState {
                            AnalysisProgressView(progress: queue.analyzer.progress)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                                .animation(.easeInOut, value: queue.analyzer.progress.percent)
                                .padding()
                        }
                    }
                }
                .edgesIgnoringSafeArea(.all)
                
                // Controls overlay
                VStack {
                    // Top bar
                    HStack {
                        Button(action: { 
                            handleNewPhotoRequest()
                        }) {
                            HStack {
                                Image(systemName: "arrow.left")
                                Text("New Photo")
                            }
                            .padding(.horizontal, 15)
                            .padding(.vertical, 10)
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(25)
                        }
                        
                        Spacer()
                        
                        // Queue management button
                        if queue.isProcessing || queue.hasPendingTasks {
                            Button(action: {
                                showQueueManagement = true
                            }) {
                                Image(systemName: "list.bullet.clipboard")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color.orange.opacity(0.8))
                                    .clipShape(Circle())
                            }
                        }
                        
                        // Black & White toggle
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                if blackWhiteImage == nil {
                                    blackWhiteImage = convertToBlackWhite(image)
                                }
                                showBlackWhite.toggle()
                            }
                        }) {
                            Image(systemName: showBlackWhite ? "circle.righthalf.filled" : "circle.lefthalf.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.7))
                                .clipShape(Circle())
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Bottom controls
                    VStack(spacing: 15) {
                        // Analyze button
                        if case .idle = queue.analyzer.analysisState {
                            Button(action: {
                                print("🔍 Starting image analysis...")
                                queue.enqueueImage(image)
                            }) {
                                Label("Analyze Composition", systemImage: "viewfinder.circle.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                                                
                        // Results button
                        if case .completed(let result) = queue.analyzer.analysisState {
                            HStack(spacing: 15) {
                                Button(action: { showAnalysisResult = true }) {
                                    Label("View Results", systemImage: "chart.bar.fill")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                }
                                
                                Button(action: { showEducation = true }) {
                                    Image(systemName: "book.fill")
                                        .font(.headline)
                                        .padding()
                                        .background(Color.orange)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                }
                            }
                            .onAppear {
                                print("✅ Analysis completed with \(result.detectedRules.count) rules")
                            }
                        }
                        
                        // Error handling
                        if case .failed(let error) = queue.analyzer.analysisState {
                            VStack {
                                Text("Analysis failed")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                Text(error.localizedDescription)
                                    .foregroundColor(.white)
                                    .font(.caption)
                                
                                Button("Try Again") {
                                    queue.analyzer.analysisState = .idle
                                }
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.7))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.black.opacity(0), Color.black.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            } else {
                // Welcome screen
                VStack(spacing: 30) {
                    Spacer()
                    
                    // App icon and title
                    VStack(spacing: 20) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text("Klick")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Learn Photography Composition")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Get started button
                    Button(action: { showImagePicker = true }) {
                        Label("Get Started", systemImage: "camera.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    
                    // Learn button
                    Button(action: { showEducation = true }) {
                        Label("Learn Composition", systemImage: "book.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                }
                .padding()
            }
        }
        .sheet(isPresented: $showImagePicker) {
            PhotoCaptureView(
                capturedImage: $capturedImage,
                showImagePicker: $showImagePicker,
                queue: queue
            )
        }
        .sheet(isPresented: $showEducation) {
            EducationalContentView()
        }
        .sheet(isPresented: $showAnalysisResult) {
            if case .completed(let result) = queue.analyzer.analysisState {
                AnalysisResultView(
                    analysisResult: result,
                    showEducation: $showEducation
                )
            }
        }
        .sheet(isPresented: $showQueueManagement) {
            QueueManagementView(
                queue: queue,
                showQueueManagement: $showQueueManagement
            )
        }
        .alert("Add New Image", isPresented: $showAddImageAlert) {
            Button("Cancel", role: .cancel) {
                pendingImage = nil
            }
            Button("Add to Queue") {
                if let image = pendingImage {
                    queue.enqueueImage(image)
                    capturedImage = image
                    showBlackWhite = false
                    blackWhiteImage = nil
                }
                pendingImage = nil
            }
            Button("Replace Current", role: .destructive) {
                if let image = pendingImage {
                    queue.stopAnalysis()
                    queue.enqueueImage(image)
                    capturedImage = image
                    showBlackWhite = false
                    blackWhiteImage = nil
                }
                pendingImage = nil
            }
        } message: {
            Text("An analysis is currently in progress. Would you like to add this image to the queue or replace the current analysis?")
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleNewPhotoRequest() {
        if queue.isProcessing || queue.hasPendingTasks {
            // Show alert to user about ongoing analysis
            pendingImage = nil
            showAddImageAlert = true
        } else {
            // Clear current image and reset state
            capturedImage = nil
            queue.analyzer.analysisState = .idle
            showBlackWhite = false
            blackWhiteImage = nil
            showImagePicker = true
        }
    }
    
    // Convert image to black and white
    private func convertToBlackWhite(_ image: UIImage) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.photoEffectMono()
        
        guard let ciImage = CIImage(image: image) else { return nil }
        filter.inputImage = ciImage
        
        guard let outputImage = filter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}

// MARK: - Basic Grid Overlay for Debugging
struct BasicGridOverlay: View {
    let imageSize: CGSize
    
    var body: some View {
        GeometryReader { geometry in
            let scaleX = geometry.size.width / imageSize.width
            let scaleY = geometry.size.height / imageSize.height
            let scale = min(scaleX, scaleY)
            
            let displayWidth = imageSize.width * scale
            let displayHeight = imageSize.height * scale
            
            let thirdX = displayWidth / 3
            let thirdY = displayHeight / 3
            
            let offsetX = (geometry.size.width - displayWidth) / 2
            let offsetY = (geometry.size.height - displayHeight) / 2
            
            ZStack {
                // Rule of thirds grid
                Path { path in
                    // Vertical lines
                    path.move(to: CGPoint(x: offsetX + thirdX, y: offsetY))
                    path.addLine(to: CGPoint(x: offsetX + thirdX, y: offsetY + displayHeight))
                    path.move(to: CGPoint(x: offsetX + thirdX * 2, y: offsetY))
                    path.addLine(to: CGPoint(x: offsetX + thirdX * 2, y: offsetY + displayHeight))
                    
                    // Horizontal lines
                    path.move(to: CGPoint(x: offsetX, y: offsetY + thirdY))
                    path.addLine(to: CGPoint(x: offsetX + displayWidth, y: offsetY + thirdY))
                    path.move(to: CGPoint(x: offsetX, y: offsetY + thirdY * 2))
                    path.addLine(to: CGPoint(x: offsetX + displayWidth, y: offsetY + thirdY * 2))
                }
                .stroke(Color.white.opacity(0.8), lineWidth: 2)
                
                // Center point for debugging
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .position(
                        x: offsetX + displayWidth / 2,
                        y: offsetY + displayHeight / 2
                    )
                
                // Corner markers
                ForEach(0..<4) { index in
                    let point = getThirdsPoint(index: index, width: displayWidth, height: displayHeight, offsetX: offsetX, offsetY: offsetY)
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 12, height: 12)
                        .position(point)
                }
            }
        }
    }
    
    private func getThirdsPoint(index: Int, width: CGFloat, height: CGFloat, offsetX: CGFloat, offsetY: CGFloat) -> CGPoint {
        let thirdX = width / 3
        let thirdY = height / 3
        
        switch index {
        case 0: return CGPoint(x: offsetX + thirdX, y: offsetY + thirdY)
        case 1: return CGPoint(x: offsetX + thirdX * 2, y: offsetY + thirdY)
        case 2: return CGPoint(x: offsetX + thirdX, y: offsetY + thirdY * 2)
        case 3: return CGPoint(x: offsetX + thirdX * 2, y: offsetY + thirdY * 2)
        default: return CGPoint(x: offsetX + width / 2, y: offsetY + height / 2)
        }
    }
}

#Preview {
    ContentView()
}
