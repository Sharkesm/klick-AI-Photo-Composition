# Klick - Smart Photo Composition App

A real-time camera assistant that teaches photographers composition techniques through live feedback and intelligent subject detection.

## 🎯 What It Does

Klick provides instant composition guidance while you frame photos, helping you learn photography techniques through practice rather than theory.

## ✨ Core Features

### 📹 **Camera System**
- **Live Camera Feed**: Real-time preview with minimal latency
- **Tap-to-Focus**: Touch anywhere to focus and adjust exposure
- **Flash Control**: Auto, on, or off flash modes
- **Background Processing**: Smooth performance without UI lag

### 📸 **Photo Management**
- **Photo Capture**: High-quality JPEG/HEVC photo capture
- **Local Storage**: Photos saved to app's document directory
- **Photo Library Integration**: Automatic saving to device photo library
- **Gallery View**: Grid-based photo browser with smooth animations
- **Photo Viewing**: Full-screen photo display with capture details
- **Delete Options**: Individual or batch photo deletion

### 🧠 **Smart Detection**
- **Face Detection**: Prioritizes human faces for composition analysis
- **Human Detection**: Falls back to full-body detection when no faces found
- **Real-Time Processing**: Analyzes every 3rd frame for optimal performance

### 🎨 **Composition Analysis**
- **Rule of Thirds**: 3×3 grid with intersection point guidance
- **Center Framing**: Crosshair overlay with symmetry analysis
- **Symmetry Detection**: Pixel-level vertical symmetry evaluation
- **Live Feedback**: Instant directional guidance ("Move left", "Perfect!")

### 🎓 **Learning Features**
- **Educational Content**: Built-in explanations of composition techniques
- **Interactive Learning**: Learn by doing with real-time feedback
- **Progressive Guidance**: Adaptive tolerance for easier learning

### ⚙️ **Customization**
- **Composition Types**: Switch between Rule of Thirds, Center Framing, and Symmetry
- **Toggle Controls**: Enable/disable face detection, overlays, and analysis
- **Visual Settings**: Customize overlay visibility and analysis behavior

## 🛠 Technical Stack

- **SwiftUI + UIKit**: Modern UI with reliable camera integration
- **AVFoundation**: Camera capture and video processing
- **Vision Framework**: Face and human detection
- **Core Image**: Image processing and analysis
- **iOS 16.0+**: Modern iOS features and APIs

## 📱 Requirements

- **Device**: iPhone 12 or newer
- **iOS**: 16.0 or later
- **Permissions**: Camera and Photo Library access

## 🚀 Quick Start

1. Open `Klick.xcodeproj` in Xcode
2. Select your target device (iPhone 12+ recommended)
3. Build and run (`⌘+R`)
4. Grant camera and photo library permissions
5. Start taking better photos with real-time guidance!

## 🎨 Design Philosophy

- **Minimal Interface**: Clean design that doesn't distract from photography
- **Instant Feedback**: Real-time guidance without delays
- **Learning-Focused**: Educational approach to skill building
- **Accessible**: Large touch targets and high-contrast overlays

## 🔧 Performance Features

- **Frame Throttling**: Processes every 3rd frame for smooth performance
- **Background Processing**: Computer vision runs on background queues
- **Memory Optimization**: Efficient image handling and caching
- **Battery Conscious**: Minimal impact on device battery life

## 📋 Current Status

✅ **Completed Features**
- Live camera preview with tap-to-focus
- Real-time face and human detection
- Three composition analysis modes
- Photo capture with quality settings
- Local photo storage and gallery
- Individual and batch photo deletion
- Educational content system
- Comprehensive settings panel

⏳ **Future Enhancements**
- Golden Ratio composition analysis
- Leading Lines detection
- Advanced symmetry techniques
- Cloud storage integration
- Photo sharing capabilities

## 📚 Documentation

Klick features comprehensive, well-organized documentation to support development and scaling:

### 🎯 Quick Links
- **[Documentation Index](./Documentation/0_INDEX.md)** - Master navigation hub
- **[Tech Stack](./Documentation/TECH_STACK.md)** - Complete technology reference
- **[Developer Guide](./Documentation/4_Development/DEVELOPER_GUIDE.md)** - Development workflow
- **[Architecture Overview](./Documentation/2_Architecture/ARCHITECTURE_OVERVIEW.md)** - System design

### 📖 Documentation Structure

```
Documentation/
├── 0_INDEX.md                     # Master navigation and quick find guide
├── TECH_STACK.md                  # Complete technology reference
│
├── 1_Product/                     # Product documentation
│   ├── PRODUCT_OVERVIEW.md        # Vision and mission
│   └── FEATURE_CATALOG.md         # Complete feature inventory
│
├── 2_Architecture/                # Architecture & design
│   ├── ARCHITECTURE_OVERVIEW.md   # System architecture
│   ├── COMPONENT_MAP.md           # Component relationships
│   ├── STATE_MANAGEMENT.md        # State patterns
│   └── DATA_FLOW.md               # Data flow diagrams
│
├── 3_Application_Flows/           # End-to-end user flows
│   ├── FLOWS_INDEX.md             # Flow navigation hub
│   ├── FLOW_PHOTO_CAPTURE.md      # Photo capture flow
│   ├── FLOW_COMPOSITION.md        # Composition analysis
│   └── [More flows...]
│
├── 4_Development/                 # Development guides
│   ├── DEVELOPER_GUIDE.md         # Complete dev guide
│   ├── CODE_STANDARDS.md          # Coding conventions
│   ├── TESTING_GUIDE.md           # Testing strategy
│   └── API_REFERENCE.md           # Public APIs
│
├── 5_Features/                    # Feature-specific docs
│   ├── CAMERA_SYSTEM.md           # Camera implementation
│   ├── COMPOSITION_ANALYSIS.md    # Composition services
│   ├── PHOTO_MANAGEMENT.md        # Photo storage
│   ├── FILTER_SYSTEM.md           # LUT filters
│   └── BLUR_EFFECTS.md            # Background blur
│
├── 6_Performance/                 # Performance documentation
│   ├── PERFORMANCE_OVERVIEW.md    # Performance summary
│   ├── MEMORY_OPTIMIZATION.md     # Memory strategies
│   ├── BLUR_OPTIMIZATION.md       # Blur performance
│   └── IMAGE_PROCESSING.md        # Concurrent processing
│
├── 7_Troubleshooting/            # Debug & troubleshooting
│   ├── COMMON_ISSUES.md           # FAQ and solutions
│   ├── DEBUGGING_GUIDE.md         # Debug workflows
│   └── PERFORMANCE_PROFILING.md   # Profiling techniques
│
└── 8_Reference/                   # Reference materials
    ├── GLOSSARY.md                # Technical terms
    ├── RESOURCES.md               # External resources
    └── DECISION_RECORDS.md        # Architecture decisions
```

### 🚀 Getting Started

**For New Developers**:
1. Start with [Documentation Index](./Documentation/0_INDEX.md)
2. Review [Tech Stack](./Documentation/TECH_STACK.md)
3. Follow [Developer Guide](./Documentation/4_Development/DEVELOPER_GUIDE.md)

**For Feature Development**:
1. Read [Architecture Overview](./Documentation/2_Architecture/ARCHITECTURE_OVERVIEW.md)
2. Check [Application Flows](./Documentation/3_Application_Flows/FLOWS_INDEX.md)
3. Review relevant feature docs in [5_Features/](./Documentation/5_Features/)

**For Cursor AI Context**:
The documentation is optimized for AI-assisted development with:
- Semantic search-friendly structure
- Complete code references with line numbers
- Component relationship maps
- End-to-end flow documentation

---

## 📄 License

This project is developed for educational purposes.

---

**Built with ❤️ using Swift, Vision, and SwiftUI** 