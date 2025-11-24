# Klick - Onboarding Flow Documentation

**Last Updated**: November 1, 2025  
**Purpose**: Comprehensive guide to the multi-screen onboarding experience  
**File Reference**: `Klick/OnboardingFlowView.swift`

---

## 🎯 Overview

Klick's onboarding flow is a 7-screen narrative journey that introduces new users to the app's value proposition, core features, and personalization options. The flow is conversion-optimized with strategic Pro upsell placement and required goal selection.

### Design Philosophy

- **Progressive Disclosure**: Introduce features gradually without overwhelming users
- **Value-First**: Lead with benefits, not features
- **Conversion-Focused**: Every user sees the Pro offering
- **Personalized**: Capture user goals for tailored experience
- **Consistent UX**: Predictable navigation and CTAs

---

## 📋 Screen-by-Screen Breakdown

### Entry Point: Landing Page

**File**: `LandingPageView.swift`  
**Duration**: User-controlled (animated gallery)  
**Purpose**: Visual introduction with photography samples

**User Action**: Tap "Let's go" → Triggers `onboardingIntroduction = true`  
**Next**: OnboardingFlowView Screen 1 (Welcome)

---

### Screen 1: Welcome - "Capture people, beautifully"

**Struct**: `OnboardingScreen1`  
**Purpose**: Establish core value proposition

**Content**:
- **Headline**: "Capture people, beautifully."
- **Subtext**: "Master the art of portraits — from composition to expression — in just a few taps."
- **Hero Image**: `Rectangle_1` (340pt height, 20pt corner radius)
- **CTA**: "Continue"

**Animations**:
```swift
0.1s delay → Headline fades in (0.6s easeOut)
0.25s delay → Description fades in (0.6s easeOut)
0.4s delay → Image scales + fades in (0.7s spring)
```

**Navigation**:
- **Back**: Hidden (first screen)
- **Progress**: 1/7 (14%)
- **Skip**: Visible → Jumps to Screen 6 (Pro Upsell)
- **Continue**: → Screen 2

---

### Screen 2: Composition - "Frame like a pro"

**Struct**: `OnboardingScreen2`  
**Purpose**: Introduce composition guidance feature

**Content**:
- **Headline**: "Frame like a pro."
- **Subtext**: "Get smart composition guides that help you capture balance, light, and the perfect angle — every time."
- **Hero Image**: `Rectangle_3`
- **CTA**: "Continue"

**Animations**: Same pattern as Screen 1 (sequential reveal)

**Navigation**:
- **Back**: Visible → Screen 1
- **Progress**: 2/7 (29%)
- **Skip**: Visible → Screen 6
- **Continue**: → Screen 3

---

### Screen 3: Posing - "Bring out your best side"

**Struct**: `OnboardingScreen3`  
**Purpose**: Highlight posing and expression guidance

**Content**:
- **Headline**: "Bring out your best side."
- **Subtext**: "Explore pose ideas, expression tips, and real-time feedback made for portraits and people."
- **Hero Image**: `Rectangle_7`
- **CTA**: "Continue"

**Animations**: Sequential headline → description → image

**Navigation**:
- **Back**: Visible → Screen 2
- **Progress**: 3/7 (43%)
- **Skip**: Visible → Screen 6
- **Continue**: → Screen 4

---

### Screen 4: Editing - "Edit smarter, not harder"

**Struct**: `OnboardingScreen4`  
**Purpose**: Showcase editing and filter capabilities

**Content**:
- **Headline**: "Edit smarter, not harder."
- **Subtext**: "Apply studio-quality filters, adjust lighting, or retouch naturally — all guided by your style."
- **Hero Image**: `Rectangle_10`
- **CTA**: "Continue"

**Animations**: Sequential headline → description → image

**Navigation**:
- **Back**: Visible → Screen 3
- **Progress**: 4/7 (57%)
- **Skip**: Visible → Screen 6
- **Continue**: → Screen 5

---

### Screen 5: Achievement - "89% of users see huge difference"

**Struct**: `OnboardingScreen5_Achievement`  
**Purpose**: Social proof and psychological validation

**Content**:
- **Badge**: "User Success Rate" (Lime green background: RGB 124, 181, 24)
- **Headline**: "89% of users" + "see a huge difference after their first 3 photos."
- **Subtext**: "With our smart composition guide, your photos instantly look more balanced, expressive, and natural — no studio lighting needed."
- **CTA**: "Continue"

**Design Specifications**:
- **Badge**: Rounded rectangle (16pt radius), white text, golden yellow icon
- **Headline**: Large percentage (56pt bold) + description (24pt semibold)
- **Layout**: Vertically centered content with flexible spacers

**Animations**:
```swift
0.1s delay → Badge scales in (0.6s spring)
0.3s delay → Headline fades in (0.6s easeOut)
0.5s delay → Description fades in (0.6s easeOut)
```

**Navigation**:
- **Back**: Visible → Screen 4
- **Progress**: 5/7 (71%)
- **Skip**: Visible → Screen 6
- **Continue**: → Screen 6

**Psychology**: Leverages social proof (89% success rate) to build confidence before Pro pitch

---

### Screen 6: Pro Upsell - "Unlock your creative edge"

**Struct**: `OnboardingScreen6_ProUpsell`  
**Purpose**: Monetization - introduce premium features

**Content**:
- **Headline**: "Unlock your creative edge."
- **Subtext**: "Go Pro to access exclusive features and unlock your full potential."
- **Features** (animated sequentially):
  1. ✨ Exclusive premium filters
  2. 🪄 Advanced editing tools
  3. ⚡ Early feature releases
  4. 👁️‍🗨️ No ads, no limits
- **Primary CTA**: "Upgrade to Pro" (with star icon)
- **Secondary CTA**: "Maybe later" (subtle, 60% opacity)

**Animations**:
```swift
0.0s → Header (headline + description) fades in together (0.6s easeOut)
0.3s → Feature 1 slides in from left (0.5s easeOut)
0.5s → Feature 2 slides in (0.5s easeOut)
0.7s → Feature 3 slides in (0.5s easeOut)
0.9s → Feature 4 slides in (0.5s easeOut)
```

**Navigation**:
- **Back**: Visible → Screen 5
- **Progress**: 6/7 (86%)
- **Skip**: HIDDEN (intentional - forces decision)
- **Upgrade to Pro**: → Screen 7 (marks `hasSeenProUpsell = true`)
- **Maybe later**: → Screen 7

**Skip Logic**:
- No skip button (Option B implementation)
- Users must choose one of two CTAs
- Ensures 100% Pro offering visibility

**State Persistence**:
```swift
@AppStorage("hasSeenProUpsell") private var hasSeenProUpsell: Bool = false
```

---

### Screen 7: Personalization - "What brings you here?"

**Struct**: `OnboardingScreen7_Personalization`  
**Purpose**: Goal selection for personalized experience

**Content**:
- **Headline**: "Let's get to know you 👋 What brings you here?"
- **Subtext**: "This helps us understand your goals and build better experiences for you."
- **Goal Options** (4 choices, revealed sequentially):
  1. 📷 **Better Self-Portraits** - "Smarter selfies made simple"
  2. 🪄 **Pro-Looking Shots** - "Shoot like a pro, no gear needed"
  3. ✨ **Aesthetic Feed** - "Stand out with your style"
  4. 📐 **Learn Composition** - "Level up your framing skills"
- **CTA**: "Continue" (disabled until selection)

**Design Specifications**:
- **Options**: Radio button style with subtext
- **Selection State**: Golden yellow background (1.0, 0.8, 0.0) with black text
- **Default State**: Transparent with white text
- **Disabled CTA**: 30% opacity white background

**Animations**:
```swift
0.0s → Header fades in (0.6s easeOut)
0.3s → Option 1 fades in (0.5s easeOut)
0.5s → Option 2 fades in (0.5s easeOut)
0.7s → Option 3 fades in (0.5s easeOut)
0.9s → Option 4 fades in (0.5s easeOut)
```

**Interaction**:
- **Selection**: Tap option → Haptic feedback (selection) → Yellow highlight
- **Continue**: Disabled by default, enabled on selection
- **Local State**: Uses `@State private var localSelection` (not persisted until Continue)

**Navigation**:
- **Back**: Visible → Screen 6
- **Progress**: 7/7 (100%)
- **Skip**: HIDDEN (required screen)
- **Continue**: → Saves goal to AppStorage → Exits onboarding

**State Persistence**:
```swift
@AppStorage("userCreativeGoal") private var userCreativeGoal: String = ""
// Saved on Continue: "self-portraits", "pro-shots", "aesthetic-feed", "learn-composition"
```

---

## 🔄 Navigation Flow

### User Paths

#### Path 1: Complete Flow (Linear)
```
Landing → 1 → 2 → 3 → 4 → 5 → 6 → 7 → Permissions → Camera
```

#### Path 2: Skip to Pro (Optimized)
```
Landing → 1 [Skip] → 6 → 7 → Permissions → Camera
```

#### Path 3: Back Navigation
```
Any Screen → [Back] → Previous Screen (with backward slide animation)
```

### Navigation Rules

1. **Skip Button Visibility**:
   - Screens 1-5: ✅ Visible
   - Screen 6 (Pro): ❌ Hidden
   - Screen 7 (Personalization): ❌ Hidden

2. **Skip Behavior**:
   ```swift
   private func handleSkip() {
       navigationDirection = .forward
       currentScreen = .proUpsell // Always jumps to Screen 6
   }
   ```

3. **Back Button Visibility**:
   - Screen 1: ❌ Hidden (first screen)
   - Screens 2-7: ✅ Visible

4. **Progress Bar**:
   - Always visible
   - Animates smoothly on navigation
   - Formula: `CGFloat(rawValue) / 7`

---

## 🎨 Design System

### Typography

```swift
// Headlines
.font(.system(size: 32, weight: .bold, design: .rounded))
.foregroundColor(.white)

// Descriptions
.font(.system(size: 16, weight: .regular, design: .rounded))
.foregroundColor(.white.opacity(0.75))

// CTA Buttons
.font(.system(size: 18, weight: .semibold, design: .rounded))
.foregroundColor(.black) // on white background

// Badge Text
.font(.system(size: 12, weight: .semibold, design: .rounded))
.foregroundColor(.white)
```

### Colors

```swift
// Background
Color.black

// Accent (Golden Yellow)
Color(red: 1.0, green: 0.8, blue: 0.0)

// Success Badge (Lime Green)
Color(red: 124/255, green: 181/255, blue: 24/255)

// Text
.white (primary)
.white.opacity(0.75) (secondary)
.white.opacity(0.6) (tertiary - "Maybe later")
.white.opacity(0.7) (skip button)

// CTA Button
.white (background)
.black (text)
```

### Spacing

```swift
// Content padding
.padding(.horizontal, 24)

// Section spacing
Spacer().frame(height: 16) // Between headline & description
Spacer().frame(height: 40) // Between description & image/features
Spacer().frame(height: 24) // Achievement screen sections

// Bottom spacing
Spacer().frame(height: 40) // Before bottom edge
```

### Corner Radius

```swift
// Hero Images
RoundedRectangle(cornerRadius: 20, style: .continuous)

// CTA Buttons
RoundedRectangle(cornerRadius: 30)

// Badge
RoundedRectangle(cornerRadius: 16)

// Goal Options
RoundedRectangle(cornerRadius: 16)
```

---

## ⚡ Animation System

### Transition Animations

```swift
.transition(.asymmetric(
    insertion: .move(edge: navigationDirection == .forward ? .trailing : .leading)
        .combined(with: .opacity),
    removal: .move(edge: navigationDirection == .forward ? .leading : .trailing)
        .combined(with: .opacity)
))
```

**Behavior**:
- Forward navigation: Slides in from right, slides out to left
- Backward navigation: Slides in from left, slides out to right
- Always combined with opacity for smooth fade

### Content Animations

**Standard Pattern** (Screens 1-4):
```swift
DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
    withAnimation(.easeOut(duration: 0.6)) { showHeadline = true }
}
DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
    withAnimation(.easeOut(duration: 0.6)) { showDescription = true }
}
DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
    withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) { showImage = true }
}
```

**Achievement Screen** (Screen 5):
```swift
withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
    showStats = true // Badge
}
withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
    showHeadline = true // Percentage + text
}
DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
    withAnimation(.easeOut(duration: 0.6)) { showDescription = true }
}
```

**Pro Upsell Screen** (Screen 6):
```swift
withAnimation(.easeOut(duration: 0.6)) {
    showHeader = true // Headline + Description together
}
DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
    withAnimation(.easeOut(duration: 0.5)) { showFeature1 = true }
}
// Features 2-4 at 0.5s, 0.7s, 0.9s intervals
```

**Personalization Screen** (Screen 7):
```swift
withAnimation(.easeOut(duration: 0.6)) {
    showHeader = true // Headline + Description together
}
// Options revealed at 0.3s, 0.5s, 0.7s, 0.9s
```

**CTA Buttons**: No animation (immediately interactive)

---

## 🔧 State Management

### AppStorage Keys

```swift
// Landing Page
@AppStorage("onboardingIntroduction") var onboardingIntroduction: Bool = false
// Set to true when user taps "Let's go" on landing page

// Onboarding Completion
@AppStorage("onboardingFlowCompleted") var onboardingFlowCompleted: Bool = false
// Set to true when user completes Screen 7

// Pro Upsell Tracking
@AppStorage("hasSeenProUpsell") var hasSeenProUpsell: Bool = false
// Set to true when user reaches Screen 6 (regardless of choice)

// User Goal
@AppStorage("userCreativeGoal") var userCreativeGoal: String = ""
// Set when user selects goal on Screen 7 and taps Continue
// Values: "self-portraits", "pro-shots", "aesthetic-feed", "learn-composition"

// Permission Status
@AppStorage("permissionGranted") var permissionGranted: Bool = false
// Set to true after camera/photo permissions granted
```

### Local State (OnboardingFlowView)

```swift
@State private var currentScreen: OnboardingScreen = .welcome
@State private var navigationDirection: NavigationDirection = .forward

enum OnboardingScreen: Int, CaseIterable {
    case welcome = 1
    case composition = 2
    case posing = 3
    case editing = 4
    case achievement = 5
    case proUpsell = 6
    case personalization = 7
}

enum NavigationDirection {
    case forward
    case backward
}
```

### Screen-Specific State

Each screen manages its own animation states:
```swift
@State private var showHeadline = false
@State private var showDescription = false
@State private var showImage = false
// Pro Upsell: showFeature1, showFeature2, etc.
// Personalization: showOption1, showOption2, etc., localSelection
```

---

## 🧪 Test Mode

For development and testing, `LandingPageView` includes a test mode:

```swift
private let testMode = true // Set to false for production

@AppStorage("onboardingIntroduction") var onboardingIntroduction: Bool = false
@AppStorage("onboardingFlowCompleted") var onboardingFlowCompleted: Bool = false
@AppStorage("permissionGranted") var permissionGranted: Bool = false
@AppStorage("hasSeenProUpsell") var hasSeenProUpsell: Bool = false
@AppStorage("userCreativeGoal") var userCreativeGoal: String = ""

// Reset all onboarding states in test mode on app launch
var body: some View {
    ZStack {
        // ... content ...
    }
    .onAppear {
        if testMode {
            resetOnboardingStates()
        }
    }
}

private func resetOnboardingStates() {
    onboardingIntroduction = false
    onboardingFlowCompleted = false
    permissionGranted = false
    hasSeenProUpsell = false
    userCreativeGoal = ""
}
```

**Usage**: Enable `testMode = true` to reset onboarding on every app launch for testing

---

## 📊 Analytics Opportunities

### Recommended Tracking Events

```swift
// Screen Views
"onboarding_screen_viewed" { screen_number: Int, screen_name: String }

// Navigation Actions
"onboarding_skipped" { from_screen: String }
"onboarding_back_pressed" { from_screen: String, to_screen: String }
"onboarding_continued" { from_screen: String }

// Pro Upsell
"pro_upsell_viewed" { }
"pro_upgrade_tapped" { }
"pro_maybe_later_tapped" { }

// Personalization
"goal_selected" { goal: String }
"onboarding_completed" { goal: String, time_spent: TimeInterval }

// Conversion Funnel
"onboarding_started" { }
"onboarding_abandoned" { last_screen: String }
"onboarding_completed" { completion_path: "full" | "skipped" }
```

---

## 🎯 Conversion Optimization

### Current Strategy

1. **Skip to Pro**: Every user who skips sees Pro offering (100% exposure)
2. **No Escape from Pro**: Screen 6 has no skip button (forced decision)
3. **Required Personalization**: Screen 7 collects valuable user data
4. **Social Proof Before Pro**: Screen 5 builds confidence before pitch
5. **Two-CTA Design**: "Upgrade" vs "Maybe later" (not dismissive "Cancel")

### Future A/B Test Ideas

- **Badge Color**: Test different colors for success rate badge (current: lime green)
- **Pro Placement**: Test showing Pro upsell earlier (after Screen 3?)
- **Skip Copy**: Test "See all features" vs "Skip"
- **Personalization Requirement**: Test optional vs required goal selection
- **Feature Count**: Test 3 vs 4 vs 5 Pro features
- **CTA Copy**: Test variations of "Continue" (e.g., "Next", "Got it")

---

## ⚠️ Edge Cases & Error Handling

### Interrupted Onboarding

**Scenario**: User force-quits app during onboarding

**Behavior**:
- App reopens to landing page (if `onboardingFlowCompleted == false`)
- User must complete onboarding again
- No state restoration mid-flow

**Future Improvement**: Save `currentScreen` to resume where user left off

### Missing Hero Images

**Scenario**: Asset `Rectangle_X` not found

**Behavior**:
- SwiftUI shows placeholder (gray rectangle)
- Screen layout remains intact
- No crash, UX degraded

**Prevention**: Ensure all assets exist in `Assets.xcassets/Introduction/`

### Permission Denial

**Scenario**: User denies camera/photo permissions

**Behavior**:
- `PermissionFlowView` shows settings redirect
- User cannot reach camera until permissions granted
- Handled after onboarding completion

---

## 🔮 Future Enhancements

### Planned Features

1. **Onboarding Resume**: Save current screen to restore interrupted sessions
2. **Dynamic Content**: Localized copy and region-specific hero images
3. **Video Hero**: Replace static images with short video clips
4. **Interactive Elements**: Swipeable before/after comparisons
5. **Skip Confirmation**: "Are you sure?" modal before skipping
6. **Goal-Based Content**: Adjust Screen 6-7 content based on earlier interactions

### Technical Debt

1. **TODO in handleProUpgrade()**: Implement actual Pro upgrade flow
2. **Legacy OnboardFlowView**: Deprecate `OnboardFlowView.swift` and `OnboardingView.swift`
3. **Animation Timing**: Extract animation constants to centralized theme file
4. **Asset Organization**: Consolidate onboarding images into dedicated folder

---

## 📚 Related Documentation

- **Feature Reference**: `Documentation/5_Features/FEATURE_REFERENCE.md`
- **Component Map**: `Documentation/2_Architecture/COMPONENT_MAP.md`
- **Product Overview**: `Documentation/1_Product/PRODUCT_OVERVIEW.md`
- **State Management**: `Documentation/2_Architecture/STATE_MANAGEMENT.md`

---

## 🎓 Developer Notes

### Common Development Tasks

**1. Adding a New Screen**:
```swift
// Step 1: Add enum case
enum OnboardingScreen: Int, CaseIterable {
    case newScreen = 8
}

// Step 2: Create screen struct
struct OnboardingScreen8: View {
    let onContinue: () -> Void
    var body: some View { /* ... */ }
}

// Step 3: Add to switch statement
switch currentScreen {
    case .newScreen:
        OnboardingScreen8(onContinue: moveToNext)
    // ...
}

// Step 4: Update skip logic if needed
```

**2. Changing Copy**:
- Search for screen struct (e.g., `OnboardingScreen2`)
- Update `Text()` components
- Test animations aren't broken

**3. Adjusting Animations**:
- Modify `.onAppear` delays and durations
- Test transitions between screens
- Ensure CTA buttons remain non-animated

**4. Updating Skip Logic**:
- Modify `shouldShowSkipButton()` function
- Update `handleSkip()` destination
- Test all navigation paths

---

**Last Updated**: November 1, 2025  
**Version**: 1.0  
**Maintainer**: Development Team











