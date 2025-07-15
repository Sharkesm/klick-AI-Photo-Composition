import SwiftUI

struct CompositionPickerView: View {
    @ObservedObject var compositionManager: CompositionManager
    @Binding var isPresented: Bool
    
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
                                onTap: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        compositionManager.switchToCompositionType(type)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                    
                    // Analysis toggle
                    VStack(spacing: 16) {
                        Divider()
                            .padding(.horizontal, 20)
                        
                        HStack(alignment: .top, spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Composition Analysis")
                                    .font(.headline)
                                    .lineLimit(nil)
                                
                                Text("Enable real-time composition feedback")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(nil)
                                    .multilineTextAlignment(.leading)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Toggle("", isOn: $compositionManager.isEnabled)
                                .toggleStyle(SwitchToggleStyle())
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Composition")
            .navigationBarTitleDisplayMode(.inline)
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

struct CompositionOptionRow: View {
    let type: CompositionType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 16) {
                // Icon
                Image(systemName: type.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .primary)
                    .frame(width: 50, height: 50)
                    .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                    .clipShape(Circle())
                    .padding(.top, 4) // Align with text baseline
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    // Title row with checkmark
                    HStack(alignment: .center, spacing: 12) {
                        Text(type.rawValue)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(nil)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        // Selection indicator aligned with title
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                            .opacity(isSelected ? 1.0 : 0.0)
                    }
                    
                    // Description (unaffected by checkmark)
                    Text(descriptionFor(type))
                        .font(.caption)
                        .foregroundColor(.secondary)
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
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func descriptionFor(_ type: CompositionType) -> String {
        switch type {
        case .ruleOfThirds:
            return "Place subjects at intersection points of the grid for dynamic balance and visual interest"
        case .centerFraming:
            return "Center subjects in the frame for formal, balanced compositions with symmetrical elements"
        case .symmetry:
            return "Create harmonious images by aligning subjects with symmetrical elements in the scene"
        }
    }
}

#Preview {
    CompositionPickerView(
        compositionManager: CompositionManager(),
        isPresented: .constant(true)
    )
} 
