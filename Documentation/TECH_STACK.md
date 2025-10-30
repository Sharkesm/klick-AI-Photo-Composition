# Klick - Technology Stack Reference

**Last Updated**: October 30, 2025  
**Version**: 1.0 MVP  
**Target Platform**: iOS 16.0+, iPhone 12+

---

## 📋 Quick Reference

| Category | Technology | Version | Purpose |
|----------|-----------|---------|---------|
| **UI Framework** | SwiftUI | iOS 16.0+ | Primary UI layer |
| **Camera** | AVFoundation | iOS 16.0+ | Camera capture & processing |
| **Computer Vision** | Vision Framework | iOS 16.0+ | Face/human detection, segmentation |
| **Image Processing** | Core Image | iOS 16.0+ | Filters, blur, effects |
| **GPU Acceleration** | Metal | iOS 16.0+ | GPU-accelerated processing |
| **Storage** | Photos Framework | iOS 16.0+ | Photo library integration |
| **Local Storage** | FileManager | iOS 16.0+ | Document directory storage |
| **Performance** | Accelerate | iOS 16.0+ | Vectorized operations |

---

## 🎨 User Interface Layer

### SwiftUI (iOS 16.0+)
**Purpose**: Modern declarative UI framework for all views

**Key Features Used**:
- `@State`, `@StateObject`, `@Published` for reactive state management
- `@Binding` for parent-child data flow
- `.sheet()`, `.fullScreenCover()` for modal presentations
- `.animation()` with spring and easing curves
- `.transition()` for view transitions
- `GeometryReader` for adaptive layouts
- `ZStack`, `VStack`, `HStack` for layout composition

**Implementation Files**:
- `Klick/Camera/Screen/ContentView.swift` - Main camera interface
- `Klick/LandingPageView.swift` - Onboarding experience
- `Klick/OnboardFlowView.swift` - Onboarding flow
- `Klick/PermissionFlowView.swift` - Permission handling
- `Klick/PhotoAlbum/PhotoAlbumView.swift` - Gallery interface
- `Klick/ImagePreview/Screen/ImagePreviewView.swift` - Image editing
- All view components in `Camera/Views/` and `Camera/Components/`

**Why SwiftUI**:
- Modern reactive programming model
- Automatic UI updates on state changes
- Less boilerplate than UIKit
- Better animation system
- Native iOS 16+ support

### UIKit Bridge (UIViewRepresentable)
**Purpose**: Bridge SwiftUI to UIKit for camera functionality

**Key Features Used**:
- `UIViewRepresentable` protocol for camera integration
- `Coordinator` pattern for delegate handling
- `makeUIView()` and `updateUIView()` lifecycle methods

**Implementation Files**:
- `Klick/Camera/Views/CameraView.swift` - Camera UIKit bridge

**Why UIKit Bridge**:
- AVFoundation camera APIs are UIKit-based
- Mature, stable camera implementation
- Better control over camera session
- Proven performance characteristics

---

## 📹 Camera & Video Processing

### AVFoundation (iOS 16.0+)
**Purpose**: Complete camera capture and video processing pipeline

#### Core Components Used:

**1. AVCaptureSession**
```swift
// Session configuration for photo capture
session.sessionPreset = .photo
```
- **Purpose**: Coordinates camera input and output
- **Configuration**: Photo preset for high-quality captures
- **Threading**: Runs on background thread
- **Location**: `CameraView.swift:130-147`

**2. AVCaptureDevice**
```swift
AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
```
- **Purpose**: Represents physical camera hardware
- **Type**: Wide-angle rear camera
- **Features**: Focus, exposure, flash control
- **Location**: `CameraView.swift:140-145`

**3. AVCaptureDeviceInput**
```swift
let input = try AVCaptureDeviceInput(device: camera)
```
- **Purpose**: Camera input connection to session
- **Location**: `CameraView.swift:148-152`

**4. AVCaptureVideoDataOutput**
```swift
videoOutput.setSampleBufferDelegate(coordinator, queue: DispatchQueue.global(qos: .userInitiated))
```
- **Purpose**: Real-time frame processing for composition analysis
- **Frame Rate**: Process every 3rd frame (throttled)
- **Thread**: Background queue (.userInitiated)
- **Location**: `CameraView.swift:166-185`

**5. AVCapturePhotoOutput**
```swift
let photoOutput = AVCapturePhotoOutput()
```
- **Purpose**: High-quality photo capture
- **Format**: HEVC/JPEG with quality prioritization
- **Features**: Flash control, orientation correction
- **Location**: `CameraView.swift:187-195`

**6. AVCaptureVideoPreviewLayer**
```swift
let previewLayer = AVCaptureVideoPreviewLayer(session: session)
previewLayer.videoGravity = .resizeAspectFill
```
- **Purpose**: Live camera preview display
- **Location**: `CameraView.swift:197-205`

#### Camera Settings & Controls:

**Flash Control**:
- Modes: `.auto`, `.on`, `.off`
- Device compatibility checking
- Location: `CameraView.swift:477-495`

**Focus & Exposure**:
- Tap-to-focus implementation
- Continuous autofocus when not locked
- Exposure adjustment on focus
- Location: `CameraView.swift:497-552`

**Photo Capture Settings**:
```swift
let settings = AVCapturePhotoSettings()
settings.flashMode = flashMode
settings.codec = photoCodec // HEVC/JPEG
```
- Location: `CameraView.swift:345-365`

**Threading Model**:
```
Main Thread: UI updates, session control
Background Thread: Session setup, frame processing
Global Queue: Vision framework processing
```

**Performance Optimizations**:
- Frame throttling (every 3rd frame): `CameraView.swift:124-153`
- Lazy initialization (1-second delay): `CameraView.swift:135-138`
- Background session startup: `CameraView.swift:206-210`

---

## 🧠 Computer Vision & AI

### Vision Framework (iOS 16.0+)
**Purpose**: Machine learning-powered subject detection and segmentation

#### Detection APIs Used:

**1. VNDetectFaceRectanglesRequest (Revision 3)**
```swift
let faceRequest = VNDetectFaceRectanglesRequest { request, error in
    // Face detection results
}
faceRequest.revision = VNDetectFaceRectanglesRequestRevision3
```
- **Purpose**: Primary face detection for composition analysis
- **Accuracy**: High precision for faces
- **Performance**: ~50-150ms per frame (device dependent)
- **Location**: `CameraView.swift:154-190`

**2. VNDetectHumanRectanglesRequest (Revision 2)**
```swift
let humanRequest = VNDetectHumanRectanglesRequest { request, error in
    // Full body detection
}
humanRequest.revision = VNDetectHumanRectanglesRequestRevision2
```
- **Purpose**: Fallback for full-body detection when no faces found
- **Use Case**: Environmental portraits, distant subjects
- **Location**: `CameraView.swift:191-220`

**3. VNGeneratePersonSegmentationRequest**
```swift
let segmentationRequest = VNGeneratePersonSegmentationRequest()
segmentationRequest.qualityLevel = .accurate
```
- **Purpose**: Person segmentation masks for background blur
- **Quality**: Accurate mode for best edge quality
- **Output**: Grayscale mask (white=person, black=background)
- **Performance**: 200-400ms full resolution, 15-25ms preview
- **Location**: `BackgroundBlurManager.swift:150-180`

#### Coordinate Space Handling:

**Vision → UIKit Conversion**:
```swift
// Vision: (0,0) = bottom-left, normalized coordinates
// UIKit: (0,0) = top-left, screen coordinates
```
- **Implementation**: `CameraView.swift:222-274`
- **Steps**: Denormalize → Flip Y → Scale to view
- **Challenges**: Aspect ratio handling, orientation correction

**VNImageRequestHandler**:
```swift
let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
try? handler.perform([faceRequest])
```
- **Purpose**: Execute Vision requests on pixel buffers
- **Threading**: Always on background queue
- **Location**: Various locations in `CameraView.swift`

#### Performance Characteristics:

| Request Type | Resolution | Time (iPhone 15 Pro) | Time (iPhone 13) |
|--------------|-----------|---------------------|------------------|
| Face Detection | 12MP | 80-120ms | 150-200ms |
| Human Detection | 12MP | 100-150ms | 200-300ms |
| Segmentation (Full) | 12MP | 200-300ms | 300-500ms |
| Segmentation (Preview) | 240K | 15-25ms | 25-40ms |

---

## 🎨 Image Processing & Effects

### Core Image (iOS 16.0+)
**Purpose**: GPU-accelerated image filtering and effects

#### CIContext Configuration:

**Metal-Accelerated Context**:
```swift
let context: CIContext = {
    if let metalDevice = MTLCreateSystemDefaultDevice() {
        return CIContext(mtlDevice: metalDevice, options: [
            .cacheIntermediates: true,
            .workingColorSpace: CGColorSpaceCreateDeviceRGB(),
            .outputPremultiplied: true,
            .useSoftwareRenderer: false
        ])
    }
    return CIContext(options: [...])
}()
```
- **Location**: `BackgroundBlurManager.swift:30-45`
- **Performance**: GPU acceleration when available
- **Fallback**: Software renderer on older devices

#### Filters Used:

**1. CIFilter.gaussianBlur()**
```swift
let blurFilter = CIFilter.gaussianBlur()
blurFilter.radius = blurIntensity // 0-40
```
- **Purpose**: Background blur effect
- **Range**: 0 (no blur) to 40 (max blur)
- **Location**: `BackgroundBlurManager.swift:185-195`

**2. CIFilter.affineClamp()**
```swift
let clampFilter = CIFilter.affineClamp()
```
- **Purpose**: Prevent edge artifacts during blur
- **Location**: `BackgroundBlurManager.swift:183-184`

**3. CIFilter.blendWithMask()**
```swift
let blendFilter = CIFilter.blendWithMask()
blendFilter.inputImage = sharpImage
blendFilter.backgroundImage = blurredImage
blendFilter.maskImage = personMask
```
- **Purpose**: Composite sharp subject with blurred background
- **Location**: `BackgroundBlurManager.swift:200-215`

**4. Custom LUT Filter (CIColorCube)**
```swift
let lutFilter = CIFilter.colorCube()
lutFilter.cubeDimension = size
lutFilter.cubeData = lutData
```
- **Purpose**: Professional color grading with .cube LUTs
- **Formats**: 32x32x32 or 64x64x64 color grids
- **Location**: `LUTApplier.swift:50-120`

#### LUT (Look-Up Table) System:

**LUT File Format**:
- Format: Adobe .cube format
- Size: 32x32x32 color grids (standard)
- Location: `Klick/Luts/*.CUBE` (42 professional LUTs)
- Implementation: `LUTApplier.swift`

**LUT Categories**:
- **Glow Pack** (7 filters): Bourbon, Teigen, Pitaya, etc.
- **Cine Pack** (13 filters): Neon, Azrael, Reeve, etc.
- **Aesthetic Pack** (9 filters): Clouseau, Hyla, Arabica, etc.

**Performance**:
- Preloading: Common LUTs loaded at app startup
- Caching: Parsed LUT data cached in memory
- Application: ~50-100ms per image
- Location: `FilterManager.swift`

---

## ⚡ GPU Acceleration & Performance

### Metal Framework (iOS 16.0+)
**Purpose**: Low-level GPU access for maximum performance

**Usage**:
- Core Image rendering backend
- Automatic GPU acceleration when available
- Memory-efficient texture management

**Implementation**:
```swift
if let metalDevice = MTLCreateSystemDefaultDevice() {
    context = CIContext(mtlDevice: metalDevice, options: [...])
}
```
- **Location**: `BackgroundBlurManager.swift:30-35`
- **Benefits**: 3-5x faster than CPU rendering
- **Fallback**: Automatic CPU rendering on unsupported devices

### Accelerate Framework (iOS 16.0+)
**Purpose**: Vectorized mathematical operations

**vDSP Operations Used**:
```swift
vDSP_vfill([UInt8(0)], &histogram, 1, vDSP_Length(256))
```
- **Purpose**: Fast histogram calculations for image analysis
- **Performance**: 10x faster than manual loops
- **Location**: Performance optimization docs reference

---

## 💾 Storage & Data Persistence

### FileManager (Foundation)
**Purpose**: Local file system storage for captured photos

**Storage Structure**:
```
~/Documents/CapturedPhotos/
├── [UUID].jpg  (Photo 1)
├── [UUID].jpg  (Photo 2)
└── [UUID].jpg  (Photo 3)
```

**Implementation**:
```swift
let photosDirectory = FileManager.default
    .urls(for: .documentDirectory, in: .userDomainMask)[0]
    .appendingPathComponent("CapturedPhotos")
```
- **Location**: `PhotoManager.swift:15-25`
- **Format**: JPEG with 90% compression
- **Naming**: UUID-based for uniqueness

**Operations**:
- Create directory: `PhotoManager.swift:20-25`
- Save photo: `PhotoManager.swift:30-65`
- Delete photo: `PhotoManager.swift:85-105`
- Load photos: `PhotoManager.swift:110-135`

### Photos Framework (PHPhotoLibrary)
**Purpose**: Integration with system Photo Library

**Features Used**:
- Permission management: `PHPhotoLibrary.authorizationStatus()`
- Photo saving: `PHPhotoLibrary.shared().performChanges()`
- Asset creation: `PHAssetChangeRequest.creationRequestForAsset(from:)`

**Implementation**:
```swift
PHPhotoLibrary.shared().performChanges({
    PHAssetChangeRequest.creationRequestForAsset(from: image)
}) { success, error in
    // Handle result
}
```
- **Location**: `PhotoManager.swift:67-83`
- **Permission**: Requested on first save attempt
- **Async**: Runs on background queue

---

## 🔄 State Management & Architecture

### SwiftUI State Management

**@State**
- **Purpose**: Local view state
- **Scope**: Single view
- **Example**: `@State private var showSettings = false`
- **Usage**: UI toggles, temporary state

**@StateObject**
- **Purpose**: Observable object ownership
- **Scope**: View creates and owns object
- **Example**: `@StateObject private var compositionManager = CompositionManager()`
- **Usage**: ViewModels, managers

**@Published**
- **Purpose**: Observable property changes
- **Scope**: Inside ObservableObject classes
- **Example**: `@Published var currentCompositionType: CompositionType`
- **Usage**: Shared state across views

**@Binding**
- **Purpose**: Two-way data binding
- **Scope**: Parent-child communication
- **Example**: `@Binding var isEnabled: Bool`
- **Usage**: Pass mutable state to child views

### MVVM + Service Layer Pattern

**Architecture**:
```
View (SwiftUI) ←→ ViewModel (ObservableObject) ←→ Service Layer
```

**Example**:
- View: `ContentView.swift`
- ViewModel: `CompositionManager.swift`
- Service: `CompositionService.swift` implementations

---

## 🧩 Design Patterns Used

### Protocol-Oriented Programming

**CompositionService Protocol**:
```swift
protocol CompositionService {
    var name: String { get }
    func evaluate(observation:, frameSize:, pixelBuffer:) -> CompositionResult
}
```
- **Implementations**: RuleOfThirdsService, CenterFramingService
- **Benefits**: Easy extensibility, testability
- **Location**: `CompositionService.swift`

### Coordinator Pattern

**CameraView.Coordinator**:
```swift
class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    var parent: CameraView
}
```
- **Purpose**: Bridge SwiftUI ↔ UIKit delegates
- **Location**: `CameraView.swift:70-120`

### Singleton Pattern

**Managers**:
- `PhotoManager.shared` - Photo storage management
- `FilterManager.shared` - Filter application
- `BackgroundBlurManager.shared` - Blur effects

### Observer Pattern

**NotificationCenter**:
```swift
NotificationCenter.default.addObserver(
    self,
    selector: #selector(handleMemoryWarning),
    name: UIApplication.didReceiveMemoryWarningNotification,
    object: nil
)
```
- **Purpose**: Memory pressure handling
- **Location**: `BackgroundBlurManager.swift`

---

## 🔧 Development Tools & Build System

### Xcode (15.0+)
**Purpose**: Primary IDE and build system

**Project Configuration**:
- Target: iOS 16.0+
- Swift Version: 5.9
- Build System: New Build System
- Project File: `Klick.xcodeproj/project.pbxproj`

### Swift Package Manager
**Status**: No external dependencies
- All functionality uses Apple frameworks
- No third-party libraries required
- Self-contained project

---

## 📊 Performance Monitoring

### Instruments Tools Used:
- **Time Profiler**: CPU usage and bottleneck identification
- **Allocations**: Memory usage and leak detection
- **System Trace**: Thread activity and system calls
- **Core Animation**: Frame rate and rendering performance

### Built-in Performance Tracking:
```swift
let startTime = CFAbsoluteTimeGetCurrent()
// ... operation ...
let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
print("Operation completed in \(duration)ms")
```
- Used throughout codebase for performance measurement

---

## 🎯 Platform Capabilities Used

### iOS 16.0+ Features:
- SwiftUI 4.0 features
- Vision framework improvements
- Photos framework enhancements
- Modern AVFoundation APIs

### Device Requirements:
- **Minimum**: iPhone 12
- **Recommended**: iPhone 13 or newer
- **Reason**: Camera quality, Neural Engine performance

### Hardware Features:
- Rear wide-angle camera
- A12 Bionic or newer (Neural Engine)
- Metal-capable GPU
- Minimum 4GB RAM

---

## 📚 Apple Documentation References

### Primary Frameworks:
- [SwiftUI](https://developer.apple.com/documentation/swiftui) - UI framework
- [AVFoundation](https://developer.apple.com/documentation/avfoundation) - Camera and media
- [Vision](https://developer.apple.com/documentation/vision) - Computer vision
- [Core Image](https://developer.apple.com/documentation/coreimage) - Image processing
- [Metal](https://developer.apple.com/documentation/metal) - GPU acceleration
- [Photos](https://developer.apple.com/documentation/photokit) - Photo library

### Secondary Frameworks:
- [Accelerate](https://developer.apple.com/documentation/accelerate) - Performance
- [Foundation](https://developer.apple.com/documentation/foundation) - Core utilities
- [UIKit](https://developer.apple.com/documentation/uikit) - UIKit bridge

---

## 🔮 Future Technology Considerations

### Potential Additions:
- **Core ML**: Custom composition models
- **ARKit**: AR composition overlays
- **WidgetKit**: Home screen widgets
- **App Clips**: Lightweight app experience
- **CloudKit**: Cloud storage and sync

### Planned Upgrades:
- SwiftUI async/await patterns
- Modern Swift Concurrency
- iOS 17+ features when minimum target increases

---

## 📋 Version Compatibility Matrix

| iOS Version | Support Status | Notes |
|-------------|----------------|-------|
| iOS 16.0 | ✅ Minimum | All features supported |
| iOS 16.1-16.7 | ✅ Full Support | Recommended |
| iOS 17.0+ | ✅ Enhanced | Better performance |
| iOS 15.x | ❌ Not Supported | Missing SwiftUI features |

---

**Document Status**: Complete  
**Maintained By**: Development Team  
**Review Frequency**: With each major iOS release  
**Related Docs**: [ARCHITECTURE_OVERVIEW.md](./2_Architecture/ARCHITECTURE_OVERVIEW.md), [DEVELOPER_GUIDE.md](./4_Development/DEVELOPER_GUIDE.md)

