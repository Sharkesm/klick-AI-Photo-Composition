# Lottie Animations

This directory contains Lottie animation files used in the Klick app.

## Files

- **confetti.json** - Confetti animation used in the success sales page after subscription purchase

## Setup Instructions

To use these animations in Xcode:

1. Open your Xcode project
2. Right-click on the "Animations" folder in the Project Navigator
3. Select "Add Files to Klick..."
4. Select the `confetti.json` file
5. Make sure "Copy items if needed" is checked
6. Make sure "Add to targets: Klick" is checked
7. Click "Add"

The animation will then be available in your app bundle and can be referenced by its filename (without extension).

## Usage

```swift
import DotLottie

DotLottieAnimation(fileName: "confetti", config: AnimationConfig(autoplay: true, loop: false))
    .view()
```

