# Monetization Event Tracking - Testing Guide

**Created**: February 14, 2026  
**Status**: Implementation Complete - Ready for Testing  
**Priority**: P1 - Critical (Revenue Impact)

---

## Overview

This guide provides comprehensive test scenarios for validating the monetization event tracking implementation. All events should be visible in the Console app during testing and will flow to PostHog in production.

---

## Prerequisites

### 1. Development Environment Setup

- **Device**: Physical iPhone (iOS 16.0+) with sandbox Apple ID configured
- **Build Configuration**: Debug build with event tracking enabled
- **Console App**: Open on Mac to monitor events in real-time

### 2. Sandbox Account Setup

- Create/use Apple Sandbox test account
- Sign out of production App Store
- Sign in with sandbox account in Settings > App Store

### 3. Event Monitoring

**Console App Filter**:
```
process:Klick AND (subsystem:com.klick.events OR category:EventTracking)
```

**Expected Event Format**:
```
📊 Event Tracked: paywall_viewed
Parameters: {
  "source": "top_bar_upgrade",
  "offerings_count": 4,
  "default_package": "annual"
}
```

---

## Test Scenarios

### Test 1: Complete Purchase Flow (Top Bar Entry)

**Objective**: Validate full purchase funnel from top bar upgrade button

**Steps**:
1. Launch app and navigate to camera
2. Tap "Upgrade" button in top bar
3. Wait for paywall to load
4. Select "Monthly" package
5. Tap "Continue" button
6. Complete sandbox purchase
7. Wait for success screen
8. Tap "Continue" on success screen

**Expected Events** (in order):
```
1. paywall_viewed
   - source: "top_bar_upgrade"
   - offerings_count: 4
   - default_package: "annual"

2. paywall_package_selected
   - package_id: "$rc_monthly"
   - package_type: "monthly"
   - price: 9.99
   - currency: "USD"

3. paywall_subscribe_tapped
   - package_id: "$rc_monthly"
   - package_type: "monthly"
   - price: 9.99
   - currency: "USD"

4. paywall_purchase_completed
   - product_id: "com.klick.monthly"
   - package_type: "monthly"
   - price: 9.99
   - currency: "USD"
   - time_to_purchase_seconds: ~5-15

5. paywall_success_viewed
   - package_type: "monthly"
   - source: "top_bar_upgrade"

6. paywall_success_continue_tapped
   - package_type: "monthly"
```

**User Properties Set**:
- `is_pro`: true
- `subscription_type`: "monthly"
- `last_purchase_source`: "top_bar_upgrade"

**Validation**:
- ✅ All 6 events fired in correct order
- ✅ User properties updated
- ✅ Time to purchase is reasonable (5-15 seconds)
- ✅ Source attribution is correct

---

### Test 2: Abandoned Purchase (Package Selected)

**Objective**: Track when user selects package but dismisses without purchasing

**Steps**:
1. Open paywall from photo counter badge
2. Select "Annual" package
3. Tap X button to dismiss

**Expected Events**:
```
1. paywall_viewed
   - source: "photo_counter_badge"

2. paywall_package_selected
   - package_type: "annual"

3. paywall_dismissed
   - source: "photo_counter_badge"
   - time_spent_seconds: ~10-20
   - package_selected: true
```

**Validation**:
- ✅ Dismissed event shows `package_selected: true`
- ✅ Time spent is accurate

---

### Test 3: Abandoned Purchase (No Package Selected)

**Objective**: Track when user dismisses without selecting any package

**Steps**:
1. Open paywall from frame settings (Live Feedback)
2. Wait 5 seconds
3. Tap X button to dismiss

**Expected Events**:
```
1. paywall_viewed
   - source: "frame_settings_live_feedback"

2. paywall_dismissed
   - source: "frame_settings_live_feedback"
   - time_spent_seconds: ~5
   - package_selected: false
```

**Validation**:
- ✅ Dismissed event shows `package_selected: false`

---

### Test 4: Purchase Interrupted (User Cancels)

**Objective**: Track when user cancels during Apple payment flow

**Steps**:
1. Open paywall
2. Select package
3. Tap Continue
4. Cancel in Apple payment dialog

**Expected Events**:
```
1. paywall_viewed
2. paywall_package_selected
3. paywall_subscribe_tapped
4. paywall_purchase_interrupted
   - package_id: "$rc_monthly"
   - package_type: "monthly"
```

**Validation**:
- ✅ Interrupted event fires (not completed)
- ✅ User stays on paywall

---

### Test 5: Restore Purchases (Success)

**Objective**: Validate restore flow for users with existing subscription

**Prerequisites**: Must have active sandbox subscription

**Steps**:
1. Open paywall
2. Tap "Restore" link at bottom
3. Wait for restore to complete

**Expected Events**:
```
1. paywall_viewed
2. paywall_restore_tapped
3. paywall_restore_completed
   - entitlements_restored: "Klick Premium"
4. paywall_success_viewed
5. paywall_success_continue_tapped
```

**User Properties Set**:
- `is_pro`: true

**Validation**:
- ✅ Restore completed event fires
- ✅ Success screen shows
- ✅ User properties updated

---

### Test 6: Restore Purchases (Failed - No Subscription)

**Objective**: Track failed restore when no subscription exists

**Prerequisites**: Sandbox account with NO active subscription

**Steps**:
1. Open paywall
2. Tap "Restore" link
3. Wait for error

**Expected Events**:
```
1. paywall_viewed
2. paywall_restore_tapped
3. paywall_restore_failed
   - error_message: "No active subscriptions found"
```

**Validation**:
- ✅ Failed event fires with error message
- ✅ User stays on paywall

---

### Test 7: Upgrade Prompt Flow (Photo Limit)

**Objective**: Track upgrade prompt → paywall flow

**Steps**:
1. Capture 5 photos (free tier limit)
2. Attempt to capture 6th photo
3. Upgrade prompt appears
4. Tap "Upgrade to Pro"
5. Paywall opens

**Expected Events**:
```
1. upgrade_prompt_viewed
   - context: "photo_limit"

2. upgrade_prompt_upgrade_tapped
   - context: "photo_limit"
   - time_on_screen_seconds: ~3-5

3. paywall_viewed
   - source: "photo_limit"
```

**Validation**:
- ✅ Prompt viewed event fires
- ✅ Upgrade tapped tracks time on screen
- ✅ Paywall source is correct

---

### Test 8: Upgrade Prompt Dismissed

**Objective**: Track when user dismisses upgrade prompt

**Steps**:
1. Trigger upgrade prompt (e.g., try to use premium filter)
2. Wait 3 seconds
3. Tap "Maybe Later"

**Expected Events**:
```
1. upgrade_prompt_viewed
   - context: "premium_filter"

2. upgrade_prompt_dismissed
   - context: "premium_filter"
   - time_on_screen_seconds: ~3
```

**Validation**:
- ✅ Dismissed event fires
- ✅ Time on screen is accurate

---

### Test 9: All Entry Point Sources

**Objective**: Verify correct source attribution for all entry points

**Test Matrix**:

| Entry Point | Action | Expected Source |
|-------------|--------|-----------------|
| Top bar upgrade button | Tap upgrade | `top_bar_upgrade` |
| Photo counter badge | Tap badge | `photo_counter_badge` |
| Frame Settings - Live Feedback | Toggle when locked | `frame_settings_live_feedback` |
| Frame Settings - Hide Overlays | Toggle when locked | `frame_settings_hide_overlays` |
| Composition Practice | Tap locked practice | `composition_practice` |
| Camera Quality Pro | Select Pro quality | `camera_quality_pro` |
| Image Preview - Premium Filter | Tap locked filter | `image_preview_premium_filter` |
| Image Preview - Background Blur | Tap blur when locked | `image_preview_background_blur` |
| Photo Limit | Capture beyond limit | `photo_limit` |
| Advanced Composition | Use locked composition | `advanced_composition` |

**For Each Entry Point**:
1. Trigger the entry point
2. Verify `paywall_viewed` has correct `source`
3. Complete or dismiss paywall
4. Verify `source` is consistent throughout flow

**Validation**:
- ✅ All 10+ sources tracked correctly
- ✅ Source persists through entire funnel

---

### Test 10: Package Switching

**Objective**: Track when user switches between packages before purchasing

**Steps**:
1. Open paywall
2. Select "Monthly" package
3. Select "Annual" package
4. Select "Lifetime" package
5. Tap Continue and complete purchase

**Expected Events**:
```
1. paywall_viewed
2. paywall_package_selected (package_type: "monthly")
3. paywall_package_selected (package_type: "annual")
4. paywall_package_selected (package_type: "lifetime")
5. paywall_subscribe_tapped (package_type: "lifetime")
6. paywall_purchase_completed (package_type: "lifetime")
```

**Validation**:
- ✅ Each package selection tracked
- ✅ Final purchase uses last selected package

---

### Test 11: Multiple Paywall Visits (Same Session)

**Objective**: Verify events track correctly across multiple paywall views

**Steps**:
1. Open paywall from top bar → Dismiss
2. Open paywall from photo counter → Dismiss
3. Open paywall from frame settings → Complete purchase

**Expected Events**:
```
Session 1:
- paywall_viewed (source: "top_bar_upgrade")
- paywall_dismissed (source: "top_bar_upgrade")

Session 2:
- paywall_viewed (source: "photo_counter_badge")
- paywall_dismissed (source: "photo_counter_badge")

Session 3:
- paywall_viewed (source: "frame_settings_live_feedback")
- paywall_subscribe_tapped
- paywall_purchase_completed
```

**User Properties**:
- `last_purchase_source`: "frame_settings_live_feedback"

**Validation**:
- ✅ Each session tracked independently
- ✅ Last purchase source is correct

---

## Event Validation Checklist

### Paywall Events (12 events)

- [ ] `paywall_viewed` - Fires when paywall appears
- [ ] `paywall_dismissed` - Fires when X button tapped
- [ ] `paywall_package_selected` - Fires for each package tap
- [ ] `paywall_subscribe_tapped` - Fires when Continue tapped
- [ ] `paywall_purchase_completed` - Fires on successful purchase
- [ ] `paywall_purchase_failed` - Fires on purchase error
- [ ] `paywall_purchase_interrupted` - Fires when user cancels
- [ ] `paywall_restore_tapped` - Fires when Restore tapped
- [ ] `paywall_restore_completed` - Fires on successful restore
- [ ] `paywall_restore_failed` - Fires on restore error
- [ ] `paywall_success_viewed` - Fires when success screen shows
- [ ] `paywall_success_continue_tapped` - Fires when Continue tapped on success

### Upgrade Prompt Events (3 events)

- [ ] `upgrade_prompt_viewed` - Fires when prompt appears
- [ ] `upgrade_prompt_upgrade_tapped` - Fires when Upgrade tapped
- [ ] `upgrade_prompt_dismissed` - Fires when Maybe Later tapped

### User Properties (4 properties)

- [ ] `is_pro` - Set to true after purchase/restore
- [ ] `subscription_type` - Set to package type after purchase
- [ ] `last_purchase_source` - Set to source after purchase
- [ ] All properties persist across app restarts

---

## Common Issues & Troubleshooting

### Issue 1: Events Not Appearing in Console

**Symptoms**: No events showing in Console app

**Solutions**:
1. Check Console filter is correct
2. Verify device is connected and selected in Console
3. Check `EventTrackingManager` is initialized
4. Verify PostHog/Console services are registered

**Debug**:
```swift
// Add breakpoint in EventTrackingManager.track()
print("🔍 Tracking event: \(eventName)")
```

---

### Issue 2: Wrong Source Attribution

**Symptoms**: `source` parameter is incorrect

**Solutions**:
1. Check `paywallSource` is set before `showSalesPage = true`
2. Verify `mapUpgradeContextToPaywallSource()` mapping is correct
3. Check callback signatures match (PaywallSource parameter)

**Debug**:
```swift
// Add print before showing paywall
print("🎯 Setting paywall source: \(paywallSource)")
```

---

### Issue 3: User Properties Not Persisting

**Symptoms**: Properties reset after app restart

**Solutions**:
1. Check PostHog identify is called
2. Verify properties are set with correct keys
3. Check PostHog SDK is initialized

**Debug**:
```swift
// Check PostHog user properties
PostHogSDK.shared.getDistinctId()
```

---

### Issue 4: Time Tracking Inaccurate

**Symptoms**: `time_spent_seconds` or `time_to_purchase_seconds` is 0 or very large

**Solutions**:
1. Check `viewStartTime` is set in `.onAppear`
2. Verify `selectedPackageTime` is set when package selected
3. Check `Date()` calculations are correct

**Debug**:
```swift
// Add print in tracking calls
let timeSpent = Date().timeIntervalSince(viewStartTime)
print("⏱️ Time spent: \(timeSpent) seconds")
```

---

## Success Criteria

### Minimum Requirements (Must Pass)

✅ **All 15 events fire correctly** (12 paywall + 3 upgrade prompt)  
✅ **All 10+ entry points have correct source attribution**  
✅ **User properties set after purchase/restore**  
✅ **Time tracking is accurate (within 1-2 seconds)**  
✅ **Events appear in Console during testing**

### Ideal State (Should Pass)

✅ **No duplicate events** (each action fires once)  
✅ **Events fire in correct order**  
✅ **Parameters are accurate and complete**  
✅ **No crashes or errors during event tracking**  
✅ **Events work across multiple sessions**

---

## Post-Testing Actions

### 1. Production Verification

After testing in sandbox:
1. Build production release
2. Submit to TestFlight
3. Verify events in PostHog dashboard
4. Check event volume and data quality

### 2. Analytics Setup

In PostHog:
1. Create conversion funnel: `paywall_viewed` → `paywall_subscribe_tapped` → `paywall_purchase_completed`
2. Create source attribution report
3. Set up alerts for failed purchases
4. Create dashboard for monetization metrics

### 3. Documentation

- [ ] Update `MISSING_EVENT_TRACKING_ANALYSIS.md` to mark monetization as complete
- [ ] Document any edge cases discovered
- [ ] Create runbook for monitoring monetization events
- [ ] Share test results with product team

---

## Quick Test Commands

### Reset Sandbox Subscription (for testing restore)
```
Settings > App Store > Sandbox Account > Manage > Cancel Subscription
```

### Clear App Data (for fresh state)
```
Delete app → Reinstall → Run from Xcode
```

### Monitor Events in Real-Time
```
# Console app filter
process:Klick AND (subsystem:com.klick.events OR message CONTAINS "Event Tracked")
```

---

## Contact & Support

**Questions**: Review implementation in:
- `MonetizationEvents.swift` - Event definitions
- `EventTrackingExtensions.swift` - Tracking methods
- `SalesPageView.swift` - Paywall tracking
- `StorageFullAlert.swift` - Upgrade prompt tracking

**Issues**: Check `monetization_event_tracking_a714e7d0.plan.md` for implementation details

---

**Last Updated**: February 14, 2026  
**Testing Status**: Ready for QA  
**Estimated Testing Time**: 2-3 hours for complete validation
