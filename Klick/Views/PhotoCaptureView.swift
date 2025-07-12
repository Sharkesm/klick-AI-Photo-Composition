//
//  PhotoCaptureView.swift
//  Klick
//
//  Created by AI Assistant on 12/07/2025.
//

import SwiftUI
import PhotosUI

struct PhotoCaptureView: View {
    @Binding var capturedImage: UIImage?
    @Binding var showImagePicker: Bool
    @ObservedObject var queue: ImageAnalysisQueue
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showAddImageAlert = false
    @State private var pendingImage: UIImage?
    
    var body: some View {
        VStack(spacing: 20) {
            // Camera Button
            Button(action: {
                checkCameraPermissions()
            }) {
                Label("Take Photo", systemImage: "camera.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            
            // Photo Library Button
            PhotosPicker(selection: $selectedPhotoItem,
                        matching: .images,
                        photoLibrary: .shared()) {
                Label("Choose from Library", systemImage: "photo.on.rectangle")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .onChange(of: selectedPhotoItem) { newItem in
                Task {
                    if let newItem = newItem {
                        await loadPhoto(from: newItem)
                    }
                }
            }
        }
        .padding()
        .sheet(isPresented: $showCamera) {
            CameraView(
                capturedImage: $capturedImage, 
                isPresented: $showCamera,
                queue: queue,
                onImageSelected: { image in
                    handleNewImage(image)
                }
            )
            .onDisappear {
                if capturedImage != nil {
                    showImagePicker = false
                }
            }
        }
        .alert("Permission Required", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .alert("Add New Image", isPresented: $showAddImageAlert) {
            Button("Cancel", role: .cancel) {
                pendingImage = nil
            }
            Button("Add to Queue") {
                if let image = pendingImage {
                    queue.enqueueImage(image)
                }
                pendingImage = nil
                showImagePicker = false
            }
            Button("Replace Current", role: .destructive) {
                if let image = pendingImage {
                    queue.stopAnalysis()
                    queue.enqueueImage(image)
                }
                pendingImage = nil
                showImagePicker = false
            }
        } message: {
            Text("An analysis is currently in progress. Would you like to add this image to the queue or replace the current analysis?")
        }
    }
    
    private func checkCameraPermissions() {
        #if targetEnvironment(simulator)
        alertMessage = "Camera is not available in the simulator. Please use a real device or choose from photo library."
        showingAlert = true
        #else
        showCamera = true
        #endif
    }
    
    private func loadPhoto(from item: PhotosPickerItem) async {
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    handleNewImage(image)
                }
            }
        } catch {
            await MainActor.run {
                alertMessage = "Failed to load the selected photo: \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }
    
    private func handleNewImage(_ image: UIImage) {
        if queue.isProcessing || queue.hasPendingTasks {
            pendingImage = image
            showAddImageAlert = true
        } else {
            capturedImage = image
            showImagePicker = false
        }
    }
}

// MARK: - Camera View using UIImagePickerController
struct CameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Binding var isPresented: Bool
    let queue: ImageAnalysisQueue
    let onImageSelected: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageSelected(image)
            }
            parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}

// MARK: - Preview
struct PhotoCaptureView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoCaptureView(
            capturedImage: .constant(nil),
            showImagePicker: .constant(true),
            queue: ImageAnalysisQueue()
        )
    }
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView(
            capturedImage: .constant(nil),
            isPresented: .constant(true),
            queue: ImageAnalysisQueue(),
            onImageSelected: { _ in }
        )
    }
} 