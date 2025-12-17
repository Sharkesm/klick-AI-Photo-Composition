import SwiftUI

struct CompositionPickerView: View {
    @ObservedObject var compositionManager: CompositionManager
    @Binding var isPresented: Bool
    @ObservedObject var featureManager: FeatureManager
    
    // Check if a composition type is locked (for visual indication only)
    // Note: Selection is now allowed, but capture will be blocked in ContentView
    private func isCompositionLocked(_ type: CompositionType) -> Bool {
        // Rule of Thirds is always free
        if type == .ruleOfThirds {
            return false
        }
        // Advanced compositions show as locked if user can't use them
        // But selection is still allowed - capture will be gated separately
        return !featureManager.canUseAdvancedComposition
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        Text("Composition Style")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                        
                        Text("Choose your preferred composition technique")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                    }
                    .padding(.top, 24)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                    
                    // Composition options
                    LazyVStack(spacing: 20) {
                        ForEach(CompositionType.allCases, id: \.self) { type in
                            CompositionOptionRow(
                                type: type,
                                isSelected: type == compositionManager.currentCompositionType,
                                isLocked: isCompositionLocked(type),
                                onTap: {
                                    // Allow selection of any composition type
                                    // Capture will be gated in ContentView.capturePhoto()
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        compositionManager.switchToCompositionType(type)
                                    }
                                    
                                    // If selecting a locked composition, inform user that capture requires upgrade
                                    if isCompositionLocked(type) {
                                        // Note: We don't show prompt here since user can still preview
                                        // The prompt will show when they try to capture
                                        print("ℹ️ Selected advanced composition (\(type.displayName)) - capture will require Pro")
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            isPresented = false
                        }
                    }
                }
            }
        }
    }
}

struct CompositionOptionRow: View {
    let type: CompositionType
    let isSelected: Bool
    let isLocked: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 16) {
                // Icon with lock overlay
                ZStack(alignment: .bottomTrailing) {
                    Image(systemName: type.icon)
                        .font(.system(size: 24))
                        .foregroundColor(isLocked ? .gray : (isSelected ? .white : .primary))
                        .frame(width: 50, height: 50)
                        .background(isLocked ? Color.gray.opacity(0.2) : (isSelected ? Color.blue : Color.gray.opacity(0.2)))
                        .clipShape(Circle())
                        .padding(.top, 4) // Align with text baseline
                        .opacity(isLocked ? 0.4 : 1.0)
                    
                    // Lock icon
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .padding(4)
                            .background(
                                Circle()
                                    .fill(Color.orange)
                            )
                            .offset(x: 4, y: -4)
                    }
                }
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    // Title row with checkmark or PRO badge
                    HStack(alignment: .center, spacing: 12) {
                        Text(type.displayName)
                            .font(.headline)
                            .foregroundColor(isLocked ? .gray : .primary)
                            .lineLimit(nil)
                            .multilineTextAlignment(.leading)
                        
                        // PRO badge for locked items
                        if isLocked {
                            Text("PRO")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [.orange, .pink],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                        }
                        
                        Spacer()
                        
                        // Selection indicator aligned with title
                        if !isLocked {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                                .opacity(isSelected ? 1.0 : 0.0)
                        }
                    }
                    
                    // Description (unaffected by checkmark)
                    Text(isLocked ? "Unlock with Pro to use this composition technique" : descriptionFor(type))
                        .font(.caption)
                        .foregroundColor(isLocked ? .gray.opacity(0.7) : .secondary)
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isLocked ? Color.gray.opacity(0.05) : (isSelected ? Color.blue.opacity(0.1) : Color.clear))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isLocked ? Color.gray.opacity(0.2) : (isSelected ? Color.blue : Color.gray.opacity(0.3)), lineWidth: 1)
                    )
            )
            .opacity(isLocked ? 0.6 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func descriptionFor(_ type: CompositionType) -> String {
        switch type {
        case .ruleOfThirds:
            return "Perfect for portraits! Place eyes on grid intersections for dynamic, professional-looking shots 📸"
        case .centerFraming:
            return "Great for headshots and formal portraits! Center your subject for balanced, powerful compositions 💪"
        case .symmetry:
            return "Ideal for architectural backdrops! Create striking photos by aligning faces with symmetrical elements ✨"
        }
    }
}
