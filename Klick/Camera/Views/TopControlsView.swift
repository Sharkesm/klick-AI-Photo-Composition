import SwiftUI

// MARK: - Top Controls View
struct TopControlsView: View {
    @ObservedObject var featureManager: FeatureManager
    
    
    @Binding var selectedCameraQuality: CameraQuality
    @Binding var selectedFlashMode: FlashMode
    @Binding var selectedZoomLevel: ZoomLevel
    @Binding var showFrameSettings: Bool
    @Binding var showCompositionPractice: Bool
    @Binding var showSalesPage: Bool
    @Binding var paywallSource: PaywallSource
    @Binding var showUpgradePrompt: Bool
    @Binding var showCameraQualityIntro: Bool
    @Binding var shouldAutoExpandCameraQuality: Bool
    
    let compositionManager: CompositionManager
    let hasCameraPermission: Bool
    let cameraLoading: Bool
    let hasShowedCameraQualityIntro: Bool
    
    var body: some View {
        // Top controls - composition indicator, quality selector and flash control
        if hasCameraPermission && !cameraLoading {
             VStack(spacing: 6) {
                 HStack(alignment: .top) {
                     Button(action: {
                         withAnimation(.easeInOut(duration: 0.3)) {
                             showFrameSettings = true
                         }
                     }) {
                         Image(systemName: "gear")
                             .font(.system(size: 15, weight: .semibold))
                             .foregroundColor(.white)
                     }
                     .frame(width: 42, height: 42)
                     .background(Color.black.opacity(0.5))
                     .clipShape(Capsule())
                     
                     Spacer()
                     VStack {
                         CompositionStylePracticeControl(showCompositionPractice: $showCompositionPractice)
                         
                         Spacer()
                             .frame(height: 130)
                         
                         CameraQualitySelectorView(
                            selectedQuality: $selectedCameraQuality,
                            shouldAutoExpand: $shouldAutoExpandCameraQuality,
                            shouldBlockExpansion: !hasShowedCameraQualityIntro,
                            onFirstInteraction: {
                                // Show intro sheet on first interaction
                                if !hasShowedCameraQualityIntro {
                                    withAnimation {
                                        showCameraQualityIntro = true
                                    }
                                }
                            },
                            onSelectionCompletion: {
                                if  featureManager.canUseAdvancedComposition { return }
                                
                                if selectedCameraQuality == .pro {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                        selectedCameraQuality = .standard
                                        showUpgradePrompt = true
                                    }
                                }
                            }
                         )
                         
                         FlashControlView(selectedFlashMode: $selectedFlashMode)
                         ZoomControlsView(selectedZoomLevel: $selectedZoomLevel)
                         
                         // Photo counter badge (free tier only)
                         if hasCameraPermission && !cameraLoading {
                             PhotoCounterBadge(featureManager: featureManager, showSalesPage: $showSalesPage, paywallSource: $paywallSource)
                         }
                         
                         Spacer()
                     }
                 }
                 .padding(.horizontal, 20)
                 .overlay(alignment: .top) {
                     if !featureManager.isPro {
                         /// Upgrade to Pro indicator
                         HStack {
                             Spacer()
                             
                            Button {
                                paywallSource = .topBarUpgrade
                                showSalesPage = true
                            } label: {
                                 HStack {
                                     Image(systemName: "crown.fill")
                                         .font(.system(size: 10, weight: .medium))
                                         .foregroundColor(.yellow)
                                     
                                     Text("Upgrade")
                                         .font(.system(size: 12, weight: .semibold, design: .default))
                                         .foregroundColor(.white)
                                 }
                                 .padding(.vertical, 6)
                                 .padding(.horizontal, 12)
                                 .background(Color.black)
                                 .cornerRadius(12)
                             }
                             .offset(y: 8)
                             Spacer()
                         }
                     }
                 }
                 
                Spacer()
            }
        }
    }
}
