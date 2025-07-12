//
//  QueueManagementView.swift
//  Klick
//
//  Created by AI Assistant on 12/07/2025.
//

import SwiftUI

struct QueueManagementView: View {
    @ObservedObject var queue: ImageAnalysisQueue
    @Binding var showQueueManagement: Bool
    @State private var showCancelAlert = false
    @State private var showAddImageAlert = false
    @State private var pendingImage: UIImage?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "list.bullet.clipboard")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text("Analysis Queue")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Manage your image analysis tasks")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Current Status
                VStack(spacing: 15) {
                    HStack {
                        Image(systemName: statusIcon)
                            .foregroundColor(statusColor)
                        Text(statusText)
                            .font(.headline)
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    if let currentTask = queue.currentTask {
                        HStack {
                            Image(systemName: "photo")
                                .foregroundColor(.blue)
                            Text("Currently analyzing image...")
                                .font(.subheadline)
                            Spacer()
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                
                // Queue Information
                VStack(spacing: 15) {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.orange)
                        Text("Queue Information")
                            .font(.headline)
                        Spacer()
                    }
                    
                    VStack(spacing: 10) {
                        QueueInfoRow(
                            icon: "list.bullet",
                            title: "Pending Tasks",
                            value: "\(queue.pendingTasks.count)"
                        )
                        
                        QueueInfoRow(
                            icon: "checkmark.circle",
                            title: "Completed",
                            value: "\(queue.completedTasks.count)"
                        )
                        
                        QueueInfoRow(
                            icon: "xmark.circle",
                            title: "Failed",
                            value: "\(queue.failedTasks.count)"
                        )
                        
                        if queue.hasPendingTasks {
                            QueueInfoRow(
                                icon: "timer",
                                title: "Estimated Time",
                                value: formatEstimatedTime(queue.estimatedTimeRemaining)
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    if queue.isProcessing {
                        Button(action: {
                            showCancelAlert = true
                        }) {
                            Label("Stop Analysis", systemImage: "stop.circle")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    
                    if queue.hasPendingTasks {
                        Button(action: {
                            queue.pauseQueue()
                        }) {
                            Label("Pause Queue", systemImage: "pause.circle")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    
                    if queue.queueState == .paused {
                        Button(action: {
                            queue.resumeQueue()
                        }) {
                            Label("Resume Queue", systemImage: "play.circle")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    
                    if !queue.completedTasks.isEmpty || !queue.failedTasks.isEmpty {
                        Button(action: {
                            queue.clearHistory()
                        }) {
                            Label("Clear History", systemImage: "trash")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                }
                
                Spacer()
                
                // Close Button
                Button("Close") {
                    showQueueManagement = false
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding()
            .navigationBarHidden(true)
        }
        .alert("Stop Analysis", isPresented: $showCancelAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Stop", role: .destructive) {
                queue.stopAnalysis()
            }
        } message: {
            Text("Are you sure you want to stop the current analysis and clear the queue? This action cannot be undone.")
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
            }
            Button("Replace Current", role: .destructive) {
                if let image = pendingImage {
                    queue.stopAnalysis()
                    queue.enqueueImage(image)
                }
                pendingImage = nil
            }
        } message: {
            Text("An analysis is currently in progress. Would you like to add this image to the queue or replace the current analysis?")
        }
    }
    
    // MARK: - Computed Properties
    
    private var statusIcon: String {
        switch queue.queueState {
        case .idle:
            return "checkmark.circle"
        case .processing:
            return "arrow.clockwise"
        case .paused:
            return "pause.circle"
        case .stopped:
            return "stop.circle"
        }
    }
    
    private var statusColor: Color {
        switch queue.queueState {
        case .idle:
            return .green
        case .processing:
            return .blue
        case .paused:
            return .orange
        case .stopped:
            return .red
        }
    }
    
    private var statusText: String {
        switch queue.queueState {
        case .idle:
            return "Queue is idle"
        case .processing:
            return "Processing analysis"
        case .paused:
            return "Queue is paused"
        case .stopped:
            return "Analysis stopped"
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatEstimatedTime(_ time: TimeInterval) -> String {
        if time < 60 {
            return "\(Int(time))s"
        } else {
            let minutes = Int(time / 60)
            let seconds = Int(time.truncatingRemainder(dividingBy: 60))
            return "\(minutes)m \(seconds)s"
        }
    }
    
    // MARK: - Public Methods
    
    func handleNewImage(_ image: UIImage) {
        if queue.isProcessing || queue.hasPendingTasks {
            pendingImage = image
            showAddImageAlert = true
        } else {
            queue.enqueueImage(image)
        }
    }
}

// MARK: - Queue Info Row
struct QueueInfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Preview
struct QueueManagementView_Previews: PreviewProvider {
    static var previews: some View {
        QueueManagementView(
            queue: ImageAnalysisQueue(),
            showQueueManagement: .constant(true)
        )
    }
} 