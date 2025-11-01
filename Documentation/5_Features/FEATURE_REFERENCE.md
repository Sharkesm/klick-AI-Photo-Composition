# Klick - Feature Reference Guide

## 📋 Feature Overview

Comprehensive reference for all Klick features, including implementation details and code references.

---

## 🎬 Onboarding Experience

### Animated Landing Page
**Purpose**: Engaging introduction with photo gallery animation and smooth camera transition.

**Key Features**:
- Dual-row scrolling photo animation (15-second cycles)
- Sequential text and icon animations
- Circular reveal transition to onboarding or camera
- 10 curated photography samples from assets
- State management using `@AppStorage` for persistence

**Code Reference**: [`LandingPageView.swift`](Klick/LandingPageView.swift)

**User Flow**: Launch → Animated gallery → "Let's go" → Onboarding Flow

### Multi-Screen Onboarding Flow
**Purpose**: 7-screen narrative onboarding introducing app value, features, and personalization.

**Key Features**:
- **Progressive Disclosure**: Screens introduce composition, posing, editing, and achievements
- **Smart Skip Logic**: Skip button on intro screens (1-5) jumps to Pro Upsell, hidden on critical screens (6-7)
- **Sequential Animations**: Staggered content reveal (headline → description → hero image/features)
- **Asymmetric Transitions**: Directional slide animations based on navigation (forward/backward)
- **Pro Upsell Integration**: Conversion-focused screen with premium feature showcase
- **Goal Personalization**: Users select creative goals (stored in `@AppStorage`)
- **Consistent CTAs**: "Continue" button across all intro screens for predictable UX

**Code Reference**: [`OnboardingFlowView.swift`](Klick/OnboardingFlowView.swift)

**Screen Structure**:
1. **Welcome** - "Capture people, beautifully" (Hero image, value proposition)
2. **Composition** - "Frame like a pro" (Smart composition guides)
3. **Posing** - "Bring out your best side" (Expression tips and real-time feedback)
4. **Editing** - "Edit smarter, not harder" (Studio-quality filters and tools)
5. **Achievement** - "89% of users see improvement" (Social proof with success rate badge)
6. **Pro Upsell** - "Unlock your creative edge" (Premium features, two-CTA decision point)
7. **Personalization** - "What brings you here?" (Goal selection: selfies, pro shots, aesthetic feed, composition learning)

**Navigation Pattern**:
```
Screen 1-5: [← Back] [Progress Bar] [Skip →]
Screen 6: [← Back] [Progress Bar] (No skip - two CTAs)
Screen 7: [← Back] [Progress Bar] (No skip - required goal selection)
```

**Skip Behavior**:
- Screens 1-5: Skip → Jump to Pro Upsell (Screen 6)
- Screen 6: No skip button (use "Upgrade to Pro" or "Maybe later")
- Screen 7: No skip button (must select goal to continue)

**State Persistence**:
```swift
@AppStorage("onboardingIntroduction") var onboardingIntroduction: Bool
@AppStorage("onboardingFlowCompleted") var onboardingFlowCompleted: Bool
@AppStorage("hasSeenProUpsell") var hasSeenProUpsell: Bool
@AppStorage("userCreativeGoal") var userCreativeGoal: String
```

**Design Specifications**:
- **Hero Images**: 340pt height, 20pt corner radius, subtle shadows
- **Typography**: SF Rounded for headlines (32pt bold), 16pt regular for descriptions
- **Animations**: 0.6s easeOut for text, 0.7s spring for images
- **Colors**: White text on black background, golden yellow (1.0, 0.8, 0.0) for accents
- **Badge Design**: Success rate badge with lime green (124, 181, 24) background

**User Flow**: 
```
Landing Page → Welcome → Composition → Posing → Editing → Achievement → Pro Upsell → Personalization → Camera
                ↓
           (Skip Path)
                ↓
         Pro Upsell → Personalization → Camera
```

---

## 📹 Camera System

### Live Camera Feed
**Purpose**: Real-time camera preview with professional-grade performance.

**Key Features**:
- High-quality camera preview with minimal latency
- Background session initialization for smooth UI
- Proper aspect ratio handling and orientation support
- Memory-efficient preview layer management

**Code Reference**: [`CameraView.swift:21-147`](Klick/CameraView.swift)

### Camera Controls
**Purpose**: Interactive camera controls for better photo capture.

**Key Features**:
- **Tap-to-Focus**: Touch anywhere on screen to focus and adjust exposure
- **Flash Control**: Auto, on, or off flash modes with device compatibility
- **Focus Indicator**: Visual feedback showing focus point location
- **Quality Settings**: Configurable camera quality presets

**Code Reference**: [`CameraView.swift:477-517`](Klick/CameraView.swift)

### Permission Management
**Purpose**: Seamless permission handling with user-friendly error states.

**Key Features**:
- Automatic permission request on app launch
- Settings redirect for denied permissions
- Loading states during permission checks
- Graceful fallback for restricted access

**Code Reference**: [`ContentView.swift:246-302`](Klick/ContentView.swift)

---

## 📸 Photo Management System

### Photo Capture
**Purpose**: High-quality photo capture with professional camera settings.

**Key Features**:
- HEVC/JPEG format support with quality prioritization
- Flash mode integration (auto, on, off)
- Automatic image orientation correction
- Background processing for smooth UI performance

**Code Reference**: [`CameraView.swift:345-436`](Klick/CameraView.swift)

**Capture Flow**: Button press → Settings configuration → AVCapturePhotoOutput → Image processing → Storage

### Photo Storage & Management
**Purpose**: Local photo storage with efficient file management.

**Key Features**:
- Local storage in Documents directory with JPEG compression (90% quality)
- Automatic photo library integration (with user permission)
- UUID-based file naming system
- Thread-safe photo array management

**Code Reference**: [`PhotoManager.swift`](Klick/PhotoManager.swift)

**Storage Path**: `Documents/CapturedPhotos/[UUID].jpg`

### Photo Gallery
**Purpose**: Intuitive photo browsing with multiple interaction modes.

**Key Features**:
- **Grid Layout**: 3-column responsive grid with 12pt spacing
- **Three States**: Hidden → Glimpse (80pt) → Full-screen
- **Animated Intro**: Engaging empty state with stacked photo animation
- **Smooth Transitions**: Spring-based animations between states

**Code Reference**: [`PhotoAlbumView.swift`](Klick/PhotoAlbumView.swift)

**Interaction Flow**: 
- First capture → Glimpse appears → Tap to expand → Full gallery

### Photo Viewing & Details
**Purpose**: Full-screen photo viewing with metadata display.

**Key Features**:
- Aspect-fit photo display on black background
- Capture date and time information
- Navigation toolbar with close/delete actions
- Modal presentation with slide transition

**Code Reference**: [`PhotoAlbumView.swift:397-447`](Klick/PhotoAlbumView.swift)

### Photo Deletion System
**Purpose**: Flexible photo deletion with safety confirmations.

**Key Features**:
- **Individual Deletion**: Delete from photo detail view
- **Batch Deletion**: Multi-select mode with checkmark indicators
- **Safety Alerts**: Confirmation dialogs for all delete operations
- **File System Cleanup**: Automatic file removal from storage

**Code Reference**: [`PhotoAlbumView.swift:175-210`](Klick/PhotoAlbumView.swift)

**Deletion Flow**: Select → Confirm → File removal → UI update

---

## 🧠 Subject Detection System

### Multi-Tier Detection Pipeline
**Description**: Intelligent subject detection that prioritizes faces over general human detection.

**Code References**:
- [`CameraView.swift:154-220`](Klick/CameraView.swift) - Detection pipeline
- [`CameraView.swift:124-153`](Klick/CameraView.swift) - Frame processing logic

**Detection Hierarchy**:
1. **Face Detection** → `VNDetectFaceRectanglesRequest` (Primary)
2. **Human Detection** → `VNDetectHumanRectanglesRequest` (Fallback)
3. **No Subject** → Basic overlays only

**Performance Optimizations**:
```swift
// Frame throttling for performance
frameCount += 1
guard frameCount % 3 == 0 else { return }

// Lazy processing - wait for camera stability
guard currentTime - cameraStartTime > 1.0 else { return }

// Background processing
DispatchQueue.global(qos: .userInitiated).async {
    // Vision framework processing
}
```

### Face Highlighting
**Description**: Visual highlighting of detected faces with smooth animations.

**Code References**:
- [`FaceHighlightOverlayView.swift`](Klick/FaceHighlightOverlayView.swift) - Overlay implementation
- [`CameraView.swift:222-274`](Klick/CameraView.swift) - Coordinate conversion

**Features**:
- Real-time face bounding box overlay
- Smooth animation transitions
- Proper coordinate space conversion (Vision → Screen)
- Toggleable via settings

---

## 🎨 Composition Analysis System

### Modular Composition Services
**Description**: Plugin-style architecture supporting multiple composition techniques.

**Code References**:
- [`CompositionService.swift:1-394`](Klick/CompositionService.swift) - Complete service system
- [`CompositionManager.swift:1-163`](Klick/CompositionManager.swift) - Service orchestration

**Architecture**:
```swift
protocol CompositionService {
    var name: String { get }
    func evaluate(observation: VNDetectedObjectObservation, 
                 frameSize: CGSize, 
                 pixelBuffer: CVPixelBuffer?) -> CompositionResult
}
```

**Available Services**:

#### 1. Rule of Thirds Service
**Implementation**: [`CompositionService.swift:268-394`](Klick/CompositionService.swift)

**Features**:
- 3x3 grid overlay with intersection points
- 12% tolerance for easier alignment
- Distance-based scoring algorithm
- Directional feedback messages

**Algorithm**:
```swift
// Calculate intersection points
let intersections = [(0.33, 0.33), (0.33, 0.67), (0.67, 0.33), (0.67, 0.67)]

// Find nearest intersection and calculate score
let distances = intersections.map { intersection in
    sqrt(pow(centerX - intersection.0, 2) + pow(centerY - intersection.1, 2))
}
let score = max(0, 1 - (minDistance / maxPossibleDistance))
```

#### 2. Center Framing Service
**Implementation**: [`CompositionService.swift:66-267`](Klick/CompositionService.swift)

**Features**:
- Center crosshair overlay
- 15% tolerance zone for centering
- Advanced symmetry analysis using pixel comparison
- Directional guidance ("Move left & up")

**Symmetry Analysis**:
```swift
// Pixel-level vertical symmetry calculation
for y in 0..<height {
    for x in 0..<midWidth {
        let leftPixel = data[rowStart + x * 4]
        let rightPixel = data[rowStart + (width - 1 - x) * 4]
        totalDifference += abs(leftValue - rightValue)
    }
}
let similarity = 1.0 - (avgDifference / maxDifference)
```

### Composition Manager
**Description**: Central coordinator for composition analysis and service management.

**Code References**:
- [`CompositionManager.swift:7-163`](Klick/CompositionManager.swift) - Complete manager implementation

**Key Responsibilities**:
- Service lifecycle management
- Composition type switching
- Result caching and state management
- Overlay generation coordination

**Public API**:
```swift
func evaluate(observation:, frameSize:, pixelBuffer:) -> CompositionResult
func switchToCompositionType(_ type: CompositionType)
func getBasicOverlays(frameSize:) -> [OverlayElement]
func getBestCompositionSuggestion(...) -> CompositionType
```

---

## 🎯 Visual Feedback System

### Live Composition Feedback
**Description**: Real-time textual feedback based on composition analysis results.

**Code References**:
- [`ContentView.swift:141-169`](Klick/ContentView.swift) - Feedback UI
- [`CompositionService.swift:25-32`](Klick/CompositionService.swift) - CompositionResult structure

**Feedback Types**:
- ✅ **Success**: "Perfect thirds!", "Nice framing!"
- ⚠️ **Guidance**: "Move left & up", "Try placing subject on a third"
- 📍 **Directional**: Specific movement instructions

**Animation System**:
```swift
Text(message)
    .scaleEffect(showFeedback ? 1.0 : 0.01)
    .opacity(showFeedback ? 1.0 : 0.0)
    .animation(.spring, value: showFeedback)
```

### Dynamic Visual Overlays
**Description**: Adaptive overlay system that changes based on composition type and analysis results.

**Code References**:
- [`CompositionOverlayView.swift:1-125`](Klick/CompositionOverlayView.swift) - Overlay rendering
- [`ContentView.swift:47-74`](Klick/ContentView.swift) - Overlay integration

**Overlay Types**:

#### Grid Overlay (Rule of Thirds)
```swift
// Create 3x3 grid with proper proportions
let thirdX1 = width / 3, thirdX2 = width * 2 / 3
let thirdY1 = height / 3, thirdY2 = height * 2 / 3

path.move(to: CGPoint(x: thirdX1, y: 0))
path.addLine(to: CGPoint(x: thirdX1, y: height))
// ... additional grid lines
```

#### Center Crosshair (Center Framing)
```swift
// Create crosshair at frame center
let centerX = frameSize.width / 2
let centerY = frameSize.height / 2
let crosshairSize: CGFloat = 30

// Horizontal and vertical lines
path.move(to: CGPoint(x: centerX - crosshairSize, y: centerY))
path.addLine(to: CGPoint(x: centerX + crosshairSize, y: centerY))
```

**Rendering System**:
```swift
ForEach(Array(overlayElements.enumerated()), id: \.offset) { index, element in
    element.path
        .stroke(element.color.opacity(element.opacity), lineWidth: element.lineWidth)
        .animation(.easeInOut(duration: 0.3), value: compositionType)
}
```

---

## ⚙️ Settings & Configuration

### Frame Settings
**Description**: Comprehensive settings panel for customizing camera and analysis behavior.

**Code References**:
- [`FrameSettingsView.swift:1-200`](Klick/FrameSettingsView.swift) - Complete settings UI
- [`ContentView.swift:13-19`](Klick/ContentView.swift) - Settings state management

**Available Settings**:

#### 1. Facial Recognition Toggle
- **Purpose**: Enable/disable face detection
- **Impact**: Controls subject detection pipeline
- **UI**: Toggle with green accent color

#### 2. Live Analysis Toggle
- **Purpose**: Enable/disable composition analysis
- **Impact**: Controls feedback generation
- **UI**: Toggle with blue accent color
- **Binding**: Directly connected to `CompositionManager.isEnabled`

#### 3. Hide Overlays Toggle
- **Purpose**: Hide visual guides while keeping analysis active
- **Impact**: Toggles overlay visibility only
- **UI**: Toggle with purple accent color

**Settings UI Pattern**:
```swift
SettingRow(
    icon: "brain",
    title: "Live Analysis",
    description: "Enable real-time composition analysis and feedback...",
    isEnabled: $isCompositionAnalysisEnabled,
    accentColor: .blue
)
```

### Composition Type Picker
**Description**: Modal interface for switching between composition techniques.

**Code References**:
- [`CompositionPickerView.swift:1-120`](Klick/CompositionPickerView.swift) - Picker implementation
- [`CompositionIndicatorView.swift:1-27`](Klick/CompositionIndicatorView.swift) - Top indicator

**Features**:
- Visual cards for each composition type
- Real-time switching with smooth animations
- Top indicator showing current active type
- Accessible via bottom control bar

**Composition Types**:
1. **Rule of Thirds** (`squareshape.split.2x2.dotted`)
2. **Center Framing** (`plus.viewfinder`)
3. **Symmetry** (`rectangle.split.2x1`)

---

## 🎓 Educational Content System

### Educational Modal
**Description**: Interactive educational content explaining composition techniques.

**Code References**:
- [`EducationalContentView.swift:1-64`](Klick/EducationalContentView.swift) - Modal implementation

**Content Structure**:
- **Header**: Technique name with close button
- **Explanation**: Clear, beginner-friendly text
- **Visual Example**: Placeholder for example images
- **Dismissible**: Sheet presentation with medium detent

**Educational Approach**:
- Simple, jargon-free explanations
- Visual examples (placeholder for future images)
- Contextual presentation (accessible during camera use)

---

## 🔧 Performance & Optimization Features

### Frame Processing Optimization
**Description**: Multi-layered performance optimization for real-time analysis.

**Code References**:
- [`PERFORMANCE_OPTIMIZATIONS.md`](PERFORMANCE_OPTIMIZATIONS.md) - Detailed optimization guide
- [`CameraView.swift:124-153`](Klick/CameraView.swift) - Frame throttling implementation

**Optimization Strategies**:

#### 1. Frame Throttling
```swift
frameCount += 1
guard frameCount % 3 == 0 else { return }  // Process every 3rd frame
```

#### 2. Lazy Processing
```swift
guard currentTime - cameraStartTime > 1.0 else { return }  // Wait for stability
```

#### 3. Background Processing
```swift
DispatchQueue.global(qos: .userInitiated).async {
    // Vision framework processing on background queue
}
```

### Concurrent Analysis System
**Description**: Advanced concurrent processing for complex image analysis (future feature).

**Code References**:
- [`PERFORMANCE_OPTIMIZATIONS.md:22-45`](PERFORMANCE_OPTIMIZATIONS.md) - Concurrent processing details

**Improvements Achieved**:
- **Processing Time**: 4-7 minutes → 15-30 seconds (90%+ improvement)
- **Memory Usage**: 60% reduction through caching
- **UI Responsiveness**: Non-blocking background processing

---

## 🎮 User Interface Components

### Bottom Control Bar
**Description**: Primary interaction area with large, accessible touch targets.

**Code References**:
- [`ContentView.swift:172-215`](Klick/ContentView.swift) - Control bar implementation

**Controls**:
1. **Composition Picker** (Left): Switch between composition analysis modes
2. **Capture Button** (Center): High-quality photo capture with gallery preview
3. **Settings Button** (Right): Access camera and analysis settings

**Design Specifications**:
- **Touch Targets**: 60x60pt minimum (accessibility compliant)
- **Visual Style**: Semi-transparent black backgrounds
- **Spacing**: 40pt between controls for easy targeting

### Top Status Indicator
**Description**: Minimalist indicator showing current composition type.

**Code References**:
- [`CompositionIndicatorView.swift:1-27`](Klick/CompositionIndicatorView.swift) - Indicator implementation
- [`ContentView.swift:75-91`](Klick/ContentView.swift) - Indicator integration

**Features**:
- **Icon + Text**: Visual and textual indication
- **Capsule Design**: Rounded background with semi-transparency
- **Auto-Update**: Reflects composition manager state changes

---

## 🔄 State Management & Data Flow

### Application State Architecture
**Description**: Comprehensive state management using SwiftUI's reactive patterns.

**State Hierarchy**:
```
ContentView (Root State)
├── Camera State
│   ├── hasCameraPermission: Bool
│   ├── cameraLoading: Bool
│   └── permissionStatus: AVAuthorizationStatus
├── Detection State
│   ├── detectedFaceBoundingBox: CGRect?
│   └── isFacialRecognitionEnabled: Bool
├── Composition State (CompositionManager)
│   ├── currentCompositionType: CompositionType
│   ├── isEnabled: Bool
│   └── lastResult: CompositionResult?
└── UI State
    ├── showFeedback: Bool
    ├── feedbackMessage: String?
    └── Various modal states
```

### Data Flow Patterns
```
Camera Frame → Vision Processing → Composition Analysis → UI Update
     ↓              ↓                      ↓               ↓
 CVPixelBuffer → VNObservation → CompositionResult → SwiftUI State
```

---

## 🎯 Feature Integration Points

### Cross-Feature Dependencies
1. **Camera ↔ Detection**: Camera provides frames for subject detection
2. **Detection ↔ Composition**: Detected subjects drive composition analysis
3. **Composition ↔ UI**: Analysis results update visual feedback
4. **Settings ↔ All**: Settings control feature availability across app

### Extension Points for Future Features
1. **New Composition Services**: Implement `CompositionService` protocol
2. **Additional Detection**: Extend detection pipeline in `CameraView`
3. **Custom Overlays**: Add new `OverlayType` cases
4. **Advanced Settings**: Extend `FrameSettingsView` with new options

---

**Last Updated**: January 2025  
**Version**: 1.0 MVP  
**Maintainer**: Development Team 