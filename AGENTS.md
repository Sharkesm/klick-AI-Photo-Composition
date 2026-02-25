# AGENTS.md

## Cursor Cloud specific instructions

### Project Overview

Klick is a **native iOS app** (Swift 5.9, SwiftUI + UIKit) that teaches photography composition through real-time camera feedback. It targets iOS 16.0+ / iPhone 12+.

### Platform Constraint

This is an Xcode-only iOS project. **Building and running the app requires macOS with Xcode 15+**. On Linux VMs, you can:

- **Lint**: `swiftlint lint Klick/` (SwiftLint is installed at `/usr/local/bin/swiftlint`)
- **Syntax-check**: `swift -frontend -parse <file.swift>` (Swift 6.0.3 is installed at `/opt/swift-6.0.3-RELEASE-ubuntu24.04/usr/bin/swift`)
- Edit code, review documentation, and manage git operations

You **cannot** compile the full project, resolve SPM dependencies, or run the app on a Linux VM.

### Key Paths

- **Entry point**: `Klick/KlickApp.swift`
- **Main UI**: `Klick/Camera/Screen/ContentView.swift`
- **Camera**: `Klick/Camera/Views/CameraView.swift`
- **Composition logic**: `Klick/CompositionService.swift`, `Klick/CompositionManager.swift`
- **SPM lockfile**: `Klick.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`
- **Documentation index**: `Documentation/0_INDEX.md`

### Linting

No `.swiftlint.yml` config file exists in the repo. SwiftLint runs with default rules. Run:
```
swiftlint lint Klick/
```
Current baseline: 2558 warnings, 40 serious violations across 86 files (all pre-existing).

### Testing

No automated test targets exist in this project. Camera features require a physical iPhone 12+ device. There are no unit tests, UI tests, or CI pipelines configured.

### Dependencies

All 4 SPM packages (RevenueCat, Firebase, PostHog, DotLottie) plus transitive dependencies are pinned in `Package.resolved`. Dependencies are resolved by Xcode, not by a standalone `Package.swift`.

### Known Gotchas

- `ContentView.swift` uses a trailing comma syntax that parses fine in Xcode's Swift compiler but fails `swift -frontend -parse` on Linux. This is not a real syntax error.
- The project has no setup scripts, no CI/CD, no Makefile, no Podfile, no Fastfile.
- All cursor rules in `.cursor/rules/` must be followed — especially `feature-governance.mdc` (mandatory feature evaluation) and `oIndex.mdc` (documentation-first workflow).
