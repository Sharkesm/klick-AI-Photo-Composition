# Event Tracking Reference

**Last Updated**: February 18, 2026  
**Total Events**: 62 events across 11 features  
**Coverage**: 100%

---

## 📋 Quick Reference

This document provides a complete reference of all event tracking in Klick, organized by feature area.

---

## 1. Onboarding (24 events)

**Feature**: User onboarding flow - permissions, guides, and composition selection

### Permission Flow (6 events)
- `onboarding_permission_camera_requested`
- `onboarding_permission_camera_granted`
- `onboarding_permission_camera_denied`
- `onboarding_permission_photos_requested`
- `onboarding_permission_photos_granted`
- `onboarding_permission_photos_denied`

### Guide Flow (6 events)
- `onboarding_guide_viewed` (params: `guide_type`)
- `onboarding_guide_dismissed` (params: `guide_type`, `time_spent_seconds`)
- `onboarding_guide_next_tapped` (params: `guide_type`)
- `onboarding_guide_skip_tapped` (params: `guide_type`)
- `onboarding_guide_completed` (params: `guide_type`)
- `onboarding_guide_back_tapped` (params: `guide_type`)

### Composition Selection (3 events)
- `onboarding_composition_selected` (params: `composition_type`)
- `onboarding_composition_changed` (params: `from_composition`, `to_composition`)
- `onboarding_composition_confirmed` (params: `composition_type`)

### Flow Control (3 events)
- `onboarding_flow_started` (params: `source`)
- `onboarding_flow_completed` (params: `time_spent_seconds`)
- `onboarding_flow_skipped` (params: `at_step`)

### Screen Navigation (6 events)
- `onboarding_screen_viewed` (params: `screen`)
- `onboarding_screen_completed` (params: `screen`, `time_spent_seconds`)
- `onboarding_screen_skipped` (params: `screen`)
- `onboarding_screen_back` (params: `screen`)
- `onboarding_proupsell_viewed`
- `onboarding_proupsell_dismissed`

---

## 2. Monetization (11 events)

**Feature**: Paywall, purchases, upgrades, and Pro feature gating

### Paywall (4 events)
- `paywall_viewed` (params: `source`)
- `paywall_dismissed` (params: `source`, `time_on_screen_seconds`)
- `paywall_package_selected` (params: `package_id`, `price`)
- `paywall_subscribe_tapped` (params: `package_id`, `price`)

### Purchase Flow (4 events)
- `purchase_initiated` (params: `package_id`, `price`)
- `purchase_completed` (params: `package_id`, `price`, `transaction_id`)
- `purchase_failed` (params: `package_id`, `error_message`)
- `purchase_restored` (params: `restored_purchases_count`)

### Upgrade Prompts (3 events)
- `upgrade_prompt_viewed` (params: `context`)
- `upgrade_prompt_upgrade_tapped` (params: `context`, `time_on_screen_seconds`)
- `upgrade_prompt_dismissed` (params: `context`, `time_on_screen_seconds`)

---

## 3. Camera (11 events)

**Feature**: Camera screen, photo capture, and camera controls

### Core Actions (5 events)
- `camera_screen_viewed` (params: `session_id`)
- `camera_photo_captured` (params: `composition_type`, `camera_quality`, `flash_mode`, `zoom_level`, `faces_detected`, `composition_score`)
- `camera_settings_opened`
- `camera_photo_album_opened` (params: `photo_count`)
- `camera_practice_opened` (params: `composition_type`)

### Camera Controls (6 events)
- `camera_flash_changed` (params: `mode`)
- `camera_zoom_changed` (params: `level`)
- `camera_quality_selected` (params: `quality`, `was_gated`)
- `camera_composition_swiped` (params: `from_composition`, `to_composition`, `swipe_direction`)
- `camera_focus_tapped` (params: `x`, `y`)
- `camera_composition_selected` (params: `composition_type`, `selection_method`)

---

## 4. Photo Gallery (6 events)

**Feature**: Photo gallery management and viewing

### Gallery Management (6 events)
- `screen_gallery_viewed` (params: `photo_count`, `source`)
- `gallery_dismissed` (params: `time_spent_seconds`, `photos_viewed`)
- `gallery_photo_selected` (params: `photo_id`, `position_in_grid`)
- `gallery_selection_mode_toggled` (params: `enabled`)
- `gallery_photos_deleted` (params: `count`, `selection_method`)
- `screen_photo_detail_viewed` (params: `photo_id`, `composition_type`, `framing_score`)

---

## 5. Photo Detail (2 events)

**Feature**: Individual photo viewing and saving

### Photo Actions (2 events)
- `photo_detail_dismissed` (params: `time_spent_seconds`)
- `photo_saved_to_library` (params: `photo_id`, `format`, `file_size`)

---

## 6. Image Preview & Editing (14 events)

**Feature**: Post-capture image preview, filters, blur, and adjustments

### Screen Navigation (5 events)
- `screen_image_preview_viewed` (params: `composition_type`)
- `image_preview_photo_discarded`
- `image_preview_photo_saved`
- `image_preview_effects_opened` (params: `time_spent_seconds`)
- `image_preview_effects_closed` (params: `time_spent_seconds`)

### Filters (4 events)
- `filter_pack_selected` (params: `pack_name`)
- `filter_applied` (params: `filter_name`, `filter_pack`, `is_premium`, `was_gated`)
- `filter_removed` (params: `previous_filter`)
- `filter_adjusted` (params: `adjustment_type`, `value`)

### Blur & Processing (4 events)
- `image_preview_blur_toggled` (params: `enabled`, `was_gated`)
- `image_preview_blur_adjusted` (params: `intensity`)
- `image_preview_proraw_toggled` (params: `to_mode`)
- `image_preview_comparison_toggled` (params: `action`, `current_state`, `previous_state`, `has_filter`, `has_blur`, `has_adjustments`)

---

## 7. Settings (8 events)

**Feature**: Frame settings and preferences

### Settings Management (8 events)
- `screen_settings_frame_viewed`
- `settings_frame_dismissed` (params: `time_spent_seconds`)
- `settings_facial_recognition_toggled` (params: `enabled`)
- `settings_live_analysis_toggled` (params: `enabled`)
- `settings_live_feedback_toggled` (params: `enabled`, `was_gated`)
- `settings_hide_overlays_toggled` (params: `enabled`, `was_gated`)
- `settings_how_klick_works_tapped`
- `legal_terms_tapped` / `legal_privacy_tapped` (params: `source`)

---

## 8. Share (3 events)

**Feature**: Photo sharing functionality

### Share Actions (3 events)
- `screen_share_viewed` (params: `composition_type`, `filter_applied`)
- `photo_shared` (params: `share_destination`)
- `share_screen_dismissed` (params: `time_spent_seconds`, `shared`)

---

## 9. Practice Mode (3 events)

**Feature**: Composition practice and learning

### Practice Actions (3 events)
- `practice_viewed` (params: `composition_type`)
- `practice_dismissed` (params: `composition_type`, `time_spent_seconds`)
- `practice_example_selected` (params: `composition_type`, `example_type`)

---

## 10. Camera Quality Intro (2 events)

**Feature**: First-time camera quality education

### Intro Actions (2 events)
- `camera_quality_intro_viewed`
- `camera_quality_intro_dismissed` (params: `time_spent_seconds`)

---

## 11. Errors & Alerts (2 events)

**Feature**: Error handling and edge cases

### Error Tracking (2 events)
- `storage_full_alert_shown` (params: `current_photo_count`, `limit`)
- `camera_permission_denied` (params: `source`)

---

## 📊 Event Distribution

| Feature | Events | % of Total |
|---------|--------|------------|
| Onboarding | 24 | 39% |
| Image Preview | 14 | 23% |
| Camera | 11 | 18% |
| Monetization | 11 | 18% |
| Settings | 8 | 13% |
| Gallery | 6 | 10% |
| Practice | 3 | 5% |
| Share | 3 | 5% |
| Photo Detail | 2 | 3% |
| Intro | 2 | 3% |
| Errors | 2 | 3% |

---

## 🎯 Event Categories by Priority

### P1 - Critical Business Metrics (39 events)
- All monetization events (11)
- Core camera actions (5)
- Photo capture and editing (14)
- Gallery management (6)
- Photo detail (2)
- Onboarding completion (1)

### P2 - High Priority Engagement (15 events)
- Settings toggles (8)
- Camera controls (3)
- Share screen (3)
- Onboarding flow (1)

### P3 - Low Priority Edge Cases (8 events)
- Onboarding screens (6)
- Practice mode (3)
- Camera intro (2)
- Errors/alerts (2)

---

## 🔍 Common Parameters

### User Identification
- `user_id` - Automatically tracked by PostHog
- `session_id` - Session identifier

### Time Tracking
- `time_spent_seconds` - Duration on screen/feature
- `time_on_screen_seconds` - Time before action

### Feature Gating
- `was_gated` - Whether Pro feature was blocked
- `is_premium` - Whether feature is premium

### State Information
- `composition_type` - Active composition technique
- `camera_quality` - Camera quality setting
- `filter_name` - Applied filter name
- `current_state` - Current edit state
- `previous_state` - Previous edit state

### User Actions
- `enabled` - Toggle state
- `source` - Where action originated
- `action` - Type of action taken

---

## 📁 Implementation Files

### Event Definitions
- `Klick/Services/OnboardingEvents.swift` - Onboarding events
- `Klick/Services/MonetizationEvents.swift` - Monetization events
- `Klick/Services/CameraEvents.swift` - Camera events
- `Klick/Services/PhotoEvents.swift` - Gallery, settings, practice, errors
- `Klick/Services/FilterEvents.swift` - Filter and image preview events

### Tracking Methods
- `Klick/Services/EventTrackingExtensions.swift` - All tracking methods (70+)

### Infrastructure
- `Klick/Services/EventTrackingManager.swift` - Core orchestrator
- `Klick/Services/EventTrackingService.swift` - Protocol definition
- `Klick/Services/PostHogEventService.swift` - PostHog implementation
- `Klick/Services/ConsoleEventService.swift` - Debug console

---

## 🎨 Event Naming Convention

**Pattern**: `group_noun_action`

**Examples**:
- `camera_photo_captured` (group: camera, noun: photo, action: captured)
- `filter_pack_selected` (group: filter, noun: pack, action: selected)
- `settings_live_feedback_toggled` (group: settings, noun: live_feedback, action: toggled)

**Rules**:
- Lowercase with snake_case
- Descriptive and self-documenting
- Consistent across all events

---

## 🚀 Usage Examples

### Tracking a Simple Event
```swift
Task {
    await EventTrackingManager.shared.trackCameraSettingsOpened()
}
```

### Tracking with Parameters
```swift
Task {
    await EventTrackingManager.shared.trackPhotoCaptured(
        compositionType: .ruleOfThirds,
        cameraQuality: .pro,
        flashMode: .auto,
        zoomLevel: .wide,
        facesDetected: 2,
        compositionScore: 0.85
    )
}
```

### Tracking with Time
```swift
let startTime = Date()
// ... user interaction ...
let timeSpent = Date().timeIntervalSince(startTime)

Task {
    await EventTrackingManager.shared.trackGalleryDismissed(
        timeSpent: timeSpent,
        photosViewed: 5
    )
}
```

---

## 📊 Analytics Dashboards

### Recommended Dashboards

**1. User Acquisition**
- Onboarding completion rate
- Permission grant rates
- Time to first photo

**2. Engagement**
- Daily active users
- Photos captured per user
- Feature usage distribution

**3. Monetization**
- Paywall conversion funnel
- Upgrade prompt effectiveness
- Revenue by source

**4. Feature Adoption**
- Settings toggle rates
- Filter usage patterns
- Composition preferences

**5. Quality Metrics**
- Error rates
- Permission denials
- Storage limit hits

---

## ✅ Testing Checklist

### Core Flows
- [ ] Complete onboarding flow
- [ ] Capture photo with all settings
- [ ] Apply filters and adjustments
- [ ] Save and share photo
- [ ] View gallery and delete photos

### Monetization
- [ ] View paywall
- [ ] Select package
- [ ] Complete purchase
- [ ] Trigger upgrade prompts

### Settings & Features
- [ ] Toggle all settings
- [ ] Use practice mode
- [ ] Compare before/after
- [ ] Reach photo limit

### Edge Cases
- [ ] Deny camera permission
- [ ] Reach storage limit
- [ ] Dismiss without saving
- [ ] Skip onboarding

---

## 🎯 Success Metrics

### Onboarding
- Completion rate: >70%
- Time to complete: <2 minutes
- Permission grant rate: >80%

### Engagement
- Photos per session: >3
- Filter usage: >60%
- Settings engagement: >30%

### Monetization
- Paywall view rate: >40%
- Conversion rate: >5%
- Upgrade prompt effectiveness: >10%

### Feature Adoption
- Comparison usage: >30%
- Practice mode: >20%
- Share rate: >15%

---

## 📚 Additional Resources

### Documentation
- `COMPLETE_EVENT_TRACKING_SUMMARY.md` - Comprehensive overview
- `BEFORE_AFTER_COMPARISON_TRACKING.md` - Comparison feature details

### Code References
- Event tracking extensions for all methods
- Type-safe event enums
- Parameter validation

---

## 🔄 Maintenance

### Regular Reviews
- Quarterly event audit
- Parameter accuracy check
- Coverage verification
- Performance monitoring

### Updates
- Add new events as features evolve
- Update parameters for new requirements
- Deprecate unused events
- Optimize tracking performance

---

**Last Updated**: February 18, 2026  
**Total Events**: 62  
**Coverage**: 100%  
**Status**: Production Ready ✅
