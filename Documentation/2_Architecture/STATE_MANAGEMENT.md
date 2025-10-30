# Klick - State Management Guide

**Last Updated**: October 30, 2025  
**Purpose**: Comprehensive guide to state management patterns in Klick

---

## 🎯 Overview

Klick uses **SwiftUI's reactive state management** combined with the **MVVM pattern** to create a predictable, maintainable state architecture.

---

## 📊 State Management Hierarchy

```
┌─────────────────────────────────────────────────────┐
│              Root App State                         │
│                KlickApp.swift                       │
└───────────────────┬─────────────────────────────────┘
                    │
    ┌───────────────┴──────────────┐
    │                              │
    ▼                              ▼
┌─────────────┐            ┌──────────────┐
│ OnboardFlow │            │ ContentView  │
│   State     │            │  (Main App)  │
└─────────────┘            └──────┬───────┘
                                  │
                    ┌─────────────┼─────────────┐
                    │             │             │
                    ▼             ▼             ▼
            ┌────────────┐ ┌──────────┐ ┌──────────┐
            │ CameraView │ │PhotoAlbum│ │ImagePreview│
            └────────────┘ └──────────┘ └──────────┘
```

---

## 🔄 SwiftUI State Property Wrappers

### @State - Local View State

**Purpose**: Manage simple, private state within a single view

**Scope**: Single view only

**Lifetime**: Tied to view lifecycle

**Example**:
```swift
struct ContentView: View {
    @State private var showSettings = false
    @State private var feedbackMessage: String?
    @State private var cameraLoading = true
    
    var body: some View {
        VStack {
            if cameraLoading {
                ProgressView()
            }
            
            Button("Settings") {
                showSettings.toggle()  // Triggers view update
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
}
```

**Best Practices**:
- Use `private` access control
- Keep state local to view
- Simple value types (Bool, String, Int, etc.)
- Don't pass `@State` directly to other views (use `@Binding` instead)

**Use Cases in Klick**:
- Modal presentation states (`showSettings`, `showCompositionPicker`)
- Loading states (`cameraLoading`)
- Temporary UI states (`showFeedback`)

**Location Examples**:
- `ContentView.swift:13-25` - Main app state
- `PhotoAlbumView.swift:20-35` - Gallery state

---

### @StateObject - Observable Object Ownership

**Purpose**: Create and own an ObservableObject

**Scope**: View creates and manages object lifecycle

**Lifetime**: Persists across view updates

**Example**:
```swift
struct ContentView: View {
    @StateObject private var compositionManager = CompositionManager()
    
    var body: some View {
        CameraView(compositionManager: compositionManager)
        
        // CompositionManager stays alive as long as ContentView exists
        // Even if view body re-evaluates, same instance is used
    }
}

class CompositionManager: ObservableObject {
    @Published var currentCompositionType: CompositionType = .ruleOfThirds
    @Published var isEnabled = true
    @Published var lastResult: CompositionResult?
    
    func switchToCompositionType(_ type: CompositionType) {
        currentCompositionType = type  // Automatically triggers UI update
    }
}
```

**Best Practices**:
- Use when view is the **owner** of the object
- Object persists across view updates
- Prefer `@StateObject` over `@ObservedObject` for ownership
- Initialize inline or in init

**Use Cases in Klick**:
- `CompositionManager` - Composition analysis coordinator
- View-specific managers

**Location Examples**:
- `ContentView.swift:12` - CompositionManager ownership
- `ImagePreviewView.swift:25` - Preview-specific state

---

### @ObservedObject - Observable Object Reference

**Purpose**: Observe an ObservableObject owned by another view

**Scope**: View observes but doesn't own

**Lifetime**: Managed by owner

**Example**:
```swift
struct CameraView: UIViewRepresentable {
    @ObservedObject var compositionManager: CompositionManager
    
    // CameraView doesn't own compositionManager
    // It's passed from ContentView
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, compositionManager: compositionManager)
    }
}
```

**Best Practices**:
- Use when object is passed from parent
- Don't create object in view using `@ObservedObject`
- Parent manages lifecycle

**Use Cases in Klick**:
- Passing managers to child views
- Shared state across view hierarchy

**Location Examples**:
- `CameraView.swift:68` - Observes passed CompositionManager

---

### @Published - Observable Properties

**Purpose**: Mark ObservableObject properties that trigger view updates

**Scope**: Inside ObservableObject classes

**Behavior**: Changes automatically trigger UI updates

**Example**:
```swift
class CompositionManager: ObservableObject {
    @Published var currentCompositionType: CompositionType = .ruleOfThirds
    @Published var isEnabled = true
    @Published var lastResult: CompositionResult?
    
    func evaluate(...) -> CompositionResult {
        let result = currentService.evaluate(...)
        lastResult = result  // Automatically triggers UI update
        return result
    }
}

class PhotoManager: ObservableObject {
    @Published var photos: [PhotoItem] = []
    
    func savePhoto(_ image: UIImage) {
        let photoItem = PhotoItem(url: fileURL, date: Date())
        photos.insert(photoItem, at: 0)  // UI automatically updates
    }
}
```

**Best Practices**:
- Only mark properties that should trigger updates
- Keep expensive computations outside @Published properties
- Use `willSet` or `didSet` for side effects if needed

**Use Cases in Klick**:
- Composition type changes
- Photo array updates
- Analysis results

**Location Examples**:
- `CompositionManager.swift:11-15` - Composition state
- `PhotoManager.swift:12` - Photos array

---

### @Binding - Two-Way Data Binding

**Purpose**: Create a two-way connection to a parent's state

**Scope**: Child view modifies parent state

**Syntax**: Pass with `$` prefix

**Example**:
```swift
// Parent View
struct ContentView: View {
    @State private var isEnabled = true
    
    var body: some View {
        SettingsView(isEnabled: $isEnabled)  // Pass binding with $
    }
}

// Child View
struct SettingsView: View {
    @Binding var isEnabled: Bool
    
    var body: some View {
        Toggle("Enable Feature", isOn: $isEnabled)
        // Changes here update parent's @State
    }
}
```

**Best Practices**:
- Use for parent-child state sharing
- Pass with `$` prefix from parent
- Child can read and write
- Prefer `@Binding` over callbacks for simple state

**Use Cases in Klick**:
- Camera settings (flash, quality)
- Feature toggles (facial recognition, overlays)
- Capture trigger

**Location Examples**:
- `CameraView.swift:57-62` - Camera bindings
- `FrameSettingsView.swift:15-20` - Settings toggles

---

## 🏗️ Singleton Pattern for Managers

### When to Use Singletons

**Criteria**:
- App-wide shared state
- Resource management (caches, queues)
- System service wrappers

### Singleton Implementation in Klick

```swift
// PhotoManager - Photo storage
class PhotoManager: ObservableObject {
    static let shared = PhotoManager()
    
    @Published var photos: [PhotoItem] = []
    private let photosDirectory: URL
    
    private init() {
        // Initialize storage
    }
}

// FilterManager - Filter application
class FilterManager {
    static let shared = FilterManager()
    
    private let lutApplier = LUTApplier()
    private let filterCache: NSCache<NSString, UIImage>
    
    private init() {
        // Setup caches
    }
}

// BackgroundBlurManager - Blur effects
class BackgroundBlurManager {
    static let shared = BackgroundBlurManager()
    
    private let context: CIContext
    private let maskCache: NSCache<NSString, CIImage>
    
    private init() {
        // Setup Metal context
    }
}
```

**Benefits**:
- Single source of truth
- Resource sharing (caches, contexts)
- Consistent state across app

**Location Examples**:
- `PhotoManager.swift:10` - Photo management singleton
- `BackgroundBlurManager.swift:15` - Blur manager singleton
- `FilterManager.swift:12` - Filter manager singleton

---

## 📊 State Flow Patterns

### Parent → Child Data Flow

```swift
// PATTERN 1: @StateObject → @ObservedObject
// Parent owns, child observes

struct ParentView: View {
    @StateObject private var manager = Manager()
    
    var body: some View {
        ChildView(manager: manager)
    }
}

struct ChildView: View {
    @ObservedObject var manager: Manager
    
    var body: some View {
        Text(manager.value)  // Automatically updates
    }
}
```

### Child → Parent Communication

```swift
// PATTERN 2: @Binding for two-way state

struct ParentView: View {
    @State private var value = ""
    
    var body: some View {
        ChildView(value: $value)
    }
}

struct ChildView: View {
    @Binding var value: String
    
    var body: some View {
        TextField("Enter", text: $value)
        // Changes update parent immediately
    }
}
```

### Callback Pattern

```swift
// PATTERN 3: Closure callbacks for events

struct ParentView: View {
    @State private var captured = false
    
    var body: some View {
        CameraView(onPhotoSaved: {
            captured = true
            // Handle capture event
        })
    }
}

struct CameraView: UIViewRepresentable {
    var onPhotoSaved: (() -> Void)?
    
    func photoOutput(...) {
        onPhotoSaved?()  // Notify parent
    }
}
```

---

## 🎬 Real-World State Flows in Klick

### Photo Capture Flow

```
User Taps Capture Button
    ↓
ContentView: @State triggerCapture = true
    ↓
CameraView receives @Binding update
    ↓
Coordinator.capturePhoto() called
    ↓
AVFoundation captures photo
    ↓
PhotoManager.shared.savePhoto()
    ↓
PhotoManager: @Published photos.insert()
    ↓
PhotoAlbumView automatically updates (observes PhotoManager)
    ↓
ContentView: @State showGalleryGlimpse = true
    ↓
Gallery glimpse animates into view
```

### Composition Type Change Flow

```
User Selects New Composition Type
    ↓
CompositionPickerView: Button action
    ↓
CompositionManager.switchToCompositionType()
    ↓
CompositionManager: @Published currentCompositionType = .centerFraming
    ↓
Automatic UI Updates:
  ├─ ContentView: Overlay changes
  ├─ CompositionIndicatorView: Icon/text updates
  └─ CameraView: Next frame uses new service
```

### Settings Toggle Flow

```
User Toggles Facial Recognition
    ↓
FrameSettingsView: Toggle changes @Binding
    ↓
ContentView: @State isFacialRecognitionEnabled updates
    ↓
CameraView receives binding update
    ↓
Coordinator.parent.isFacialRecognitionEnabled = false
    ↓
Frame processing skips Vision framework
```

---

## ⚡ Performance Considerations

### Minimize State Updates

**Problem**: Too many state changes cause excessive re-renders

```swift
// ❌ BAD - Updates on every frame
@State private var frameCount = 0

func captureOutput(...) {
    frameCount += 1  // 30 updates/second!
}

// ✅ GOOD - Update only when needed
@State private var feedbackMessage: String?

func captureOutput(...) {
    if shouldUpdate {
        feedbackMessage = "Move left"  // Only when composition changes
    }
}
```

### Debounce Rapid Updates

```swift
// ✅ Debounce slider changes
private var blurWorkItem: DispatchWorkItem?

func updateBlur(intensity: Float) {
    blurWorkItem?.cancel()
    
    let workItem = DispatchWorkItem {
        // Apply blur
    }
    blurWorkItem = workItem
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: workItem)
}
```

**Location**: `ImagePreviewView.swift:180-210`

### Scope State Appropriately

```swift
// ❌ BAD - Too much state at root
struct ContentView: View {
    @State private var allImageEditingState = ...  // Too broad
}

// ✅ GOOD - State where it's used
struct ImagePreviewView: View {
    @State private var blurIntensity: Float = 0  // Local to editing
}
```

---

## 🧪 Testing State Management

### Test ObservableObjects

```swift
class CompositionManagerTests: XCTestCase {
    func testSwitchingCompositionType() {
        let manager = CompositionManager()
        
        // Initial state
        XCTAssertEqual(manager.currentCompositionType, .ruleOfThirds)
        
        // Change state
        manager.switchToCompositionType(.centerFraming)
        
        // Verify update
        XCTAssertEqual(manager.currentCompositionType, .centerFraming)
    }
}
```

### Test State Flow

```swift
func testPhotoSaveTriggersGalleryUpdate() {
    let manager = PhotoManager.shared
    let initialCount = manager.photos.count
    
    // Save photo
    manager.savePhoto(testImage)
    
    // Verify state update
    XCTAssertEqual(manager.photos.count, initialCount + 1)
}
```

---

## 🎯 Best Practices Summary

### ✅ DO:
- Use `@State` for simple, local view state
- Use `@StateObject` when view owns the object
- Use `@ObservedObject` when object is passed from parent
- Use `@Published` for properties that trigger UI updates
- Use `@Binding` for parent-child state sharing
- Keep state minimal and scoped appropriately
- Debounce rapid state changes
- Use singletons for app-wide managers

### ❌ DON'T:
- Don't use `@State` for complex objects
- Don't use `@ObservedObject` to create objects (use `@StateObject`)
- Don't update state too frequently (causes re-renders)
- Don't put all state at root level
- Don't use `@Published` for expensive computed properties
- Don't pass `@State` directly (use `$` binding)

---

## 📚 Related Documentation

- [ARCHITECTURE_OVERVIEW.md](./ARCHITECTURE_OVERVIEW.md) - System architecture
- [DATA_FLOW.md](./DATA_FLOW.md) - Data flow patterns
- [COMPONENT_MAP.md](./COMPONENT_MAP.md) - Component relationships
- [Application Flows](../3_Application_Flows/FLOWS_INDEX.md) - State changes in context

---

**Document Status**: ✅ Complete  
**Last Updated**: October 30, 2025  
**Maintained By**: Development Team

