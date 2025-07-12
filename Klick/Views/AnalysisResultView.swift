//
//  AnalysisResultView.swift
//  Klick
//
//  Created by AI Assistant on 12/07/2025.
//

import SwiftUI

struct AnalysisResultView: View {
    let analysisResult: CompositionAnalysisResult
    @State private var expandedSuggestion: CompositionRule?
    @Binding var showEducation: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Composition Analysis")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(analysisResult.detectedRules.count) composition rules detected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { showEducation = true }) {
                    Image(systemName: "book.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
            ScrollView {
                VStack(spacing: 15) {
                    // Detected Rules
                    if !analysisResult.detectedRules.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Detected Composition")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(analysisResult.detectedRules, id: \.self) { rule in
                                DetectedRuleCard(
                                    rule: rule,
                                    confidence: analysisResult.confidence[rule] ?? 0,
                                    suggestions: analysisResult.suggestions.filter { $0.rule == rule }
                                )
                            }
                        }
                    }
                    
                    // Suggestions
                    if !analysisResult.suggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Suggestions for Improvement")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(analysisResult.suggestions, id: \.message) { suggestion in
                                SuggestionCard(
                                    suggestion: suggestion,
                                    isExpanded: expandedSuggestion == suggestion.rule
                                ) {
                                    withAnimation {
                                        expandedSuggestion = expandedSuggestion == suggestion.rule ? nil : suggestion.rule
                                    }
                                }
                            }
                        }
                    }
                    
                    // Quick Stats
                    QuickStatsView(analysisResult: analysisResult)
                        .padding(.vertical)
                }
                .padding(.bottom, 20)
            }
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct DetectedRuleCard: View {
    let rule: CompositionRule
    let confidence: Float
    let suggestions: [CompositionSuggestion]
    
    var confidenceLevel: CompositionStrength {
        switch confidence {
        case 0.8...1.0: return .strong
        case 0.5..<0.8: return .moderate
        case 0.2..<0.5: return .weak
        default: return .notDetected
        }
    }
    
    var body: some View {
        HStack(spacing: 15) {
            // Icon
            Image(systemName: rule.icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Color.blue)
                .cornerRadius(10)
            
            // Content
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(rule.rawValue)
                        .font(.headline)
                    
                    Spacer()
                    
                    // Confidence badge
                    Text(confidenceLevel.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(confidenceLevel.color))
                        .cornerRadius(6)
                }
                
                if let firstSuggestion = suggestions.first {
                    Text(firstSuggestion.message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct SuggestionCard: View {
    let suggestion: CompositionSuggestion
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: suggestion.rule.icon)
                    .font(.body)
                    .foregroundColor(.orange)
                
                Text(suggestion.message)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            if isExpanded {
                Text(suggestion.improvementTip)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 25)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
        .onTapGesture(perform: onTap)
    }
}

struct QuickStatsView: View {
    let analysisResult: CompositionAnalysisResult
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Quick Stats")
                .font(.headline)
            
            HStack(spacing: 20) {
                StatItem(
                    icon: "face.smiling",
                    value: "\(analysisResult.faceObservations.count)",
                    label: "Faces"
                )
                
                StatItem(
                    icon: "scribble",
                    value: "\(analysisResult.contourObservations.count)",
                    label: "Contours"
                )
                
                StatItem(
                    icon: "rectangle.on.rectangle",
                    value: "\(analysisResult.rectangleObservations.count)",
                    label: "Shapes"
                )
                
                StatItem(
                    icon: "star.fill",
                    value: "\(analysisResult.detectedRules.count)",
                    label: "Rules"
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.headline)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
} 