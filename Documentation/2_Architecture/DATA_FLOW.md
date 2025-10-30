# Klick - Data Flow Architecture

**Last Updated**: October 30, 2025  
**Purpose**: Complete data flow diagrams and patterns

---

## 🔄 Overview

This document maps how data flows through Klick from user actions to UI updates, covering camera frames, state changes, and asynchronous operations.

---

## 📹 Camera Frame Processing Pipeline

### High-Level Flow

```
Camera Hardware
    ↓ [30 FPS]
AVCaptureVideoDataOutput
    ↓ [Sample Buffer Delegate]
CameraView.Coordinator
    ↓ [Frame Throttling - Every 3rd frame]
CVPixelBuffer Extraction
    ↓ [Background Queue]
Vision Framework
    ↓ [Face/Human Detection]
VNObservation Results
    ↓ [Coordinate Conversion]
CompositionManager
    ↓ [Service Evaluation]
CompositionResult
    ↓ [Main Queue]
SwiftUI State Update
    ↓ [Automatic Rendering]
UI Update (Overlays + Feedback)
```

### Detailed Frame Processing

```swift
// STEP 1: Frame Arrival (30 FPS)
func captureOutput(
    _ output: AVCaptureOutput,
    didOutput sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection
) {
    // STEP 2: Stability & Throttling Checks
    guard cameraReady else { return }
    guard currentTime - cameraStartTime > 1.0 else { return }  // Wait 1 sec
    
    frameCount += 1
    guard frameCount % 3 == 0 else { return }  // Process every 3rd frame
    
    // STEP 3: Extract Pixel Buffer
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
        return
    }
    
    // STEP 4: Background Processing (if enabled)
    if parent.isFacialRecognitionEnabled {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.performSubjectDetection(pixelBuffer: pixelBuffer)
        }
    }
}

// STEP 5: Vision Framework Detection
private func performSubjectDetection(pixelBuffer: CVPixelBuffer) {
    let faceRequest = VNDetectFaceRectanglesRequest { [weak self] request, error in
        guard let self = self else { return }
        
        if let results = request.results as? [VNFaceObservation],
           let face = results.first {
            // STEP 6: Composition Analysis
            self.evaluateComposition(
                observation: face, 
                pixelBuffer: pixelBuffer
            )
        } else {
            // STEP 6b: Fallback to Human Detection
            self.performHumanDetection(pixelBuffer: pixelBuffer)
        }
    }
    
    let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
    try? handler.perform([faceRequest])
}

// STEP 7: Evaluate Composition
private func evaluateComposition(
    observation: VNDetectedObjectObservation,
    pixelBuffer: CVPixelBuffer
) {
    let result = parent.compositionManager.evaluate(
        observation: observation,
        frameSize: parent.frameSize,
        pixelBuffer: pixelBuffer
    )
    
    // STEP 8: Update UI on Main Thread
    DispatchQueue.main.async {
        self.parent.feedbackMessage = result.feedbackMessage
        self.parent.showFeedback = true
        self.parent.compositionScore = result.score
    }
}
```

**Threading**:
- **Main Thread**: Frame arrival, UI updates
- **Background (.userInitiated)**: Vision processing, composition analysis
- **Automatic**: SwiftUI rendering

**Performance**:
- Frame rate: 30 FPS
- Processing rate: 10 FPS (every 3rd frame)
- Vision latency: 50-150ms
- Total feedback delay: 100-200ms

---

## 📸 Photo Capture Flow

### Complete Capture Pipeline

```
User Action
    ↓
[1] Button Tap Event (Main Thread)
    ↓
ContentView.capturePhoto()
    ↓
@State triggerCapture = true
    ↓
[2] SwiftUI Binding Update
    ↓
CameraView.updateUIView()
    ↓
Coordinator detects trigger change
    ↓
[3] Coordinator.capturePhoto()
    ↓
Configure AVCapturePhotoSettings
  ├─ Flash mode
  ├─ Quality settings
  └─ Codec selection
    ↓
[4] photoOutput.capturePhoto(with: settings)
    ↓
Camera Hardware Capture (200-500ms)
    ↓
[5] Delegate Callback: photoOutput(_:didFinishProcessingPhoto:)
    ↓
Extract image data
    ↓
Convert to UIImage
    ↓
[6] PhotoManager.shared.savePhoto(image)
    ↓
Save to Documents  ┌─────────────┐  Save to Photo Library
     ├─────────────┤ Concurrent  ├──────────────┤
     ↓             └─────────────┘              ↓
Generate UUID filename              PHPhotoLibrary.shared().performChanges()
Create JPEG (90% quality)                      ↓
Write to file                          PHAssetChangeRequest
     ↓                                         ↓
[7] Update @Published photos array    Permission check
     ↓                                         ↓
DispatchQueue.main.async              Success/Error
     ↓
[8] PhotoManager broadcasts change
     ↓
SwiftUI Automatic Updates:
  ├─ PhotoAlbumView (gallery updates)
  ├─ ContentView (gallery glimpse appears)
  └─ Haptic feedback triggers
```

### State Changes

| Step | State Variable | Owner | Effect |
|------|---------------|-------|--------|
| 1 | `triggerCapture` | ContentView | Button → true |
| 2 | (binding propagation) | CameraView | Receives trigger |
| 3 | (internal) | Coordinator | Initiates capture |
| 6 | `photos` array | PhotoManager | New photo added |
| 8 | `showGalleryGlimpse` | ContentView | Gallery appears |

**Timing**:
- Button tap → Capture start: <10ms
- Capture duration: 200-500ms
- File save: 50-150ms
- UI update: <16ms (1 frame)
- **Total**: ~500-1000ms

---

## 🎨 Composition Analysis Data Flow

### Analysis Trigger → UI Update

```
Vision Detection Complete
    ↓
VNDetectedObjectObservation
  ├─ boundingBox (subject location)
  ├─ confidence (detection quality)
  └─ uuid (tracking)
    ↓
[1] CompositionManager.evaluate()
    ↓
Select Active Service
  ├─ .ruleOfThirds → RuleOfThirdsService
  ├─ .centerFraming → CenterFramingService
  └─ .symmetry → CenterFramingService (symmetry mode)
    ↓
[2] Service.evaluate(observation, frameSize, pixelBuffer)
    ↓
Algorithm Processing:
  ├─ Calculate subject position
  ├─ Determine composition alignment
  ├─ Generate score (0.0-1.0)
  ├─ Create directional feedback
  └─ Generate overlay elements
    ↓
[3] Return CompositionResult
    {
        isWellComposed: Bool
        feedbackMessage: String
        overlayElements: [OverlayElement]
        score: Double
        compositionType: CompositionType
    }
    ↓
[4] Update @Published Properties
    ├─ lastResult = result
    └─ (Optional) currentCompositionType
    ↓
[5] SwiftUI Automatic Updates (Main Thread)
    ├─ ContentView.feedbackMessage updates
    │   └─ Feedback text appears with animation
    ├─ CompositionOverlayView re-renders
    │   └─ Grid/crosshair updates position
    └─ CompositionIndicatorView updates
        └─ Score/status indicator changes
```

### Composition Type Change Flow

```
User Selects New Type (e.g., Center Framing)
    ↓
[1] CompositionPickerView Button Action
    ↓
compositionManager.switchToCompositionType(.centerFraming)
    ↓
[2] CompositionManager Method
    ├─ currentCompositionType = .centerFraming  (@Published)
    ├─ lastResult = nil  (clear previous result)
    └─ (Service registry updates active service)
    ↓
[3] @Published Property Change Broadcasts
    ↓
[4] SwiftUI Automatic UI Updates:
    ├─ CompositionIndicatorView
    │   ├─ Icon changes (grid → crosshair)
    │   └─ Text updates
    ├─ CompositionOverlayView
    │   ├─ Remove old overlays (grid lines)
    │   ├─ Add new overlays (crosshair)
    │   └─ Animate transition (0.3s)
    └─ CameraView (next frame)
        └─ Uses new service for evaluation
```

---

## 📱 Settings State Propagation

### Toggle Change → Feature Update

```
User Toggles "Facial Recognition"
    ↓
[1] FrameSettingsView.Toggle
    ↓
@Binding var isFacialRecognitionEnabled
    ↓
[2] Binding Updates Parent
    ↓
ContentView: @State isFacialRecognitionEnabled = false
    ↓
[3] SwiftUI Binding Propagation
    ↓
CameraView(isFacialRecognitionEnabled: $isFacialRecognitionEnabled)
    ↓
[4] CameraView.updateUIView()
    ↓
coordinator.parent.isFacialRecognitionEnabled = false
    ↓
[5] Next Frame Processing
    ↓
captureOutput() checks:
if parent.isFacialRecognitionEnabled {
    performSubjectDetection()  // SKIPPED
}
    ↓
[6] Feature Disabled
    └─ No Vision processing
    └─ No composition analysis
    └─ Better battery life
```

### Settings State Flow Diagram

```
┌─────────────────┐
│  ContentView    │ (State Owner)
│  @State vars    │
└────────┬────────┘
         │
         ├─ Pass as @Binding
         │
         ▼
┌────────────────────┐
│ FrameSettingsView  │ (Modal)
│  @Binding vars     │
│  ┌──────────────┐  │
│  │   Toggle     │  │ ← User interaction
│  └──────────────┘  │
└────────┬───────────┘
         │
         └─ Updates binding → Updates ContentView @State
                              │
                              ├─ CameraView (receives binding)
                              │   └─ Behavior changes
                              │
                              └─ CompositionManager (direct property)
                                  └─ Analysis enabled/disabled
```

---

## 🖼️ Image Editing Data Flow

### Filter Application Pipeline

```
User Selects Filter
    ↓
[1] ImagePreviewView Filter Picker
    ↓
selectedFilter = "Bourbon 64"
    ↓
[2] Trigger Filter Application
    ↓
FilterManager.shared.applyFilter(filter, to: image)
    ↓
[3] LUTApplier.applyLUT()
    ├─ Load .CUBE file (cached)
    ├─ Parse LUT data
    ├─ Create CIFilter.colorCube
    ├─ Apply to CIImage
    └─ Render with Metal-accelerated CIContext
    ↓
[4] Return Filtered UIImage
    ↓
[5] Update State
@State var previewImage = filteredImage
    ↓
[6] SwiftUI Update
    └─ Image view re-renders with filtered image
```

### Background Blur Pipeline

```
User Adjusts Blur Slider
    ↓
[1] Slider Value Change (0-40)
@State var blurIntensity: Float = 15.0
    ↓
[2] Debounce (150ms)
    ├─ Cancel previous work item
    └─ Schedule new work item
    ↓
[3] BackgroundBlurManager.generateBlurPreview()
    ↓
[4] Person Segmentation (if not cached)
    ├─ VNGeneratePersonSegmentationRequest
    ├─ Quality: .accurate
    ├─ Process at preview resolution (400×600)
    └─ Generate mask (white=person, black=background)
    ↓
[5] Blur Application
    ├─ CIFilter.gaussianBlur (radius=blurIntensity)
    ├─ CIFilter.affineClamp (edge prevention)
    └─ Apply to background only
    ↓
[6] Mask Blending (Dual-Method)
    ├─ Method 1: CIFilter.blendWithMask
    │   └─ Composite sharp subject + blurred background
    └─ Method 2: Manual compositing (fallback)
        └─ (original × personMask) + (blurred × bgMask)
    ↓
[7] Cache Result
    ├─ maskCache.setObject(mask, forKey: key)
    └─ blurCache.setObject(result, forKey: key)
    ↓
[8] Update State
@State var previewImage = blurredImage
    ↓
[9] SwiftUI Update
    └─ Preview updates in real-time
```

**Performance**:
- Segmentation (cached): <1ms
- Segmentation (new): 15-25ms (preview), 200-400ms (full)
- Blur application: 10-20ms
- Total: 20-50ms for cached, 100-200ms for new

---

## 💾 Photo Management Data Flow

### Gallery Update Flow

```
PhotoManager.savePhoto() Called
    ↓
[1] Generate UUID Filename
filename = "\(UUID().uuidString).jpg"
    ↓
[2] JPEG Compression (90% quality)
jpegData = image.jpegData(compressionQuality: 0.9)
    ↓
[3] Concurrent Operations
    ├─────────────────┬─────────────────┐
    │                 │                 │
    ▼                 ▼                 ▼
Save to Documents  Update Array   Save to Library
FileManager write  @Published     PHPhotoLibrary
    │              photos.insert()     │
    │                   │              │
    └───────────────────┼──────────────┘
                        │
                        ▼
         [4] @Published Property Change
                        ↓
         [5] SwiftUI Automatic Updates
                        ↓
            ┌───────────┴───────────┐
            │                       │
            ▼                       ▼
    PhotoAlbumView          ContentView
    (Gallery grid)      (Gallery glimpse)
            │                       │
            └───────────┬───────────┘
                        │
                        ▼
              [6] UI Animations
                ├─ Gallery glimpse slides up
                ├─ Thumbnail appears in grid
                └─ Haptic feedback
```

### Photo Deletion Flow

```
User Confirms Delete
    ↓
[1] PhotoAlbumView.deletePhoto(photoItem)
    ↓
[2] PhotoManager.shared.deletePhoto(photoItem)
    ↓
[3] File System Operations
    ├─ FileManager.removeItem(at: photoItem.url)
    └─ Error handling
    ↓
[4] Update @Published Array
photos.removeAll { $0.id == photoItem.id }
    ↓
[5] @Published Change Broadcast
    ↓
[6] SwiftUI Automatic Update
    └─ PhotoAlbumView removes thumbnail
        └─ Animated removal transition
```

---

## 🔄 Asynchronous Operation Patterns

### Background Processing Pattern

```swift
// Pattern: Background work → Main thread UI update

// STEP 1: Dispatch to background
DispatchQueue.global(qos: .userInitiated).async { [weak self] in
    guard let self = self else { return }
    
    // STEP 2: Heavy processing
    let result = performExpensiveOperation()
    
    // STEP 3: Update UI on main thread
    DispatchQueue.main.async {
        self.updateState(result)  // Triggers SwiftUI update
    }
}
```

### Debounced Updates Pattern

```swift
// Pattern: Rapid user input → Debounced processing

private var workItem: DispatchWorkItem?

func handleRapidInput(value: Float) {
    // Cancel previous work
    workItem?.cancel()
    
    // Schedule new work
    let newWorkItem = DispatchWorkItem { [weak self] in
        guard let self = self else { return }
        self.processValue(value)
    }
    workItem = newWorkItem
    
    // Execute after delay
    DispatchQueue.main.asyncAfter(
        deadline: .now() + 0.15,
        execute: newWorkItem
    )
}
```

### Concurrent Operations Pattern

```swift
// Pattern: Parallel independent operations

async let task1 = performOperation1()
async let task2 = performOperation2()
async let task3 = performOperation3()

let (result1, result2, result3) = await (task1, task2, task3)

// All operations completed
processResults(result1, result2, result3)
```

---

## 📊 State Update Frequency Analysis

| Operation | Frequency | Thread | Latency |
|-----------|-----------|--------|---------|
| Camera frames | 30 FPS | Main | 33ms |
| Frame processing | 10 FPS | Background | 100-200ms |
| Composition updates | ~5-10 FPS | Main | <16ms |
| Slider changes | ~10-20/sec | Main | Debounced 150ms |
| Photo save | On-demand | Background | 200-500ms |
| Settings toggle | On-demand | Main | <16ms |

---

## 🎯 Data Flow Best Practices

### ✅ DO:
- Process heavy operations on background threads
- Update UI only on main thread
- Debounce rapid user inputs
- Use weak references in async closures
- Cache expensive computations
- Throttle high-frequency updates

### ❌ DON'T:
- Block main thread with heavy processing
- Update state in background threads (use DispatchQueue.main.async)
- Process every camera frame (throttle)
- Perform expensive operations on state changes
- Create retain cycles in closures
- Update UI faster than screen refresh rate (60 FPS)

---

## 📚 Related Documentation

- [STATE_MANAGEMENT.md](./STATE_MANAGEMENT.md) - State patterns
- [ARCHITECTURE_OVERVIEW.md](./ARCHITECTURE_OVERVIEW.md) - System architecture
- [COMPONENT_MAP.md](./COMPONENT_MAP.md) - Component relationships
- [Application Flows](../3_Application_Flows/FLOWS_INDEX.md) - End-to-end flows
- [PERFORMANCE_OVERVIEW.md](../6_Performance/PERFORMANCE_OVERVIEW.md) - Performance details

---

**Document Status**: ✅ Complete  
**Last Updated**: October 30, 2025  
**Maintained By**: Development Team

