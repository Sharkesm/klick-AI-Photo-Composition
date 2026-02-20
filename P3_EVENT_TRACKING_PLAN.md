# P3 Event Tracking Implementation Plan

## Overview

Implement the final 7 P3 (low-priority) events to achieve 100% event tracking coverage.

**Current Coverage**: 54/61 events (92%)  
**Target Coverage**: 61/61 events (100%)  
**Estimated Time**: 30-45 minutes

---

## Events to Implement

### Category 1: Composition Practice Mode (3 events)

**File**: `Klick/Camera/Views/CompositionStyleEdView.swift`

| Event | Parameters | Business Value |
|-------|-----------|----------------|
| `screen_practice_viewed` | `composition_type: String` | Practice engagement rate |
| `practice_dismissed` | `time_spent_seconds: Int` | Time spent learning |
| `practice_example_selected` | `composition_type: String, example_type: String` | Example interaction |

**Implementation Steps**:
1. Add `@State private var viewStartTime: Date?` for time tracking
2. Track practice viewed in `.onAppear` with composition type
3. Track practice dismissed in dismiss handler with time spent
4. Track example selection when user taps portrait examples

---

### Category 2: Camera Quality Intro (2 events)

**File**: `Klick/Camera/Components/CameraQualityIntroView.swift`

| Event | Parameters | Business Value |
|-------|-----------|----------------|
| `screen_camera_quality_intro_viewed` | - | First-time education engagement |
| `camera_quality_intro_dismissed` | `time_spent_seconds: Int` | Intro completion rate |

**Implementation Steps**:
1. Add `@State private var viewStartTime: Date?` for time tracking
2. Track intro viewed in `.onAppear`
3. Track intro dismissed in "Got it" button action with time spent

---

### Category 3: Error/Edge Cases (2 events)

**Files**: 
- `Klick/Camera/Components/StorageFullAlert.swift`
- `Klick/Camera/Screen/ContentView.swift` (permission handling)

| Event | Parameters | Business Value |
|-------|-----------|----------------|
| `storage_full_alert_shown` | `current_photo_count: Int, limit: Int` | Storage limit monitoring |
| `camera_permission_denied` | `source: String` | Permission issues tracking |

**Implementation Steps**:
1. Track storage alert when shown with photo count and limit
2. Track permission denied in camera permission check

---

## Event Definitions

### New Event Enums

**File**: `Klick/Services/PhotoEvents.swift`

Add practice and error event enums:

```swift
// MARK: - Practice Event Names

enum PracticeEvent: String {
    case viewed = "viewed"
    case dismissed = "dismissed"
    case exampleSelected = "example_selected"
    
    var eventName: String {
        return "practice_\(rawValue)"
    }
}

// MARK: - Camera Quality Intro Event Names

enum CameraQualityIntroEvent: String {
    case viewed = "viewed"
    case dismissed = "dismissed"
    
    var eventName: String {
        return "camera_quality_intro_\(rawValue)"
    }
}

// MARK: - Error/Alert Event Names

enum AlertEvent: String {
    case storageFullShown = "storage_full_alert_shown"
    case cameraPermissionDenied = "camera_permission_denied"
    
    var eventName: String {
        return rawValue
    }
}
```

---

## Extension Methods

**File**: `Klick/Services/EventTrackingExtensions.swift`

Add 7 new tracking methods:

```swift
// MARK: - Practice Events

func trackPracticeViewed(compositionType: String) async
func trackPracticeDismissed(compositionType: String, timeSpent: TimeInterval) async
func trackPracticeExampleSelected(compositionType: String, exampleType: String) async

// MARK: - Camera Quality Intro Events

func trackCameraQualityIntroViewed() async
func trackCameraQualityIntroDismissed(timeSpent: TimeInterval) async

// MARK: - Error/Alert Events

func trackStorageFullAlertShown(currentPhotoCount: Int, limit: Int) async
func trackCameraPermissionDenied(source: String) async
```

---

## Implementation Order

### Step 1: Event Infrastructure (5 minutes)
1. Add event enums to `PhotoEvents.swift`
2. Add extension methods to `EventTrackingExtensions.swift`

### Step 2: Practice Mode Tracking (10 minutes)
1. Update `CompositionStyleEdView.swift`
2. Track viewed, dismissed, and example selection

### Step 3: Camera Quality Intro Tracking (5 minutes)
1. Update `CameraQualityIntroView.swift`
2. Track viewed and dismissed

### Step 4: Error/Alert Tracking (10 minutes)
1. Update `StorageFullAlert.swift`
2. Update `ContentView.swift` for permission tracking

### Step 5: Testing (10 minutes)
1. Test practice mode events
2. Test intro events
3. Test error scenarios
4. Verify all parameters

---

## Files to Modify

### Event Infrastructure (2 files)
1. `Klick/Services/PhotoEvents.swift` - Add event enums
2. `Klick/Services/EventTrackingExtensions.swift` - Add tracking methods

### UI Files (3 files)
1. `Klick/Camera/Views/CompositionStyleEdView.swift` - Practice tracking
2. `Klick/Camera/Components/CameraQualityIntroView.swift` - Intro tracking
3. `Klick/Camera/Components/StorageFullAlert.swift` - Storage alert tracking
4. `Klick/Camera/Screen/ContentView.swift` - Permission tracking

**Total**: 5 files modified, ~100 lines of code

---

## Testing Checklist

### Practice Mode
- [ ] Open practice mode for different compositions
- [ ] Verify composition type parameter
- [ ] Dismiss practice and check time spent
- [ ] Tap portrait examples and verify tracking

### Camera Quality Intro
- [ ] Trigger intro on first interaction (reset app if needed)
- [ ] Verify intro viewed event
- [ ] Tap "Got it" and verify time spent

### Error/Alert Events
- [ ] Reach photo limit and verify storage alert
- [ ] Check photo count and limit parameters
- [ ] Deny camera permission and verify tracking

---

## Success Metrics

### Coverage Achievement
- **Before**: 54/61 events (92%)
- **After**: 61/61 events (100%)
- **Improvement**: +7 events, +8% coverage

### Complete Event Coverage
- ✅ Monetization (11 events)
- ✅ Camera (11 events)
- ✅ Gallery (6 events)
- ✅ Image Preview (13 events)
- ✅ Settings (8 events)
- ✅ Share (3 events)
- ✅ Practice (3 events)
- ✅ Intro (2 events)
- ✅ Errors (2 events)
- ✅ Onboarding (24 events)

**Total**: 61/61 events (100% coverage)

---

## Post-Implementation

### Documentation Updates
1. Update `P3_EVENT_TRACKING_IMPLEMENTATION_SUMMARY.md`
2. Mark all events complete in `MISSING_EVENT_TRACKING_ANALYSIS.md`
3. Create final comprehensive testing guide

### Analytics Setup
- Create error monitoring dashboard
- Track practice mode engagement
- Monitor intro completion rates

---

## Risk Assessment

### Very Low Risk
- All infrastructure already exists
- Simple view lifecycle tracking
- No complex business logic
- Consistent with existing patterns

### Potential Issues
1. **Practice mode navigation**: May need to find correct dismiss handler
2. **Intro timing**: First-time trigger may be tricky to test
3. **Permission state**: Need to handle different permission states

### Mitigation
- Test on fresh app install for intro
- Use simulator settings to reset permissions
- Verify all events in PostHog console

---

**Ready to implement?** This will complete 100% event tracking coverage for Klick!
