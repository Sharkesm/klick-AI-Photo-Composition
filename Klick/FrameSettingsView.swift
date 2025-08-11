import SwiftUI

struct FrameSettingsView: View {
    @Binding var isPresented: Bool
    @Binding var isFacialRecognitionEnabled: Bool
    @Binding var isCompositionAnalysisEnabled: Bool
    @Binding var areOverlaysHidden: Bool
    @ObservedObject var compositionManager: CompositionManager
    @State private var showOnboarding = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "viewfinder")
                            .font(.system(size: 32))
                            .foregroundColor(.blue)
                        
                        Text("Frame Settings")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                        
                        Text("Configure your camera frame analysis preferences")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                    }
                    .padding(.top, 24)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                    
                    // Settings sections
                    VStack(spacing: 20) {
                        // Facial Recognition Setting
                        SettingRow(
                            icon: "face.dashed",
                            title: "Facial Recognition",
                            description: "Detect and highlight faces in the camera frame. This helps with subject tracking and positioning guides.",
                            isEnabled: $isFacialRecognitionEnabled,
                            accentColor: .green
                        )
                        
                        Divider()
                        
                        // Composition Analysis Setting
                        SettingRow(
                            icon: "brain",
                            title: "Live Analysis",
                            description: "Enable real-time composition analysis and feedback. Processes camera frames to provide shooting guidance.",
                            isEnabled: $isCompositionAnalysisEnabled,
                            accentColor: .blue
                        )
                        .onChange(of: isCompositionAnalysisEnabled) { newValue in
                            compositionManager.isEnabled = newValue
                        }
                        
                        Divider()
                        
                        // Hide Overlays Setting
                        SettingRow(
                            icon: "eye.slash",
                            title: "Hide Overlays",
                            description: "Hide all composition guide overlays (grids, crosshairs, etc.) while keeping live analysis active.",
                            isEnabled: $areOverlaysHidden,
                            accentColor: .purple
                        )
                    
                        Divider()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                
                    // How Klick Works Section
                    VStack(spacing: 16) {
                        Button(action: {
                            showOnboarding = true
                        }) {
                            HStack(alignment: .center, spacing: 16) {
                                Image(systemName: "questionmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.blue)
                                    .frame(width: 50, height: 50)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("How Klick Works")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    Text("Learn about Klick's features and composition tips")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 24)
                    
                    // Performance Info Section
//                    VStack(spacing: 16) {
//                        InfoSection(
//                            icon: "speedometer",
//                            title: "Performance Impact",
//                            description: "Disabling live analysis improves battery life and camera performance. Hiding overlays has minimal impact.",
//                            color: .orange
//                        )
//                    }
//                    .padding(.horizontal, 20)
//                    .padding(.bottom, 24)
                    
                    MadeWithLoveView(location: "🇹🇿")
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showOnboarding) {
                OnboardingView(isPresented: $showOnboarding)
            }
        }
    }
}

struct SettingRow: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isEnabled: Bool
    let accentColor: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(isEnabled ? accentColor : .secondary)
                .frame(width: 50, height: 50)
                .background(isEnabled ? accentColor.opacity(0.1) : Color.gray.opacity(0.1))
                .clipShape(Circle())
                .padding(.top, 4) // Align with text baseline
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Title row with toggle
                HStack(alignment: .center, spacing: 12) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    // Toggle aligned with title
                    Toggle("", isOn: $isEnabled)
                        .tint(accentColor)
                        .toggleStyle(SwitchToggleStyle())
                }
                
                // Description (unaffected by toggle)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

struct InfoSection: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.1))
                .clipShape(Circle())
                .padding(.top, 4) // Align with text baseline
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                
                Text(description)
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
                .fill(color.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    FrameSettingsView(
        isPresented: .constant(true),
        isFacialRecognitionEnabled: .constant(true),
        isCompositionAnalysisEnabled: .constant(true),
        areOverlaysHidden: .constant(false),
        compositionManager: CompositionManager()
    )
} 
