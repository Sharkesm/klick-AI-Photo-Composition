//
//  LiveCameraView.swift
//  Klick
//
//  Created by AI Assistant on 12/07/2025.
//

import SwiftUI
import AVFoundation
import Vision
import UIKit

struct LiveCameraView: View {
    @StateObject private var cameraManager = LiveCameraManager()
    @State private var showRuleOfThirds = true
    @State private var showEducationalTip = false
    @State private var compositionFeedback: CompositionFeedback?
    
    var body: some View {
        ZStack {
            // Live camera preview
            CameraPreviewView(cameraManager: cameraManager)
                .edgesIgnoringSafeArea(.all)
            
            // Rule of Thirds overlay
            if showRuleOfThirds {
                RuleOfThirdsOverlay()
                    .animation(.easeInOut(duration: 0.3), value: showRuleOfThirds)
            }
            
            // Subject detection bounding box
            if let subjectBoundingBox = cameraManager.detectedSubjectBoundingBox {
                SubjectBoundingBoxOverlay(boundingBox: subjectBoundingBox)
            }
            
            // Composition feedback
            if let feedback = compositionFeedback {
                CompositionFeedbackView(feedback: feedback)
            }
            
            // Top controls
            VStack {
                HStack {
                    // Rule of Thirds toggle
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showRuleOfThirds.toggle()
                        }
                    }) {
                        Image(systemName: showRuleOfThirds ? "grid" : "grid.slash")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // Educational tip button
                    Button(action: {
                        showEducationalTip = true
                    }) {
                        Image(systemName: "info.circle")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                    }
                }
                .padding()
                
                Spacer()
            }
        }
        .onAppear {
            cameraManager.startSession()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .onChange(of: cameraManager.detectedSubjectBoundingBox) { boundingBox in
            updateCompositionFeedback(boundingBox: boundingBox)
        }
        .sheet(isPresented: $showEducationalTip) {
            EducationalTipView()
        }
    }
    
    private func updateCompositionFeedback(boundingBox: CGRect?) {
        guard let boundingBox = boundingBox else {
            compositionFeedback = nil
            return
        }
        
        let isAligned = cameraManager.checkRuleOfThirdsAlignment(boundingBox: boundingBox)
        compositionFeedback = CompositionFeedback(
            isAligned: isAligned,
            message: isAligned ? "Nice framing!" : "Try placing your subject on a third"
        )
    }
}

// MARK: - Camera Preview View
struct CameraPreviewView: UIViewRepresentable {
    let cameraManager: LiveCameraManager
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        
        if let previewLayer = cameraManager.previewLayer {
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = cameraManager.previewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
}

// MARK: - Rule of Thirds Overlay
struct RuleOfThirdsOverlay: View {
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let thirdX = width / 3
            let thirdY = height / 3
            
            Path { path in
                // Vertical lines
                path.move(to: CGPoint(x: thirdX, y: 0))
                path.addLine(to: CGPoint(x: thirdX, y: height))
                path.move(to: CGPoint(x: thirdX * 2, y: 0))
                path.addLine(to: CGPoint(x: thirdX * 2, y: height))
                
                // Horizontal lines
                path.move(to: CGPoint(x: 0, y: thirdY))
                path.addLine(to: CGPoint(x: width, y: thirdY))
                path.move(to: CGPoint(x: 0, y: thirdY * 2))
                path.addLine(to: CGPoint(x: width, y: thirdY * 2))
            }
            .stroke(Color.white.opacity(0.6), lineWidth: 1)
        }
    }
}

// MARK: - Subject Bounding Box Overlay
struct SubjectBoundingBoxOverlay: View {
    let boundingBox: CGRect
    
    var body: some View {
        GeometryReader { geometry in
            let rect = CGRect(
                x: boundingBox.minX * geometry.size.width,
                y: boundingBox.minY * geometry.size.height,
                width: boundingBox.width * geometry.size.width,
                height: boundingBox.height * geometry.size.height
            )
            
            Rectangle()
                .stroke(Color.yellow, lineWidth: 2)
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
        }
    }
}

// MARK: - Composition Feedback View
struct CompositionFeedbackView: View {
    let feedback: CompositionFeedback
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: feedback.isAligned ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(feedback.isAligned ? .green : .orange)
                Text(feedback.message)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding()
            .background(Color.black.opacity(0.7))
            .cornerRadius(10)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .padding(.top, 100)
        .animation(.easeInOut(duration: 0.3), value: feedback.isAligned)
    }
}

// MARK: - Educational Tip View
struct EducationalTipView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "grid")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Rule of Thirds")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 15) {
                    Text("Place key elements of your photo where the grid lines intersect. This helps create balance and interest.")
                        .font(.body)
                    
                    Text("Try moving your subject slightly off-center to the left or right third of the frame.")
                        .font(.body)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Composition Tip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Data Models
struct CompositionFeedback {
    let isAligned: Bool
    let message: String
}

#Preview {
    LiveCameraView()
} 