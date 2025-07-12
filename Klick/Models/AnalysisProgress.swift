// New file defining progress information used by analyzer and UI
import Foundation

struct AnalysisProgress {
    let percent: Double            // 0…100
    let message: String            // e.g. "Analyzing grid-lines"
    var isCompleted: Bool { percent >= 100 }
} 
