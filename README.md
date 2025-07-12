# Klick - Photography Composition Analysis App

Klick is an iOS application designed to help beginners learn photography composition through real-time analysis and educational content. The app uses Apple's Vision framework to analyze photos and provide feedback on composition rules like the rule of thirds, leading lines, and symmetry.

## Features

- **Camera Integration**: Take photos directly within the app or select from your photo library
- **Composition Analysis**: Uses Vision framework to detect:
  - Rule of thirds alignment
  - Leading lines
  - Symmetry and balance
  - Faces and their positioning
  - Geometric shapes and patterns
- **Visual Overlays**: Animated overlays show composition grids and detected elements
- **Black & White Mode**: Toggle between color and black & white views for better composition visualization
- **Educational Content**: Comprehensive lessons on 8 different composition rules
- **Beginner-Friendly**: Clear explanations and practical tips for each composition technique

## Requirements

- iOS 15.0 or later
- iPhone or iPad with camera (for photo capture)
- Xcode 14.0 or later for development

## Setup Instructions

1. Open the project in Xcode
2. Configure signing with your Apple Developer account
3. Update the Info.plist permissions (already included):
   - Camera Usage Description
   - Photo Library Usage Description
4. Build and run on a physical device (camera features won't work in simulator)

## App Structure

```
Klick/
├── Models/
│   └── CompositionModels.swift    # Data models for composition rules and analysis
├── Services/
│   └── CompositionAnalyzer.swift  # Vision framework analysis logic
├── Views/
│   ├── PhotoCaptureView.swift     # Camera and photo library interface
│   ├── CompositionOverlayView.swift # Animated overlay visualization
│   ├── AnalysisResultView.swift   # Analysis results display
│   └── EducationalContentView.swift # Learning materials
└── ContentView.swift              # Main app interface
```

## How to Use

1. **Taking a Photo**:
   - Tap "Get Started" on the home screen
   - Choose "Take Photo" for camera or "Choose from Library" for existing photos

2. **Analyzing Composition**:
   - After selecting a photo, tap "Analyze Composition"
   - The app will detect faces, lines, and shapes in your photo

3. **Viewing Results**:
   - Animated overlays will appear showing detected composition elements
   - Tap "View Results" to see detailed analysis and suggestions
   - Use the black & white toggle for alternative visualization

4. **Learning**:
   - Tap the book icon or "Learn Composition" to access educational content
   - Browse through 8 different composition rules with examples and exercises

## Composition Rules Covered

1. **Rule of Thirds**: Dividing the frame into nine sections
2. **Leading Lines**: Using lines to guide the viewer's eye
3. **Symmetry**: Creating balance in your photos
4. **Framing**: Using foreground elements to frame subjects
5. **Golden Ratio**: Nature's perfect proportion
6. **Diagonals**: Adding dynamic energy
7. **Patterns**: Creating visual rhythm
8. **Fill the Frame**: Getting close for impact

## Technical Details

- Built with SwiftUI for modern iOS interface
- Uses Vision framework for image analysis
- Core Image for black & white conversion
- Implements animated overlays with SwiftUI animations
- Supports both portrait and landscape orientations

## Future Enhancements

- Save analyzed photos with composition overlays
- Share functionality for social media
- Advanced composition rules (negative space, color theory)
- Practice challenges and progress tracking
- Community gallery for inspiration

## Privacy

Klick processes all images locally on your device. No photos or analysis data are sent to external servers, ensuring your privacy is protected.

## License

This project is created for educational purposes and demonstration of iOS development capabilities. 