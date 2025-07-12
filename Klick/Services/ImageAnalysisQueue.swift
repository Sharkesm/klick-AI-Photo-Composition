//
//  ImageAnalysisQueue.swift
//  Klick
//
//  Created by AI Assistant on 12/07/2025.
//

import Foundation
import UIKit
import SwiftUI
import Combine

// MARK: - Analysis Task
struct AnalysisTask: Identifiable {
    let id = UUID()
    let image: UIImage
    let priority: TaskPriority
    let createdAt: Date
    
    init(image: UIImage, priority: TaskPriority = .userInitiated) {
        self.image = image
        self.priority = priority
        self.createdAt = Date()
    }
}

// MARK: - Queue State
enum QueueState {
    case idle
    case processing
    case paused
    case stopped
}

// MARK: - Queue Events
enum QueueEvent {
    case taskStarted(AnalysisTask)
    case taskCompleted(AnalysisTask, CompositionAnalysisResult)
    case taskFailed(AnalysisTask, Error)
    case taskCancelled(AnalysisTask)
    case queueEmpty
    case queueStopped
}

// MARK: - Image Analysis Queue Service
class ImageAnalysisQueue: ObservableObject {
    @Published var queueState: QueueState = .idle
    @Published var currentTask: AnalysisTask?
    @Published var pendingTasks: [AnalysisTask] = []
    @Published var completedTasks: [AnalysisTask] = []
    @Published var failedTasks: [AnalysisTask] = []
    
    let analyzer = CompositionAnalyzer()
    private var currentTaskHandle: Task<Void, Never>?
    private var cancellationToken: CancellationToken?
    
    private var cancellables = Set<AnyCancellable>()

    // Event callbacks
    var onEvent: ((QueueEvent) -> Void)?
    
    init() {
        setupAnalyzerCallbacks()
    }
    
    // MARK: - Public Interface
    
    /// Add a new image to the analysis queue
    func enqueueImage(_ image: UIImage, priority: TaskPriority = .userInitiated) {
        let task = AnalysisTask(image: image, priority: priority)
        pendingTasks.append(task)
        
        print("📋 Added image to queue. Queue size: \(pendingTasks.count)")
        
        // Start processing if not already running
        if queueState == .idle {
            processNextTask()
        }
    }
    
    /// Stop the current analysis and clear the queue
    func stopAnalysis() {
        print("🛑 Stopping image analysis...")
        
        // Cancel current task
        if let currentTask = currentTask {
            cancelCurrentTask()
            onEvent?(.taskCancelled(currentTask))
        }
        
        // Clear pending tasks
        pendingTasks.removeAll()
        
        // Update state
        queueState = .stopped
        currentTask = nil
        
        print("✅ Analysis stopped. Queue cleared.")
        onEvent?(.queueStopped)
    }
    
    /// Pause the queue (current task continues, new tasks won't start)
    func pauseQueue() {
        queueState = .paused
        print("⏸️ Queue paused")
    }
    
    /// Resume the queue
    func resumeQueue() {
        if queueState == .paused {
            queueState = .processing
            processNextTask()
            print("▶️ Queue resumed")
        }
    }
    
    /// Clear all completed and failed tasks
    func clearHistory() {
        completedTasks.removeAll()
        failedTasks.removeAll()
        print("🗑️ Analysis history cleared")
    }
    
    // MARK: - Private Methods
    
    private func setupAnalyzerCallbacks() {
        // Monitor analyzer state changes
        analyzer.$analysisState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleAnalyzerStateChange(state)
            }
            .store(in: &cancellables)
    }
    
    private func processNextTask() {
        guard queueState != .stopped && queueState != .paused else { return }
        guard !pendingTasks.isEmpty else {
            queueState = .idle
            currentTask = nil
            onEvent?(.queueEmpty)
            return
        }
        
        // Get next task (FIFO for now, could be enhanced with priority)
        let task = pendingTasks.removeFirst()
        currentTask = task
        queueState = .processing
        
        print("🔄 Starting analysis for task \(task.id)")
        onEvent?(.taskStarted(task))
        
        // Create cancellation token for this task
        cancellationToken = CancellationToken()
        
        // Start analysis in background
        currentTaskHandle = Task.detached(priority: task.priority) { [weak self] in
            guard let self = self else { return }
            
            // Check for cancellation before starting
            if self.cancellationToken?.isCancelled == true {
                await MainActor.run {
                    self.handleTaskCancellation(task)
                }
                return
            }
            
            // Start the analysis
            await MainActor.run {
                self.analyzer.analyzeImage(task.image)
            }
        }
    }
    
    private func handleAnalyzerStateChange(_ state: AnalysisState) {
        guard let currentTask = currentTask else { return }
        
        switch state {
        case .completed(let result):
            print("✅ Analysis completed for task \(currentTask.id)")
            completedTasks.append(currentTask)
            onEvent?(.taskCompleted(currentTask, result))
            self.currentTask = nil
            processNextTask()
            
        case .failed(let error):
            print("❌ Analysis failed for task \(currentTask.id): \(error)")
            failedTasks.append(currentTask)
            onEvent?(.taskFailed(currentTask, error))
            self.currentTask = nil
            processNextTask()
            
        case .analyzing:
            // Analysis in progress, no action needed
            break
            
        case .idle:
            // Analysis reset, no action needed
            break
        }
    }
    
    private func cancelCurrentTask() {
        // Cancel the task handle
        currentTaskHandle?.cancel()
        currentTaskHandle = nil
        
        // Cancel the analyzer
        analyzer.cancelAnalysis()
        
        // Cancel the token
        cancellationToken?.cancel()
        cancellationToken = nil
    }
    
    private func handleTaskCancellation(_ task: AnalysisTask) {
        print("🚫 Task \(task.id) was cancelled")
        onEvent?(.taskCancelled(task))
        currentTask = nil
        processNextTask()
    }
    
    // MARK: - Queue Information
    
    var queueSize: Int {
        return pendingTasks.count
    }
    
    var isProcessing: Bool {
        return queueState == .processing
    }
    
    var hasPendingTasks: Bool {
        return !pendingTasks.isEmpty
    }
    
    var estimatedTimeRemaining: TimeInterval {
        // Rough estimate: 30 seconds per task
        let averageTimePerTask: TimeInterval = 30.0
        return TimeInterval(pendingTasks.count) * averageTimePerTask
    }
}

// MARK: - CancellationToken
class CancellationToken {
    private var isCancelledFlag = false
    private let lock = NSLock()
    
    var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return isCancelledFlag
    }
    
    func cancel() {
        lock.lock()
        defer { lock.unlock() }
        isCancelledFlag = true
    }
}
