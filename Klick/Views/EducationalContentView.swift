//
//  EducationalContentView.swift
//  Klick
//
//  Created by AI Assistant on 12/07/2025.
//

import SwiftUI

struct EducationalContentView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedRule: CompositionRule = .ruleOfThirds
    @State private var showingLessonDetail = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Learn Photography Composition")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Master the art of composition to take stunning photos")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    
                    // Composition Rules Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                        ForEach(CompositionRule.allCases, id: \.self) { rule in
                            CompositionRuleCard(rule: rule)
                                .onTapGesture {
                                    selectedRule = rule
                                    showingLessonDetail = true
                                }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Quick Tips Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Quick Tips")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        ForEach(quickTips, id: \.self) { tip in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                                
                                Text(tip)
                                    .font(.subheadline)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.vertical, 5)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.bottom, 30)
            }
            .navigationBarHidden(true)
            .overlay(alignment: .topTrailing) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingLessonDetail) {
            CompositionLessonDetailView(rule: selectedRule)
        }
    }
}

struct CompositionRuleCard: View {
    let rule: CompositionRule
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: rule.icon)
                .font(.largeTitle)
                .foregroundColor(.blue)
                .frame(height: 50)
            
            Text(rule.rawValue)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text(rule.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 180)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}

struct CompositionLessonDetailView: View {
    let rule: CompositionRule
    @Environment(\.dismiss) var dismiss
    @State private var currentExampleIndex = 0
    
    var lesson: CompositionLesson {
        getLesson(for: rule)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header with icon
                    HStack {
                        Image(systemName: rule.icon)
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text(rule.rawValue)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text(lesson.title)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    
                    // Overview
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Overview")
                            .font(.headline)
                        
                        Text(lesson.overview)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal)
                    
                    // Examples
                    if !lesson.examples.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Examples")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            TabView(selection: $currentExampleIndex) {
                                ForEach(lesson.examples.indices, id: \.self) { index in
                                    ExampleCard(example: lesson.examples[index])
                                        .tag(index)
                                }
                            }
                            .tabViewStyle(PageTabViewStyle())
                            .frame(height: 200)
                        }
                    }
                    
                    // Exercises
                    if !lesson.exercises.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Practice Exercises")
                                .font(.headline)
                            
                            ForEach(lesson.exercises.indices, id: \.self) { index in
                                HStack(alignment: .top, spacing: 10) {
                                    Text("\(index + 1).")
                                        .fontWeight(.semibold)
                                    
                                    Text(lesson.exercises[index])
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.vertical, 5)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Pro Tips
                    if !lesson.tips.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Pro Tips")
                                .font(.headline)
                            
                            ForEach(lesson.tips, id: \.self) { tip in
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                        .font(.caption)
                                    
                                    Text(tip)
                                        .font(.subheadline)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.vertical, 5)
                            }
                        }
                        .padding()
                        .background(Color.yellow.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 30)
            }
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ExampleCard: View {
    let example: String
    
    var body: some View {
        VStack {
            // Placeholder for example image
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(
                    colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .overlay(
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(.white.opacity(0.5))
                )
            
            Text(example)
                .font(.caption)
                .padding(.horizontal)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Educational Content Data
let quickTips = [
    "Take your time to compose before shooting",
    "Move around to find the best angle",
    "Look for natural frames in your environment",
    "Pay attention to the background",
    "Use negative space to emphasize your subject",
    "Break the rules once you understand them"
]

func getLesson(for rule: CompositionRule) -> CompositionLesson {
    switch rule {
    case .ruleOfThirds:
        return CompositionLesson(
            rule: rule,
            title: "The Foundation of Great Composition",
            overview: "The rule of thirds is one of the most fundamental principles in photography. By dividing your frame into nine equal sections with two horizontal and two vertical lines, you create four intersection points where the eye naturally gravitates. Placing your subject at these points or along these lines creates more dynamic and balanced compositions than centering everything.",
            examples: [
                "A portrait with the subject's eyes on the upper third line",
                "A landscape with the horizon on the lower third line",
                "A building placed on the right vertical third line"
            ],
            exercises: [
                "Take 10 photos placing different subjects on each intersection point",
                "Photograph the same subject centered and then on a third - compare the results",
                "Practice with landscapes, placing the horizon on different third lines"
            ],
            tips: [
                "Enable grid lines in your camera settings",
                "For portraits, place the eyes on the upper third line",
                "When in doubt, try multiple compositions"
            ]
        )
        
    case .leadingLines:
        return CompositionLesson(
            rule: rule,
            title: "Guide the Viewer's Journey",
            overview: "Leading lines are visual elements that guide the viewer's eye through your photograph. They can be literal lines like roads or fences, or implied lines created by the arrangement of objects. Leading lines create depth, movement, and help tell a visual story by directing attention to your main subject.",
            examples: [
                "A road leading to mountains in the distance",
                "Railway tracks converging at the horizon",
                "A river winding through a landscape"
            ],
            exercises: [
                "Find and photograph 5 different types of leading lines",
                "Use diagonal lines to create dynamic tension",
                "Combine leading lines with the rule of thirds"
            ],
            tips: [
                "Look for S-curves for a more natural flow",
                "Diagonal lines add energy and movement",
                "Leading lines don't always need to lead to a subject"
            ]
        )
        
    case .symmetry:
        return CompositionLesson(
            rule: rule,
            title: "Balance and Harmony",
            overview: "Symmetry creates a sense of balance and harmony in your photos. It can be vertical, horizontal, or radial. While perfect symmetry can be powerful, near-symmetry with a small breaking element can be even more interesting. Symmetry works especially well in architecture, reflections, and patterns.",
            examples: [
                "A building reflected in still water",
                "A centered portrait with balanced elements",
                "Architectural facades with repeating patterns"
            ],
            exercises: [
                "Find and photograph perfect symmetry in architecture",
                "Create symmetry using reflections in water or glass",
                "Break symmetry intentionally with one element"
            ],
            tips: [
                "Use a tripod for perfect alignment",
                "Small asymmetries can add interest",
                "Symmetry works great for formal compositions"
            ]
        )
        
    case .framing:
        return CompositionLesson(
            rule: rule,
            title: "Create Depth and Context",
            overview: "Framing involves using elements in the foreground to create a 'frame' around your main subject. This technique adds depth, context, and helps draw attention to your subject. Natural frames can include archways, trees, windows, or any object that surrounds your subject.",
            examples: [
                "A landscape viewed through an archway",
                "A portrait framed by tree branches",
                "A building framed by a window"
            ],
            exercises: [
                "Find 5 different natural frames in your environment",
                "Use shadows to create frames",
                "Experiment with partial frames"
            ],
            tips: [
                "Frames don't need to surround the entire subject",
                "Dark frames make subjects pop",
                "Ensure the frame enhances, not distracts"
            ]
        )
        
    case .goldenRatio:
        return CompositionLesson(
            rule: rule,
            title: "Nature's Perfect Proportion",
            overview: "The golden ratio (1.618:1) appears throughout nature and has been used in art for centuries. In photography, it's similar to the rule of thirds but with slightly different proportions. The golden spiral is particularly useful for creating naturally flowing compositions.",
            examples: [
                "A spiral staircase following the golden spiral",
                "A portrait with features aligned to golden proportions",
                "A seashell demonstrating natural golden ratio"
            ],
            exercises: [
                "Practice visualizing the golden spiral in scenes",
                "Compare golden ratio placement with rule of thirds",
                "Look for natural spirals in your environment"
            ],
            tips: [
                "The golden ratio is subtle - don't force it",
                "Works especially well with curves and spirals",
                "Combine with other composition techniques"
            ]
        )
        
    case .diagonals:
        return CompositionLesson(
            rule: rule,
            title: "Add Dynamic Energy",
            overview: "Diagonal lines and compositions create a sense of movement, energy, and dynamism in your photos. They break the static nature of horizontal and vertical lines, making images more engaging. Diagonals can be actual lines or created by the arrangement of subjects.",
            examples: [
                "A staircase shot from an angle",
                "Mountain ridges creating diagonal lines",
                "A tilted horizon for dramatic effect"
            ],
            exercises: [
                "Convert static scenes to diagonal compositions by changing angle",
                "Use diagonal lines to connect corners of the frame",
                "Combine multiple diagonals for complex compositions"
            ],
            tips: [
                "Diagonals from bottom-left to top-right feel ascending",
                "Multiple diagonals can create tension",
                "Don't overuse - it can be exhausting to view"
            ]
        )
        
    case .patterns:
        return CompositionLesson(
            rule: rule,
            title: "Rhythm and Repetition",
            overview: "Patterns create visual rhythm through repetition of elements. They can be found everywhere - in nature, architecture, and everyday objects. The key to great pattern photography is finding the right balance between repetition and variation, often by breaking the pattern with a contrasting element.",
            examples: [
                "Rows of windows on a building facade",
                "Repeating waves on a beach",
                "A field of flowers with one different color"
            ],
            exercises: [
                "Find and photograph 5 different patterns",
                "Break a pattern with one different element",
                "Fill the entire frame with a pattern"
            ],
            tips: [
                "Breaking the pattern creates a focal point",
                "Get close to emphasize the pattern",
                "Look for patterns in unexpected places"
            ]
        )
        
    case .fillTheFrame:
        return CompositionLesson(
            rule: rule,
            title: "Eliminate Distractions",
            overview: "Filling the frame means getting close to your subject to eliminate distracting elements and create impact. This technique forces viewers to engage with your subject's details and textures. It's particularly effective for portraits, wildlife, and detail shots.",
            examples: [
                "A close-up portrait showing just eyes and smile",
                "Macro photography of flower petals",
                "Wildlife photography filling frame with the animal"
            ],
            exercises: [
                "Take the same subject at 5 different distances",
                "Practice with portraits, getting progressively closer",
                "Use fill the frame for abstract compositions"
            ],
            tips: [
                "Don't be afraid to crop in camera",
                "Watch your focus when very close",
                "Leave some breathing room for portraits"
            ]
        )
    }
} 