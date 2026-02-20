# Missing Event Tracking Analysis

**Date**: February 14, 2026  
**Status**: ✅ Onboarding Complete | ⏳ Other Features Pending

---

## Executive Summary

This document identifies all features and screens in Klick that are missing event tracking. The onboarding flow has been fully instrumented with 24 events. The analysis below covers the remaining areas of the app.

### Coverage Status

| Feature Area | Events Tracked | Status |
|-------------|----------------|--------|
| **Onboarding** | 24 events | ✅ Complete |
| **Camera** | 0 events | ❌ Not tracked |
| **Photo Gallery** | 0 events | ❌ Not tracked |
| **Image Preview/Editing** | 0 events | ❌ Not tracked |
| **Monetization** | 0 events | ❌ Not tracked |
| **Settings** | 0 events | ❌ Not tracked |

---

## 1. Camera Feature (HIGH PRIORITY)

### Main Camera Screen
**File**: `Klick/Camera/Screen/ContentView.swift`

#### Critical Interactions (Must Track)

| Interaction | Current Status | Recommended Event | Parameters |
|-------------|---------------|-------------------|------------|
| **Photo capture** | ❌ Not tracked | `camera_photo_captured` | `composition_type`, `camera_quality`, `flash_mode`, `zoom_level`, `faces_detected`, `composition_score` |
| **Composition selected** | ❌ Not tracked | `camera_composition_selected` | `composition_type: "rule_of_thirds"/"center"/"symmetry"`, `selection_method: "tap"/"swipe"` |
| **Camera screen viewed** | ❌ Not tracked | `screen_camera_viewed` | `session_id`, `timestamp` |

**Existing Helper (Unused)**:
- `trackPhotoCaptured(compositionType:filterApplied:)` - defined but never called
- `trackCompositionSelected(_:)` - defined but never called

---

### Camera Controls
**File**: `Klick/Camera/Views/TopControlsView.swift`, `BottomControlsView.swift`

#### High Priority

| Control | Current Status | Recommended Event | Parameters |
|---------|---------------|-------------------|------------|
| **Flash toggle** | ❌ Not tracked | `camera_flash_changed` | `mode: "off"/"auto"/"on"` |
| **Zoom changed** | ❌ Not tracked | `camera_zoom_changed` | `zoom_level: "0.5x"/"1x"/"2x"` |
| **Camera quality selected** | ❌ Not tracked | `camera_quality_selected` | `quality: "hq"/"pro"`, `was_gated: true/false` |
| **Flip camera** | ❌ Not tracked | `camera_flipped` | `to_camera: "front"/"back"` |
| **Focus tap** | ❌ Not tracked | `camera_focus_tapped` | `x`, `y` (normalized coordinates) |

#### Medium Priority

| Control | Current Status | Recommended Event | Parameters |
|---------|---------------|-------------------|------------|
| **Composition swipe** | ❌ Not tracked | `camera_composition_swiped` | `from_composition`, `to_composition`, `swipe_direction: "left"/"right"` |
| **Settings opened** | ❌ Not tracked | `camera_settings_opened` | - |
| **Photo album opened** | ❌ Not tracked | `camera_photo_album_opened` | `photo_count` |
| **Practice mode opened** | ❌ Not tracked | `camera_practice_opened` | `composition_type` |

---

### Composition & Overlays
**Display-only, no tracking needed** (overlays, face highlights, feedback text)

---

## 2. Photo Gallery & Management (HIGH PRIORITY)

### Photo Album
**File**: `Klick/PhotoAlbum/PhotoAlbumView.swift`

| Interaction | Current Status | Recommended Event | Parameters |
|-------------|---------------|-------------------|------------|
| **Gallery opened** | ❌ Not tracked | `screen_gallery_viewed` | `photo_count`, `source: "photo_strip"/"button"` |
| **Gallery closed** | ❌ Not tracked | `gallery_dismissed` | `time_spent_seconds`, `photos_viewed` |
| **Photo selected** | ❌ Not tracked | `gallery_photo_selected` | `photo_id`, `position_in_grid` |
| **Add photo tapped** | ❌ Not tracked | `gallery_add_photo_tapped` | - |
| **Selection mode toggled** | ❌ Not tracked | `gallery_selection_mode_toggled` | `enabled: true/false` |
| **Photos deleted** | ❌ Not tracked | `gallery_photos_deleted` | `count`, `selection_method: "bulk"/"single"` |

---

### Photo Detail
**File**: `Klick/PhotoAlbum/PhotoDetailView.swift`

| Interaction | Current Status | Recommended Event | Parameters |
|-------------|---------------|-------------------|------------|
| **Detail viewed** | ❌ Not tracked | `screen_photo_detail_viewed` | `photo_id`, `composition_type`, `framing_score` |
| **Save to library** | ❌ Not tracked | `photo_saved_to_library` | `photo_id`, `format`, `file_size` |
| **Detail dismissed** | ❌ Not tracked | `photo_detail_dismissed` | `time_spent_seconds` |

---

## 3. Image Preview & Editing (HIGH PRIORITY)

### Image Preview (Post-Capture)
**File**: `Klick/ImagePreview/Screen/ImagePreviewView.swift`

| Interaction | Current Status | Recommended Event | Parameters |
|-------------|---------------|-------------------|------------|
| **Preview opened** | ❌ Not tracked | `screen_image_preview_viewed` | `composition_type`, `camera_quality` |
| **Photo saved** | ❌ Not tracked | `image_preview_photo_saved` | `filter_applied`, `blur_applied`, `adjustments_made`, `time_to_save_seconds` |
| **Photo discarded** | ❌ Not tracked | `image_preview_photo_discarded` | `time_spent_seconds`, `filter_applied`, `blur_applied` |
| **Effects panel opened** | ❌ Not tracked | `image_preview_effects_opened` | - |
| **Effects panel closed** | ❌ Not tracked | `image_preview_effects_closed` | `filter_applied`, `time_spent_seconds` |

---

### Filter Application
**File**: `Klick/ImagePreview/Screen/ImagePreviewView.swift`

| Interaction | Current Status | Recommended Event | Parameters |
|-------------|---------------|-------------------|------------|
| **Filter pack selected** | ❌ Not tracked | `filter_pack_selected` | `pack_name: "glow"/"vibrant"/etc.` |
| **Filter applied** | ❌ Not tracked | `filter_applied` | `filter_name`, `filter_pack`, `is_premium: true/false`, `was_gated: true/false` |
| **Filter removed** | ❌ Not tracked | `filter_removed` | `previous_filter` |
| **Filter adjusted** | ❌ Not tracked | `filter_adjusted` | `adjustment_type`, `value` |

**Existing Helper (Unused)**:
- `trackFilterApplied(_:)` - defined but never called

---

### Background Blur
**File**: `Klick/ImagePreview/Screen/ImagePreviewView.swift`

| Interaction | Current Status | Recommended Event | Parameters |
|-------------|---------------|-------------------|------------|
| **Blur toggled** | ❌ Not tracked | `image_preview_blur_toggled` | `enabled: true/false`, `was_gated: true/false` |
| **Blur intensity adjusted** | ❌ Not tracked | `image_preview_blur_adjusted` | `intensity: 0.0-1.0` |

---

### Composition Share
**File**: `Klick/Camera/Views/CompositionShareView.swift`

| Interaction | Current Status | Recommended Event | Parameters |
|-------------|---------------|-------------------|------------|
| **Share screen viewed** | ❌ Not tracked | `screen_share_viewed` | `composition_type`, `filter_applied` |
| **Share button tapped** | ❌ Not tracked | `photo_shared` | `share_destination` (if available from UIActivityViewController) |
| **Share dismissed** | ❌ Not tracked | `share_screen_dismissed` | `time_spent_seconds`, `shared: true/false` |

---

## 4. Monetization & Purchases (CRITICAL PRIORITY)

### Sales Page (Paywall)
**File**: `Klick/SalesPage/SalesPageView.swift`

| Interaction | Current Status | Recommended Event | Parameters |
|-------------|---------------|-------------------|------------|
| **Paywall viewed** | ❌ Not tracked | `paywall_viewed` | `source`, `offerings_count` |
| **Paywall dismissed** | ❌ Not tracked | `paywall_dismissed` | `source`, `time_spent_seconds`, `package_selected: true/false` |
| **Package selected** | ❌ Not tracked | `paywall_package_selected` | `package_type: "weekly"/"monthly"/"yearly"/"lifetime"`, `price`, `currency` |
| **Subscribe tapped** | ❌ Not tracked | `paywall_subscribe_tapped` | `package_id`, `package_type`, `price` |
| **Subscribe success** | ❌ Not tracked | `purchase_completed` (use existing `trackPurchase()`) | `product_id`, `price`, `currency`, `package_type` |
| **Subscribe failed** | ❌ Not tracked | `paywall_purchase_failed` | `error_code`, `error_message` |
| **Subscribe interrupted** | ❌ Not tracked | `paywall_purchase_interrupted` | `package_id` |
| **Restore tapped** | ❌ Not tracked | `paywall_restore_tapped` | - |
| **Restore success** | ❌ Not tracked | `purchase_restored` | `entitlements_restored` |
| **Restore failed** | ❌ Not tracked | `paywall_restore_failed` | `error_message` |
| **Success screen viewed** | ❌ Not tracked | `paywall_success_viewed` | `package_type` |
| **Success continue tapped** | ❌ Not tracked | `paywall_success_continue_tapped` | - |

**Existing Helper**:
- `trackPurchase(productId:price:currency:)` - defined but never called

---

### Upgrade Prompt Alert
**File**: `Klick/Camera/Components/StorageFullAlert.swift`

| Interaction | Current Status | Recommended Event | Parameters |
|-------------|---------------|-------------------|------------|
| **Upgrade prompt viewed** | ❌ Not tracked | `upgrade_prompt_viewed` | `context: "photo_limit"/"advanced_composition"/"premium_filter"/"background_blur"/"portrait_practices"/"live_feedback"/"hide_overlays"/"pro_camera_quality"` |
| **Upgrade tapped** | ❌ Not tracked | `upgrade_prompt_upgrade_tapped` | `context` |
| **Maybe later tapped** | ❌ Not tracked | `upgrade_prompt_dismissed` | `context`, `time_on_screen_seconds` |

---

### Entry Points to Paywall (for `source` parameter)

| Entry Point | Location | Source Value |
|-------------|----------|--------------|
| Top bar upgrade button | `TopControlsView` | `"top_bar_upgrade"` |
| Photo counter badge | `PhotoCounterBadge` | `"photo_counter_badge"` |
| Frame Settings - Live Feedback | `FrameSettingsView` | `"frame_settings_live_feedback"` |
| Frame Settings - Hide Overlays | `FrameSettingsView` | `"frame_settings_hide_overlays"` |
| Composition Practice | `CompositionStyleEdView` | `"composition_practice"` |
| Pro camera quality | `CameraQualitySelectorView` | `"camera_quality_pro"` |
| Premium filter tap | `ImagePreviewView` | `"image_preview_premium_filter"` |
| Background blur tap | `ImagePreviewView` | `"image_preview_background_blur"` |
| Photo limit reached | `ContentView` | `"photo_limit"` |
| Advanced composition | `ContentView` | `"advanced_composition"` |

---

## 5. Settings & Preferences (MEDIUM PRIORITY)

### Frame Settings
**File**: `Klick/Camera/Views/FrameSettingsView.swift`

| Interaction | Current Status | Recommended Event | Parameters |
|-------------|---------------|-------------------|------------|
| **Settings opened** | ❌ Not tracked | `screen_settings_frame_viewed` | - |
| **Settings dismissed** | ❌ Not tracked | `settings_frame_dismissed` | `time_spent_seconds` |
| **Facial recognition toggled** | ❌ Not tracked | `settings_facial_recognition_toggled` | `enabled: true/false` |
| **Live analysis toggled** | ❌ Not tracked | `settings_live_analysis_toggled` | `enabled: true/false` |
| **Live feedback toggled** | ❌ Not tracked | `settings_live_feedback_toggled` | `enabled: true/false`, `was_gated: true/false` |
| **Hide overlays toggled** | ❌ Not tracked | `settings_hide_overlays_toggled` | `enabled: true/false`, `was_gated: true/false` |
| **How Klick Works tapped** | ❌ Not tracked | `settings_how_klick_works_tapped` | - |

---

### Legal & Support
**File**: `Klick/SalesPage/SalesPageView.swift`

| Interaction | Current Status | Recommended Event | Parameters |
|-------------|---------------|-------------------|------------|
| **Terms of Use tapped** | ❌ Not tracked | `legal_terms_tapped` | `source: "sales_page"` |
| **Privacy Policy tapped** | ❌ Not tracked | `legal_privacy_tapped` | `source: "sales_page"` |

---

## 6. Composition Practice (LOW PRIORITY)

### Practice Mode
**File**: `Klick/Camera/Views/CompositionStyleEdView.swift`

| Interaction | Current Status | Recommended Event | Parameters |
|-------------|---------------|-------------------|------------|
| **Practice screen opened** | ❌ Not tracked | `screen_practice_viewed` | `composition_type` |
| **Practice dismissed** | ❌ Not tracked | `practice_dismissed` | `time_spent_seconds` |
| **Practice example tapped** | ❌ Not tracked | `practice_example_selected` | `composition_type`, `example_type` |

---

## Implementation Priority Matrix

### Priority 1: Critical Business Metrics (Week 1)

**Monetization** (Revenue Impact):
1. Paywall viewed/dismissed/package selected
2. Subscribe tapped/success/failed
3. Restore purchases
4. Upgrade prompt viewed/tapped/dismissed

**Core User Journey**:
5. Photo capture (composition, quality, settings)
6. Photo saved vs discarded
7. Filter applied

### Priority 2: Product Engagement (Week 2)

**Camera Usage**:
1. Composition selection (tap/swipe)
2. Flash, zoom, camera quality changes
3. Camera screen viewed (session tracking)

**Photo Management**:
4. Gallery opened/closed
5. Photo detail viewed
6. Photos deleted

### Priority 3: Feature Discovery (Week 3)

**Settings & Preferences**:
1. Frame settings opened/dismissed
2. Setting toggles (facial recognition, live analysis, etc.)

**Advanced Features**:
3. Background blur toggled/adjusted
4. Filter pack selection
5. Composition practice

---

## Recommended Event Naming Convention

Follow the established pattern: `group_noun_action`

### New Event Groups

```swift
enum EventGroup {
    static let camera = "camera"
    static let gallery = "gallery"
    static let photo = "photo"
    static let filter = "filter"
    static let paywall = "paywall"
    static let upgrade = "upgrade"
    static let settings = "settings"
    static let practice = "practice"
    static let legal = "legal"
}
```

### Example Events

```swift
// Camera
camera_photo_captured
camera_composition_selected
camera_flash_changed
camera_zoom_changed

// Gallery
gallery_photo_selected
gallery_photos_deleted
screen_gallery_viewed

// Photo/Image Preview
photo_saved
photo_discarded
photo_shared

// Filters
filter_applied
filter_pack_selected
filter_adjusted

// Monetization
paywall_viewed
paywall_subscribe_tapped
purchase_completed
upgrade_prompt_viewed

// Settings
settings_frame_viewed
settings_facial_recognition_toggled
```

---

## Next Steps: Feature-Level Event Enums

Following the onboarding pattern, create type-safe enums for each feature:

### 1. Camera Events (`CameraEvents.swift`)
```swift
enum CameraEvent: String {
    case photoCaptured = "photo_captured"
    case compositionSelected = "composition_selected"
    case flashChanged = "flash_changed"
    case zoomChanged = "zoom_changed"
    case qualitySelected = "quality_selected"
    // ...
    
    var eventName: String {
        return "\(EventGroup.camera)_\(rawValue)"
    }
}

enum CompositionType: String {
    case ruleOfThirds = "rule_of_thirds"
    case center = "center"
    case symmetry = "symmetry"
}

enum CameraQuality: String {
    case hq = "hq"
    case pro = "pro"
}

enum FlashMode: String {
    case off = "off"
    case auto = "auto"
    case on = "on"
}
```

### 2. Monetization Events (`MonetizationEvents.swift`)
```swift
enum PaywallEvent: String {
    case viewed = "viewed"
    case dismissed = "dismissed"
    case packageSelected = "package_selected"
    case subscribeTapped = "subscribe_tapped"
    case purchaseCompleted = "purchase_completed"
    case restoreTapped = "restore_tapped"
    // ...
    
    var eventName: String {
        return "\(EventGroup.paywall)_\(rawValue)"
    }
}

enum UpgradePromptContext: String {
    case photoLimit = "photo_limit"
    case advancedComposition = "advanced_composition"
    case premiumFilter = "premium_filter"
    case backgroundBlur = "background_blur"
    case portraitPractices = "portrait_practices"
    case liveFeedback = "live_feedback"
    case hideOverlays = "hide_overlays"
    case proCameraQuality = "pro_camera_quality"
}

enum PaywallSource: String {
    case topBarUpgrade = "top_bar_upgrade"
    case photoCounterBadge = "photo_counter_badge"
    case frameSettingsLiveFeedback = "frame_settings_live_feedback"
    // ...
}
```

### 3. Photo Events (`PhotoEvents.swift`)
```swift
enum PhotoEvent: String {
    case saved = "saved"
    case discarded = "discarded"
    case shared = "shared"
    case deleted = "deleted"
    case savedToLibrary = "saved_to_library"
    // ...
    
    var eventName: String {
        return "\(EventGroup.photo)_\(rawValue)"
    }
}
```

### 4. Filter Events (`FilterEvents.swift`)
```swift
enum FilterEvent: String {
    case applied = "applied"
    case removed = "removed"
    case packSelected = "pack_selected"
    case adjusted = "adjusted"
    // ...
    
    var eventName: String {
        return "\(EventGroup.filter)_\(rawValue)"
    }
}
```

---

## Estimated Implementation Effort

| Feature Area | Events Count | Effort (Days) | Priority |
|-------------|--------------|---------------|----------|
| Camera | ~15 events | 2-3 days | P1 |
| Monetization | ~15 events | 2-3 days | P1 (Critical) |
| Photo Gallery | ~8 events | 1-2 days | P1 |
| Image Preview/Editing | ~12 events | 2 days | P1 |
| Settings | ~8 events | 1 day | P2 |
| Composition Practice | ~3 events | 0.5 days | P3 |
| **Total** | **~61 events** | **8-11 days** | - |

---

## Key Insights

1. **Monetization is completely untracked** - This is the highest priority as it directly impacts revenue understanding
2. **Core camera functionality has no tracking** - Photo capture, composition selection, and camera controls are fundamental user actions
3. **Photo management lifecycle is invisible** - Can't measure save vs discard rates, filter usage, or sharing behavior
4. **Feature gating effectiveness unknown** - No data on which upgrade prompts convert best
5. **Settings usage is a black box** - Don't know which features users enable/disable

---

## Questions for Product/Analytics Team

1. **Monetization**: Do we want to track individual package prices and currencies, or just package types?
2. **Camera**: Should we track every photo capture or sample (e.g., every 10th)?
3. **Filters**: Track every filter change or only final applied filter?
4. **User Properties**: Should we set properties like `is_pro`, `photos_captured_count`, `favorite_composition`?
5. **Session Tracking**: Do we need session IDs to group related events?
6. **A/B Testing**: Should we add variant parameters for future experiments?

---

**Last Updated**: February 14, 2026  
**Status**: Analysis Complete - Ready for Implementation Planning
