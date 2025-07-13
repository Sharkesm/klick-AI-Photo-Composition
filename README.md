# Klick - Smart Photo Composition App (MVP)

A real-time camera assistant that teaches beginner and intermediate photographers how to frame better photos using the Rule of Thirds composition technique.

## 🎯 App Objective

Klick provides live camera composition guides with real-time subject detection and Rule of Thirds recommendations using overlays and educational prompts.

## ✨ MVP Features

### Phase 1: Live Camera Feed ✅
- Real-time camera preview with minimal latency
- Uses AVCaptureSession for rear camera access
- SwiftUI integration with UIViewRepresentable
- Proper aspect ratio handling (.resizeAspectFill)

### Phase 2: Rule of Thirds Grid ✅
- 3x3 grid overlay (2 vertical + 2 horizontal lines)
- Semi-transparent white lines (alpha 0.6, 1pt width)
- Smooth animation on show/hide
- Scales with different screen sizes

### Phase 3: Subject Detection ✅
- Face detection using VNDetectFaceRectanglesRequest
- Object detection using VNRecognizeObjectsRequest
- Real-time frame analysis with throttling (every 3rd frame)
- Background queue processing for performance

### Phase 4: Rule of Thirds Evaluation ✅
- Calculates four key intersection points
- Compares subject center to nearest intersection
- 10% tolerance threshold for alignment
- Live feedback messages:
  - ✅ "Nice framing!" when aligned
  - ⚠️ "Try placing your subject on a third" when not aligned

### Phase 5: Educational Content ✅
- Tappable ℹ️ info icon
- Educational popup explaining Rule of Thirds
- Dismissible sheet with smooth animations
- Clear, simple explanations for beginners

### Phase 6: Minimal UI ✅
- Clean, intuitive interface
- Bottom control bar with large hit areas (60x60pt)
- Three main buttons:
  - 📷 Capture Button (placeholder)
  - 👁️ Grid Toggle
  - ℹ️ Info/Educational Content

## 🛠 Technical Stack

- **SwiftUI** - Modern UI framework
- **AVFoundation** - Camera capture and video processing
- **Vision** - Face and object detection
- **Core ML** - Machine learning integration
- **iOS 16+** - Target platform

## 📱 Requirements

- iPhone 12 and newer
- iOS 16.0+
- Camera permission required

## 🚀 Getting Started

1. Open `Klick.xcodeproj` in Xcode
2. Select your target device (iPhone 12+ recommended)
3. Build and run the project
4. Grant camera permissions when prompted
5. Start framing photos with Rule of Thirds guidance!

## 🎨 UI/UX Design

- **Clean Interface**: Minimal distractions during photography
- **Large Touch Targets**: All buttons meet 44x44pt minimum
- **Smooth Animations**: 0.3s easeInOut transitions
- **Clear Feedback**: Immediate visual and textual guidance
- **Educational Focus**: Learning through interaction

## 🔧 Performance Optimizations

- Frame throttling (process every 3rd frame)
- Background queue processing
- Efficient Vision framework usage
- Memory-conscious image handling

## 📋 MVP Completion Criteria

✅ Live camera preview with minimal delay  
✅ Rule of Thirds grid overlay  
✅ Face/object detection and highlighting  
✅ Real-time Rule of Thirds evaluation  
✅ Live feedback on framing accuracy  
✅ Educational popup explaining the technique  
✅ Smooth performance on iPhone 12+  
✅ Touch-friendly, clean UI  

## 🚫 Not Implemented (Future Versions)

- Golden Ratio detection
- Leading Lines analysis
- Multi-rule recommendations
- Symmetry analysis
- Capture history/gallery
- User accounts
- External model integration

## 📄 License

This project is developed as an MVP for educational purposes.

---

**Built with ❤️ using Swift, Vision, and SwiftUI** 