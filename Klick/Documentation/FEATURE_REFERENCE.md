# Klick - Feature Reference Guide

## 📋 Feature Overview

This document provides detailed information about each feature in Klick, including implementation details, code references, and usage patterns.

---

## 🎬 Onboarding & Landing Experience

### Animated Landing Page
**Description**: Immersive onboarding experience with scrolling photo gallery and smooth transition to camera.

**Code References**:
- [`LandingPageView.swift:1-321`](Klick/LandingPageView.swift) - Complete implementation
- [`KlickApp.swift:12-16`](Klick/KlickApp.swift) - App entry point

**Key Features**:
- Dual-row scrolling photo animation
- Sequential text and icon animations
- Circular reveal transition to camera
- 10 sample photography images from assets

**Implementation Details**:
```swift
// Dual-row animation with opposite directions
withAnimation(.linear(duration: 15).repeatForever(autoreverses: true)) {
    scrollOffset1 = -UIScreen.main.bounds.width / 1.5  // Left to right
    scrollOffset2 = -100  // Right to left
}

// Circular reveal transition
ContentView()
    .mask(
        Circle()
            .scaleEffect(fillCircle ? 50 : 0.01)
            .animation(.spring(response: 1.0, dampingFraction: 0.75))
    )
```

**User Journey**: Launch → Animated gallery → "Let's go" → Circular transition → Camera

---

## 📹 Camera System

### Real-Time Camera Feed
**Description**: High-performance camera preview with minimal latency and proper aspect ratio handling.

**Code References**:
- [`CameraView.swift:1-305`](Klick/CameraView.swift) - Complete camera implementation
- [`CameraView.swift:21-95`](Klick/CameraView.swift) - Session setup

**Technical Implementation**:
```swift
// Asynchronous camera setup to avoid UI blocking
DispatchQueue.global(qos: .userInitiated).async {
    self.setupCameraSession(for: view, context: context)
}

// High-quality session configuration
session.sessionPreset = .photo
connection.videoOrientation = .portrait
previewLayer.videoGravity = .resizeAspectFill
```

**Performance Features**:
- Background session initialization
- Proper orientation handling
- Memory-conscious preview layer management
- Graceful permission handling

### Camera Permission Management
**Description**: Comprehensive permission handling with user-friendly error states.

**Code References**:
- [`ContentView.swift:246-302`](Klick/ContentView.swift) - Permission logic
- [`ContentView.swift:100-140`](Klick/ContentView.swift) - Permission UI states

**Permission States**:
- **Not Determined**: Show loading, request permission
- **Authorized**: Initialize camera immediately
- **Denied/Restricted**: Show settings redirect UI

**UI States**:
```swift
if permissionStatus == .denied || permissionStatus == .restricted {
    // Settings redirect UI
    Button("Open Settings") {
        UIApplication.shared.open(UIApplication.openSettingsURLString)
    }
} else {
    // Loading state with progress indicator
    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
}
```

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
1. **Composition Picker** (Left): Switch composition types
2. **Capture Button** (Center): Photo capture (placeholder)
3. **Settings Button** (Right): Access frame settings

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