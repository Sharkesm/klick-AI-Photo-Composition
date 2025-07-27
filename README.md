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

## 📄 License

This project is developed for educational purposes.

---

**Built with ❤️ using Swift, Vision, and SwiftUI** 