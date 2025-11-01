# Klick - Component Relationship Map

**Last Updated**: October 30, 2025  
**Purpose**: Visual guide to component relationships and dependencies

---

## 🗺️ High-Level Component Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                          Klick App                                   │
│                      (KlickApp.swift)                                │
└────────────────────────────────┬────────────────────────────────────┘
                                 │
                                 │ First Launch
                                 │
                                 ▼
         ┌────────────────────────────────────────┐
         │         LandingPageView                │
         │     (Animated Gallery Intro)           │
         └────────────────┬───────────────────────┘
                          │
                          │ "Let's go"
                          │
                          ▼
         ┌────────────────────────────────────────┐
         │      OnboardingFlowView                │
         │   (7-Screen Narrative Flow)            │
         │  ┌──────────────────────────────────┐  │
         │  │ 1. Welcome                       │  │
         │  │ 2. Composition                   │  │
         │  │ 3. Posing                        │  │
         │  │ 4. Editing                       │  │
         │  │ 5. Achievement                   │  │
         │  │ 6. Pro Upsell ← Skip jumps here │  │
         │  │ 7. Personalization (Required)   │  │
         │  └──────────────────────────────────┘  │
         └────────────────┬───────────────────────┘
                          │
                          │ Complete
                          │
                          ▼
         ┌────────────────────────────────────────┐
         │       PermissionFlowView               │
         │  (Camera + Photo Library Access)       │
         └────────────────┬───────────────────────┘
                          │
                          │ Permissions Granted
                          │
                          ▼
         ┌────────────────────────────────────────┐
         │          ContentView                    │
         │      (Main Camera Screen)              │
         │  ┌──────────────────────────────────┐  │
         │  │  Camera System                   │  │
         │  │  Composition Analysis            │  │
         │  │  Photo Management                │  │
         │  │  UI Controls                     │  │
         │  └──────────────────────────────────┘  │
         └────────────────┬───────────────────────┘
                          │
         ┌────────────────┼────────────────┐
         │                │                │
         ▼                ▼                ▼
    Camera View    Photo Album      Image Preview
  (Capture Flow) (Gallery Flow)   (Editing Flow)
```

---

## 📱 Screen/View Component Hierarchy

### Primary Screens

```
App Entry Points:
├── KlickApp.swift (App lifecycle)
├── SceneDelegate.swift (Scene management)
└── AppDelegate.swift (App delegate)

Onboarding Flow:
├── LandingPageView.swift (Animated intro - entry point)
├── OnboardingFlowView.swift (7-screen narrative onboarding)
│   ├── OnboardingScreen1 (Welcome)
│   ├── OnboardingScreen2 (Composition)
│   ├── OnboardingScreen3 (Posing)
│   ├── OnboardingScreen4 (Editing)
│   ├── OnboardingScreen5_Achievement (Social proof)
│   ├── OnboardingScreen6_ProUpsell (Monetization)
│   └── OnboardingScreen7_Personalization (Goal selection)
├── PermissionFlowView.swift (Camera/photo permissions)
├── OnboardFlowView.swift (Legacy onboarding - deprecated)
└── OnboardingView.swift (Educational screens)

Main App Flow:
├── ContentView.swift (Main camera screen)
│   ├── CameraView.swift (Camera + Vision processing)
│   ├── CompositionOverlayView.swift (Visual overlays)
│   ├── FaceHighlightOverlayView.swift (Face boxes)
│   ├── GridOverlayView.swift (Composition grids)
│   ├── CompositionPickerView.swift (Type selector)
│   ├── FrameSettingsView.swift (Settings panel)
│   └── EducationalContentView.swift (Learning modals)
│
├── PhotoAlbumView.swift (Gallery screen)
│   ├── PhotoThumbnailView.swift (Grid items)
│   ├── PhotoDetailView.swift (Full-screen view)
│   ├── BasicDetailCard.swift (Photo info card)
│   ├── AnimatedIntroView.swift (Empty state)
│   └── AddPhotoCanvasView.swift (Add photo prompt)
│
└── ImagePreviewView.swift (Edit screen)
    ├── Filter controls
    ├── Blur controls
    ├── Export functionality
    └── 13 supporting view components
```

---

## 🧩 Detailed Component Dependencies

### ContentView (Main Coordinator)

**File**: `Klick/Camera/Screen/ContentView.swift`

**Role**: Main application coordinator and state manager

**Dependencies**:
```
ContentView
├── CameraView (Camera + Vision)
│   └── AVFoundation, Vision Framework
├── CompositionManager (Analysis coordinator)
│   └── CompositionService implementations
├── PhotoManager (Storage)
│   └── FileManager, PHPhotoLibrary
├── CompositionOverlayView (Visual guides)
├── PhotoAlbumView (Gallery)
└── Various UI components
```

**State Managed**:
- Camera permission status
- UI modal states (settings, pickers, education)
- Feedback messages and visibility
- Gallery glimpse state
- Face detection bounding boxes

**Provides to Children**:
- Composition manager (via @StateObject)
- Permission status (via @State + Binding)
- Capture triggers (via @State + Binding)
- Settings toggles (via @State + Binding)

---

### CameraView (Camera + Vision Processing)

**File**: `Klick/Camera/Views/CameraView.swift`

**Role**: Camera session management and real-time frame processing

**Architecture**:
```
CameraView (UIViewRepresentable)
├── makeUIView() → Creates camera preview
├── updateUIView() → Updates from SwiftUI state
└── Coordinator (Delegate handler)
    ├── AVCaptureSession management
    ├── AVCaptureVideoDataOutputSampleBufferDelegate
    ├── AVCapturePhotoCaptureDelegate
    └── Vision framework processing
```

**Dependencies**:
```
CameraView
├── AVFoundation
│   ├── AVCaptureSession
│   ├── AVCaptureDevice
│   ├── AVCaptureDeviceInput
│   ├── AVCaptureVideoDataOutput
│   ├── AVCapturePhotoOutput
│   └── AVCaptureVideoPreviewLayer
├── Vision Framework
│   ├── VNDetectFaceRectanglesRequest
│   ├── VNDetectHumanRectanglesRequest
│   └── VNImageRequestHandler
└── CompositionManager (from parent)
```

**Threading Model**:
```
Main Thread:
├── UI updates (state changes)
└── Session control (start/stop)

Background Thread (Global .userInitiated):
├── Frame processing
├── Vision framework requests
└── Composition analysis

Background Thread (Global .background):
└── Camera session setup
```

**Provides**:
- Live camera preview
- Real-time subject detection
- Frame data for composition analysis
- Photo capture capability
- Focus/exposure control

---

### CompositionManager (Analysis Coordinator)

**File**: `Klick/CompositionManager.swift`

**Role**: Centralized composition analysis coordination

**Architecture**:
```
CompositionManager (ObservableObject)
├── @Published currentCompositionType
├── @Published isEnabled
├── @Published lastResult
├── Service Registry
│   ├── RuleOfThirdsService
│   ├── CenterFramingService
│   └── (Future services)
└── Public API
    ├── evaluate()
    ├── switchToCompositionType()
    ├── getBasicOverlays()
    └── getBestCompositionSuggestion()
```

**Dependencies**:
```
CompositionManager
└── CompositionService implementations
    ├── RuleOfThirdsService
    └── CenterFramingService
```

**Used By**:
- ContentView (main coordinator)
- CameraView (frame analysis)
- CompositionPickerView (type selection)
- CompositionIndicatorView (status display)

**Data Flow**:
```
Vision Detection → CompositionManager.evaluate()
                          ↓
                  Select active service
                          ↓
                  Service.evaluate()
                          ↓
                  CompositionResult
                          ↓
                  Update @Published properties
                          ↓
                  SwiftUI automatic UI update
```

---

### CompositionService Protocol

**File**: `Klick/CompositionService.swift`

**Role**: Pluggable composition analysis techniques

**Protocol Definition**:
```swift
protocol CompositionService {
    var name: String { get }
    func evaluate(
        observation: VNDetectedObjectObservation,
        frameSize: CGSize,
        pixelBuffer: CVPixelBuffer?
    ) -> CompositionResult
}
```

**Implementations**:

#### 1. RuleOfThirdsService
```
RuleOfThirdsService
├── Grid calculation (3×3)
├── Intersection points (4 points)
├── Distance-based scoring
└── Directional guidance
```
**Location**: `CompositionService.swift:268-394`

#### 2. CenterFramingService
```
CenterFramingService
├── Geometric center calculation
├── Centering tolerance (12%)
├── Symmetry analysis (pixel-level)
└── Dual-method blending
```
**Location**: `CompositionService.swift:66-267`

**Extension Pattern**:
```
New Service Implementation:
1. Create class conforming to CompositionService
2. Implement name property
3. Implement evaluate() method
4. Register in CompositionManager
5. Add to CompositionType enum
6. Update UI picker
```

---

## 📸 Photo Management System

### Component Overview

```
Photo Lifecycle:
┌─────────────┐     ┌──────────────┐     ┌─────────────┐     ┌──────────────┐
│ CameraView  │ --> │ PhotoManager │ --> │ FileManager │     │ PHPhotoLib   │
│ (Capture)   │     │  (Storage)   │     │ (Documents) │     │  (Library)   │
└─────────────┘     └──────────────┘     └─────────────┘     └──────────────┘
                            │
                            ▼
                    ┌──────────────┐
                    │ PhotoAlbum   │
                    │  (Gallery)   │
                    └──────────────┘
                            │
                            ▼
                    ┌──────────────┐
                    │ ImagePreview │
                    │   (Editor)   │
                    └──────────────┘
```

### PhotoManager (Singleton)

**File**: `Klick/PhotoManager.swift`

**Role**: Centralized photo storage and management

**Architecture**:
```
PhotoManager (ObservableObject, Singleton)
├── @Published photos: [PhotoItem]
├── photosDirectory: URL
└── Methods
    ├── savePhoto()
    ├── deletePhoto()
    ├── deletePhotos()
    ├── loadPhotos()
    └── saveToPhotoLibrary()
```

**Storage Strategy**:
```
Documents/
└── CapturedPhotos/
    ├── [UUID-1].jpg (90% compression)
    ├── [UUID-2].jpg
    └── [UUID-3].jpg
```

**Dependencies**:
```
PhotoManager
├── FileManager (local storage)
├── PHPhotoLibrary (system library)
└── UIImage (image handling)
```

**Used By**:
- CameraView (save captured photos)
- PhotoAlbumView (display, delete)
- ImagePreviewView (load for editing)

---

### PhotoAlbumView (Gallery)

**File**: `Klick/PhotoAlbum/PhotoAlbumView.swift`

**Role**: Photo gallery with multiple interaction modes

**Component Structure**:
```
PhotoAlbumView
├── State: .hidden | .glimpse | .fullScreen
├── Grid Layout (3 columns)
├── PhotoThumbnailView (grid items)
│   └── Checkmark overlay (multi-select)
├── PhotoDetailView (full-screen)
│   ├── Image display
│   ├── BasicDetailCard (metadata)
│   └── Delete action
├── AnimatedIntroView (empty state)
└── Delete confirmation dialogs
```

**Dependencies**:
```
PhotoAlbumView
├── PhotoManager (data source)
└── Sub-components
    ├── PhotoThumbnailView
    ├── PhotoDetailView
    ├── BasicDetailCard
    └── AnimatedIntroView
```

**State Modes**:
1. **Hidden**: No photos captured yet
2. **Glimpse**: 80pt preview after first capture
3. **Full-Screen**: Complete gallery view

---

### ImagePreviewView (Editor)

**File**: `Klick/ImagePreview/Screen/ImagePreviewView.swift`

**Role**: Photo editing and export interface

**Component Structure**:
```
ImagePreviewView
├── Image Display
├── Filter Controls
│   ├── FilterManager integration
│   └── LUTApplier (42 filters)
├── Blur Controls
│   ├── BackgroundBlurManager
│   └── Intensity slider
├── Export Functionality
│   └── Save to library
└── 13 supporting UI components
```

**Dependencies**:
```
ImagePreviewView
├── FilterManager (filter application)
│   └── LUTApplier (LUT processing)
├── BackgroundBlurManager (blur effects)
│   ├── Vision (segmentation)
│   └── Core Image (blur + blend)
├── CompositionManager (analysis display)
├── PhotoManager (source images)
└── PHPhotoLibrary (export)
```

---

## 🎨 Overlay & Visual Components

### Overlay System Architecture

```
Overlay Rendering:
ContentView
└── CompositionOverlayView
    ├── Gets overlay elements from CompositionManager
    ├── Renders based on composition type
    └── Animates transitions
        ├── Grid overlay (Rule of Thirds)
        ├── Center crosshair (Center Framing)
        ├── Symmetry line (Symmetry)
        └── Guide lines (Dynamic)
```

**Component Files**:
- `CompositionOverlayView.swift` - Main overlay renderer
- `GridOverlayView.swift` - Grid-specific overlay
- `FaceHighlightOverlayView.swift` - Face bounding boxes

**Data Flow**:
```
CompositionService.evaluate()
    ↓ Returns overlay elements
CompositionResult.overlayElements
    ↓ Passed to view
CompositionOverlayView
    ↓ Renders with animation
SwiftUI Canvas
```

---

## 🎛️ Settings & Configuration

### Settings Architecture

```
Settings System:
ContentView (state owner)
├── @State isFacialRecognitionEnabled
├── @State areOverlaysHidden
└── CompositionManager.isEnabled (via StateObject)
    │
    └── FrameSettingsView (modal)
        ├── Toggle: Facial Recognition
        ├── Toggle: Live Analysis
        └── Toggle: Hide Overlays
```

**Files**:
- `Klick/Camera/Views/FrameSettingsView.swift`
- State managed in `ContentView.swift`

**Settings Flow**:
```
User toggles setting
    ↓
@State variable changes
    ↓
SwiftUI automatic binding update
    ↓
Child component receives new value
    ↓
Feature enabled/disabled
```

---

## 🎨 Filter & Effects System

### Filter Architecture

```
Filter System:
ImagePreviewView
└── FilterManager.shared (Singleton)
    ├── LUTApplier (Core Image LUT filter)
    │   ├── 42 .CUBE files
    │   ├── LUT parsing
    │   └── Core Image rendering
    ├── Filter caching
    └── Memory management
```

**Files**:
- `Klick/Services/FilterManager.swift` - Filter coordinator
- `Klick/LUTApplier.swift` - LUT application
- `Klick/Luts/*.CUBE` - 42 LUT files

**Dependencies**:
```
FilterManager
└── LUTApplier
    ├── Core Image (CIFilter.colorCube)
    └── Metal (GPU acceleration)
```

### Blur Effects Architecture

```
Blur System:
ImagePreviewView
└── BackgroundBlurManager.shared (Singleton)
    ├── Person Segmentation (Vision)
    │   └── VNGeneratePersonSegmentationRequest
    ├── Blur Application (Core Image)
    │   ├── CIFilter.gaussianBlur
    │   ├── CIFilter.affineClamp
    │   └── CIFilter.blendWithMask
    ├── Mask Cache (NSCache)
    ├── Blur Cache (NSCache)
    └── Session Management
```

**Files**:
- `Klick/BackgroundBlurManager.swift` - Blur coordinator
- Memory optimization strategies
- Dual-method mask blending

**Performance Features**:
- Preview resolution processing (400×600)
- Full resolution for final render
- Intelligent mask caching
- Session-based cleanup

---

## 🔄 State Flow Diagram

### Complete State Management Flow

```
App Launch
    ↓
KlickApp.swift (App entry)
    ↓
OnboardFlowView / PermissionFlowView
    ↓
LandingPageView (animated intro)
    ↓
ContentView (@State initialization)
    ├── @State camera permission
    ├── @State UI states
    └── @StateObject compositionManager
        ↓
CameraView (receives bindings)
    ├── Captures frames
    ├── Detects subjects (Vision)
    └── Triggers composition analysis
        ↓
CompositionManager.evaluate()
    ├── Selects active service
    ├── Calls service.evaluate()
    └── Updates @Published properties
        ↓
SwiftUI Automatic Updates
    ├── ContentView updates feedback
    ├── Overlays re-render
    └── Indicator updates
```

---

## 📊 Component Relationship Matrix

| Component | Depends On | Used By | State Type |
|-----------|-----------|---------|------------|
| **KlickApp** | None | iOS System | - |
| **ContentView** | CameraView, PhotoAlbum, CompositionManager | KlickApp | @State, @StateObject |
| **CameraView** | AVFoundation, Vision, CompositionManager | ContentView | UIViewRepresentable |
| **CompositionManager** | CompositionServices | ContentView, CameraView | ObservableObject |
| **PhotoManager** | FileManager, PHPhotoLibrary | CameraView, PhotoAlbum | ObservableObject, Singleton |
| **PhotoAlbumView** | PhotoManager | ContentView | @State |
| **ImagePreviewView** | FilterManager, BlurManager, PhotoManager | PhotoAlbum | @State |
| **FilterManager** | LUTApplier, Core Image | ImagePreview | Singleton |
| **BackgroundBlurManager** | Vision, Core Image | ImagePreview | Singleton |

---

## 🧪 Component Testing Map

### Unit Test Targets

```
CompositionManager
├── Test service switching
├── Test evaluation results
└── Test overlay generation

CompositionServices
├── Test rule of thirds calculation
├── Test center framing logic
└── Test symmetry analysis

PhotoManager
├── Test photo saving
├── Test photo deletion
├── Test file system operations
└── Test photo library integration

FilterManager
├── Test LUT loading
├── Test filter application
└── Test cache management

BackgroundBlurManager
├── Test mask generation
├── Test blur application
└── Test session management
```

---

## 🎯 Integration Points

### Cross-Component Communication

**Camera → Composition**:
```
CameraView detects face/human
    ↓
Calls CompositionManager.evaluate()
    ↓
Returns CompositionResult
    ↓
Updates ContentView state
```

**Camera → Photo Management**:
```
User taps capture button
    ↓
CameraView.capturePhoto()
    ↓
PhotoManager.savePhoto()
    ↓
Updates PhotoManager.photos array
    ↓
PhotoAlbumView automatically updates (SwiftUI)
```

**Photo Album → Image Editing**:
```
User selects photo from gallery
    ↓
PhotoAlbumView presents ImagePreviewView
    ↓
ImagePreviewView loads image
    ↓
User applies filters/blur
    ↓
Exports back to PhotoManager
```

---

## 🔮 Extension Points

### Adding New Features

**New Composition Rule**:
```
1. Create new service implementing CompositionService
2. Add to CompositionManager service registry
3. Add to CompositionType enum
4. Update CompositionPickerView UI
```

**New Filter**:
```
1. Add .CUBE file to Klick/Luts/
2. Add to FilterManager filter list
3. Update UI picker automatically
```

**New Photo Operation**:
```
1. Add method to PhotoManager
2. Update PhotoAlbumView UI if needed
3. Implement using FileManager/PHPhotoLibrary
```

---

## 📚 Related Documentation

- [ARCHITECTURE_OVERVIEW.md](./ARCHITECTURE_OVERVIEW.md) - Detailed architecture patterns
- [STATE_MANAGEMENT.md](./STATE_MANAGEMENT.md) - State management deep dive
- [DATA_FLOW.md](./DATA_FLOW.md) - Complete data flow diagrams
- [Application Flows](../3_Application_Flows/FLOWS_INDEX.md) - User journey flows

---

**Document Status**: ✅ Complete  
**Last Verified**: October 30, 2025  
**Maintained By**: Development Team

