import SwiftUI

struct FrameSettingsView: View {
    @Binding var isPresented: Bool
    @Binding var isFacialRecognitionEnabled: Bool
    @Binding var isCompositionAnalysisEnabled: Bool
    @Binding var areOverlaysHidden: Bool
    @Binding var isLiveFeedbackEnabled: Bool
    @ObservedObject var compositionManager: CompositionManager
    @ObservedObject var featureManager: FeatureManager
    @State private var showOnboarding = false
    @State private var viewStartTime: Date?
    let onShowSalesPage: ((PaywallSource) -> Void)? // Callback to show sales page with source
    let onDismiss: (() -> Void)? // Callback when view dismisses
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "viewfinder")
                            .font(.system(size: 32))
                            .foregroundColor(.yellow)
                        
                        Text("Frame Settings")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(Color.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Configure your camera frame analysis preferences")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
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
                        .onChange(of: isFacialRecognitionEnabled) { newValue in
                            Task {
                                await EventTrackingManager.shared.trackSettingsFacialRecognitionToggled(enabled: newValue)
                            }
                        }
                        
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
                            Task {
                                await EventTrackingManager.shared.trackSettingsLiveAnalysisToggled(enabled: newValue)
                            }
                        }
                        
                        Divider()
                        
                        // Live Feedback Setting
                        SettingRow(
                            icon: "message.badge",
                            title: "Live Feedback",
                            description: "Show real-time composition feedback messages. Disable to reduce distractions while keeping visual guides active.",
                            isEnabled: $isLiveFeedbackEnabled,
                            isLocked: !featureManager.canUseLiveFeedback,
                            accentColor: .orange,
                            onToggleAttempt: {
                                // If user tries to enable while locked
                                if !featureManager.canUseLiveFeedback && isLiveFeedbackEnabled == false {
                                    print("🔒 Live Feedback blocked - requires Pro")
                                    onShowSalesPage?(.frameSettingsLiveFeedback)
                                    return false // Prevent toggle
                                }
                                return true // Allow toggle
                            }
                        )
                        .onChange(of: isLiveFeedbackEnabled) { newValue in
                            let wasGated = !featureManager.canUseLiveFeedback
                            Task {
                                await EventTrackingManager.shared.trackSettingsLiveFeedbackToggled(
                                    enabled: newValue,
                                    wasGated: wasGated
                                )
                            }
                        }
                        
                        Divider()
                        
                        // Hide Overlays Setting
                        SettingRow(
                            icon: "eye.slash",
                            title: "Hide Overlays",
                            description: "Hide all composition guide overlays (grids, crosshairs, etc.) while keeping live analysis active.",
                            isEnabled: $areOverlaysHidden,
                            isLocked: !featureManager.canHideOverlays,
                            accentColor: .purple,
                            onToggleAttempt: {
                                // If user tries to enable while locked
                                if !featureManager.canHideOverlays && areOverlaysHidden == false {
                                    print("🔒 Hide Overlays blocked - requires Pro")
                                    onShowSalesPage?(.frameSettingsHideOverlays)
                                    return false // Prevent toggle
                                }
                                return true // Allow toggle
                            }
                        )
                        .onChange(of: areOverlaysHidden) { newValue in
                            let wasGated = !featureManager.canHideOverlays
                            Task {
                                await EventTrackingManager.shared.trackSettingsHideOverlaysToggled(
                                    enabled: newValue,
                                    wasGated: wasGated
                                )
                            }
                        }
                        
                        Divider()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                
                    // How Klick Works Section
                    VStack(spacing: 16) {
                        Button(action: {
                            Task {
                                await EventTrackingManager.shared.trackSettingsHowKlickWorksTapped()
                            }
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
                                        .foregroundColor(.blue)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    Text("Learn about Klick's features and composition tips")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.blue)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue.opacity(0.15))
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
            .background(Color(hue: 232/255, saturation: 20/255, brightness: 18/255))
            .sheet(isPresented: $showOnboarding) {
                OnboardingView(isPresented: $showOnboarding)
            }
            .onAppear {
                // Track settings viewed
                viewStartTime = Date()
                Task {
                    await EventTrackingManager.shared.trackSettingsFrameViewed()
                }
            }
            .onDisappear {
                // Track settings dismissed
                if let startTime = viewStartTime {
                    let timeSpent = Date().timeIntervalSince(startTime)
                    Task {
                        await EventTrackingManager.shared.trackSettingsFrameDismissed(timeSpent: timeSpent)
                    }
                }
                onDismiss?()
            }
        }
    }
}

struct SettingRow: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isEnabled: Bool
    var isLocked: Bool = false
    var hideSwitchControl: Bool = false
    let accentColor: Color
    var onToggleAttempt: (() -> Bool)? = nil // Returns true if toggle should proceed
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.1))
                )
                .padding(.top, 4) // Align with text baseline
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Title row with toggle
                HStack(alignment: .center, spacing: 12) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium, design: .default))
                        .foregroundColor(isLocked ? .white.opacity(0.5) : .white)
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                    
                    // Pro badge for locked features
                    if isLocked {
                        Text("PRO")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.yellow)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.yellow.opacity(0.2))
                            )
                    }
                    
                    Spacer()
                    
                    if !hideSwitchControl {
                        // Toggle aligned with title
                        Toggle("", isOn: Binding(
                            get: { isEnabled },
                            set: { newValue in
                                // Check if toggle should proceed
                                if let shouldProceed = onToggleAttempt?(), !shouldProceed {
                                    return // Block the toggle
                                }
                                isEnabled = newValue
                            }
                        ))
                        .tint(.green)
                        .toggleStyle(SwitchToggleStyle())
                        .disabled(isLocked && !isEnabled) // Disable if locked and currently off
                    }
                }
                
                // Description (unaffected by toggle)
                Text(description)
                    .font(.caption)
                    .foregroundColor(isLocked ? .white.opacity(0.5) : .white.opacity(0.8))
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
