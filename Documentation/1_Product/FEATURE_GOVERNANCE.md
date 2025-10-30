# Feature Governance Framework - Preview & Examples

**Date**: October 30, 2025  
**Purpose**: Demonstrate how the new feature governance framework prevents scope creep and maintains product focus  
**Rule Location**: `.cursor/rules/feature-governance.mdc`

---

## 🎯 Overview

This document shows how the **Feature Governance Framework** would evaluate various feature proposals to protect Klick's core mission: **teaching photographers composition through real-time feedback**.

---

## 📊 Framework Quick Reference

### Evaluation Criteria (Total: 100 points)

| Criterion | Weight | Threshold |
|-----------|--------|-----------|
| Vision Alignment | 35% | Must teach composition |
| User Value | 30% | Solves photographer need |
| Technical Fit | 15% | Fits architecture |
| ROI | 10% | Effort justified |
| Brand Clarity | 10% | Maintains focus |

**Approval Threshold**: 70/100 minimum  
**Strong Candidate**: 85/100+

---

## 📝 Feature Evaluation Examples

### Example 1: ❌ REJECTED - Hotdog Detection

**Proposal**: "Add hotdog detection to identify food in photos"

#### Evaluation Breakdown

**Vision Alignment: 1/35** ❌
```
Question: Does it teach composition?
Answer: No - identifies objects, doesn't teach framing

Question: Helps photographers learn?
Answer: No - unrelated to photography skills

Question: Serves educational goals?
Answer: No - classification, not education
```

**User Value: 1/30** ❌
```
Question: Do target users need this?
Answer: No - photographers don't need hotdog detection

Question: Solves real problem?
Answer: No - creates a solution looking for a problem

Question: Improves learning experience?
Answer: No - distracts from composition learning
```

**Technical Fit: 3/15** ❌
```
Question: Fits existing architecture?
Answer: No - needs object classification system

Question: Reuses current systems?
Answer: No - Vision framework different API (VNClassifyImageRequest)

Question: Reasonable complexity?
Answer: No - requires Core ML models, training data
```

**ROI: 2/10** ❌
```
Question: Development time justified?
Answer: No - 10+ days for zero user value

Question: Better than roadmap alternatives?
Answer: No - Golden Ratio, Leading Lines far better
```

**Brand Clarity: 1/10** ❌
```
Question: Maintains focused identity?
Answer: No - confusing ("Why does camera app detect hotdogs?")

Question: Doesn't confuse value prop?
Answer: No - severely dilutes brand message
```

#### Total Score: 8/100 ❌

**Decision**: **REJECT IMMEDIATELY**

**Reasoning**:
- Fails on all criteria
- Classic feature creep
- Wrong product, wrong mission, wrong users
- Suggests fundamental misunderstanding of product vision

**Alternative**: If food identification is needed, create separate app with focused mission

---

### Example 2: ✅ APPROVED - Golden Ratio Composition

**Proposal**: "Add Golden Ratio spiral overlay for composition guidance"

#### Evaluation Breakdown

**Vision Alignment: 35/35** ✅
```
Question: Does it teach composition?
Answer: Yes - fundamental composition technique

Question: Helps photographers learn?
Answer: Yes - teaches mathematical beauty in framing

Question: Serves educational goals?
Answer: Yes - core photography education principle
```

**User Value: 28/30** ✅
```
Question: Do target users need this?
Answer: Yes - requested composition technique

Question: Solves real problem?
Answer: Yes - photographers want to learn Golden Ratio

Question: Improves learning experience?
Answer: Yes - expands composition technique arsenal
```

**Technical Fit: 14/15** ✅
```
Question: Fits existing architecture?
Answer: Yes - perfect CompositionService implementation

Question: Reuses current systems?
Answer: Yes - same Vision detection, overlay system

Question: Reasonable complexity?
Answer: Yes - geometric calculation, existing patterns
```

**ROI: 9/10** ✅
```
Question: Development time justified?
Answer: Yes - 3-4 days for high-value feature

Question: Better than roadmap alternatives?
Answer: Yes - on roadmap, high priority
```

**Brand Clarity: 10/10** ✅
```
Question: Maintains focused identity?
Answer: Yes - strengthens "composition teaching" brand

Question: Doesn't confuse value prop?
Answer: Yes - exactly what users expect from us
```

#### Total Score: 96/100 ✅

**Decision**: **APPROVED**

**Implementation Plan**:
1. Create `GoldenRatioService` implementing `CompositionService`
2. Calculate Fibonacci spiral overlay
3. Detect subject alignment with spiral
4. Add educational content about Golden Ratio
5. Update `CompositionType` enum
6. Register in `CompositionManager`

**Timeline**: 3-4 days  
**Priority**: High (Roadmap item)

---

### Example 3: ⚠️ CONDITIONAL - Food Photography Mode

**Proposal**: "Add specialized composition rules for food photography"

#### Evaluation Breakdown

**Vision Alignment: 25/35** ⚠️
```
Question: Does it teach composition?
Answer: Yes - but very specialized composition

Question: Helps photographers learn?
Answer: Yes - but narrow niche of food photography

Question: Serves educational goals?
Answer: Partially - expands scope significantly
```

**User Value: 20/30** ⚠️
```
Question: Do target users need this?
Answer: Some - food photography subset of users

Question: Solves real problem?
Answer: Yes - food has specific composition rules

Question: Improves learning experience?
Answer: Yes, but for limited audience
```

**Technical Fit: 14/15** ✅
```
Question: Fits existing architecture?
Answer: Yes - new CompositionService implementations

Question: Reuses current systems?
Answer: Yes - same detection and overlay system

Question: Reasonable complexity?
Answer: Yes - follows existing patterns
```

**ROI: 6/10** ⚠️
```
Question: Development time justified?
Answer: Uncertain - 10+ days for niche feature

Question: Better than roadmap alternatives?
Answer: No - general techniques serve more users
```

**Brand Clarity: 7/10** ⚠️
```
Question: Maintains focused identity?
Answer: Somewhat - expands to vertical-specific

Question: Doesn't confuse value prop?
Answer: Somewhat - are we general or food-focused?
```

#### Total Score: 72/100 ⚠️

**Decision**: **CONDITIONAL - DEFER to v2.0**

**Reasoning**:
- Passes minimum threshold (72 > 70)
- BUT: Represents significant scope expansion
- Should include complete feature set:
  - Overhead 90° angle composition
  - 45° hero shot guidance
  - Natural lighting detection
  - Negative space for food
  - Prop arrangement suggestions
- Better as v2.0 feature after core techniques proven

**Requirements for Approval**:
1. Complete v1.0 core composition features first
2. Market validation showing food photographer demand
3. Full feature specification (not one-off addition)
4. Educational content for all food composition rules

---

### Example 4: ❌ REJECTED - Social Media Sharing

**Proposal**: "Add buttons to share photos directly to Instagram/Facebook"

#### Evaluation Breakdown

**Vision Alignment: 5/35** ❌
```
Question: Does it teach composition?
Answer: No - just distribution mechanism

Question: Helps photographers learn?
Answer: No - unrelated to learning

Question: Serves educational goals?
Answer: No - convenience feature only
```

**User Value: 15/30** ⚠️
```
Question: Do target users need this?
Answer: No - iOS share sheet already exists

Question: Solves real problem?
Answer: No - users can already share via Photos

Question: Improves learning experience?
Answer: No - distribution, not learning
```

**Technical Fit: 10/15** ⚠️
```
Question: Fits existing architecture?
Answer: Somewhat - needs social SDK integration

Question: Reuses current systems?
Answer: Minimal - new networking layer

Question: Reasonable complexity?
Answer: Medium - SDK integration, auth flows
```

**ROI: 3/10** ❌
```
Question: Development time justified?
Answer: No - 5-7 days for feature available elsewhere

Question: Better than roadmap alternatives?
Answer: No - composition features far more valuable
```

**Brand Clarity: 2/10** ❌
```
Question: Maintains focused identity?
Answer: No - looks like social media app

Question: Doesn't confuse value prop?
Answer: No - "Is this Instagram competitor?"
```

#### Total Score: 35/100 ❌

**Decision**: **REJECT**

**Reasoning**:
- Well below threshold (35 << 70)
- Users already have share functionality via iOS
- Adds maintenance burden (SDK updates, auth changes)
- Dilutes brand as composition teaching tool
- Resource better spent on core mission

**Alternative**: Users can share via native iOS share sheet

---

### Example 5: ✅ APPROVED - Leading Lines Detection

**Proposal**: "Detect and highlight leading lines in camera view to teach this composition technique"

#### Evaluation Breakdown

**Vision Alignment: 34/35** ✅
```
Question: Does it teach composition?
Answer: Yes - fundamental composition principle

Question: Helps photographers learn?
Answer: Yes - teaches eye guidance through photos

Question: Serves educational goals?
Answer: Yes - core photography technique
```

**User Value: 29/30** ✅
```
Question: Do target users need this?
Answer: Yes - highly requested technique

Question: Solves real problem?
Answer: Yes - leading lines hard to spot for beginners

Question: Improves learning experience?
Answer: Yes - interactive detection teaches recognition
```

**Technical Fit: 13/15** ✅
```
Question: Fits existing architecture?
Answer: Yes - new CompositionService + line detection

Question: Reuses current systems?
Answer: Mostly - Vision framework edge detection

Question: Reasonable complexity?
Answer: Medium - edge detection + line analysis
```

**ROI: 8/10** ✅
```
Question: Development time justified?
Answer: Yes - 5-7 days for high-value feature

Question: Better than roadmap alternatives?
Answer: Yes - on roadmap, high priority
```

**Brand Clarity: 10/10** ✅
```
Question: Maintains focused identity?
Answer: Yes - perfect composition teaching feature

Question: Doesn't confuse value prop?
Answer: Yes - exactly our mission
```

#### Total Score: 94/100 ✅

**Decision**: **APPROVED**

**Implementation Considerations**:
- Use Vision framework edge detection
- Implement line segment detection algorithm
- Calculate convergence points
- Show overlay guiding eye to subject
- Add educational content about leading lines

**Complexity Note**: More complex than other services but justified by high value

---

### Example 6: ❌ REJECTED - Weather Overlay

**Proposal**: "Show weather information overlay on camera view"

#### Evaluation Breakdown

**Vision Alignment: 0/35** ❌
```
Question: Does it teach composition?
Answer: No - completely unrelated

Question: Helps photographers learn?
Answer: No - weather doesn't teach framing

Question: Serves educational goals?
Answer: No - information display, not education
```

**User Value: 8/30** ❌
```
Question: Do target users need this?
Answer: No - can check weather app

Question: Solves real problem?
Answer: No - convenience at best

Question: Improves learning experience?
Answer: No - distracts from composition focus
```

**Technical Fit: 5/15** ❌
```
Question: Fits existing architecture?
Answer: No - needs weather API, location services

Question: Reuses current systems?
Answer: No - completely new integration

Question: Reasonable complexity?
Answer: Medium - API key, networking, parsing
```

**ROI: 1/10** ❌
```
Question: Development time justified?
Answer: No - 3-4 days for zero educational value

Question: Better than roadmap alternatives?
Answer: No - all roadmap items better
```

**Brand Clarity: 1/10** ❌
```
Question: Maintains focused identity?
Answer: No - "Why does composition app show weather?"

Question: Doesn't confuse value prop?
Answer: No - makes us look unfocused
```

#### Total Score: 15/100 ❌

**Decision**: **REJECT IMMEDIATELY**

**Reasoning**:
- Massive failure on all criteria
- Classic scope creep
- Distracts from core mission
- Users have weather apps

---

### Example 7: ✅ APPROVED - Histogram Overlay for Exposure

**Proposal**: "Add histogram overlay to help photographers understand exposure distribution"

#### Evaluation Breakdown

**Vision Alignment: 28/35** ✅
```
Question: Does it teach composition?
Answer: Partially - teaches exposure as composition element

Question: Helps photographers learn?
Answer: Yes - fundamental photography concept

Question: Serves educational goals?
Answer: Yes - technical foundation for composition
```

**User Value: 26/30** ✅
```
Question: Do target users need this?
Answer: Yes - exposure critical to composition

Question: Solves real problem?
Answer: Yes - beginners struggle with exposure

Question: Improves learning experience?
Answer: Yes - visual feedback on technical aspect
```

**Technical Fit: 14/15** ✅
```
Question: Fits existing architecture?
Answer: Yes - analyzes existing frame data

Question: Reuses current systems?
Answer: Yes - uses CVPixelBuffer from camera

Question: Reasonable complexity?
Answer: Low - pixel analysis, simple overlay
```

**ROI: 9/10** ✅
```
Question: Development time justified?
Answer: Yes - 2-3 days for valuable feature

Question: Better than roadmap alternatives?
Answer: Equal - enhances existing features
```

**Brand Clarity: 9/10** ✅
```
Question: Maintains focused identity?
Answer: Yes - photography education tool

Question: Doesn't confuse value prop?
Answer: Yes - enhances composition teaching
```

#### Total Score: 86/100 ✅

**Decision**: **APPROVED**

**Reasoning**:
- Exposure is foundational to composition
- Teaches technical aspect that affects framing
- Low complexity, high educational value
- Complements composition analysis

---

## 📊 Summary Statistics

### Feature Evaluation Results

| Feature | Score | Decision | Primary Reason |
|---------|-------|----------|----------------|
| Hotdog Detection | 8/100 | ❌ REJECT | Zero composition teaching |
| Golden Ratio | 96/100 | ✅ APPROVE | Core composition technique |
| Food Photography | 72/100 | ⚠️ DEFER | Scope expansion, needs v2.0 |
| Social Sharing | 35/100 | ❌ REJECT | Available elsewhere, off-mission |
| Leading Lines | 94/100 | ✅ APPROVE | Fundamental technique |
| Weather Overlay | 15/100 | ❌ REJECT | Completely unrelated |
| Histogram | 86/100 | ✅ APPROVE | Foundational to composition |

### Score Distribution

```
Approved (≥85):  3 features (42.8%)
Conditional (70-84): 1 feature (14.3%)
Rejected (<70):  3 features (42.8%)
```

### Common Rejection Reasons

1. **Doesn't teach composition** - 100% of rejections
2. **Wrong target users** - 100% of rejections  
3. **Feature creep** - 100% of rejections
4. **Available elsewhere** - 66% of rejections
5. **Dilutes brand** - 100% of rejections

---

## 🎯 Key Insights

### What Gets Approved

**Pattern**: Features that...
- ✅ Directly teach composition techniques
- ✅ Help photographers improve framing skills
- ✅ Provide real-time educational feedback
- ✅ Extend existing architectural patterns
- ✅ Align with roadmap priorities

**Examples**: Golden Ratio, Leading Lines, Histogram

### What Gets Rejected

**Pattern**: Features that...
- ❌ Don't relate to composition teaching
- ❌ Serve wrong user base or needs
- ❌ Dilute product focus and identity
- ❌ Duplicate existing functionality
- ❌ Break architectural patterns

**Examples**: Hotdog detection, Social sharing, Weather

### The "Composition Teaching Test"

**Simple litmus test**: "Does this help a photographer learn to frame better photos?"

- If YES → Evaluate further
- If NO → Reject immediately
- If MAYBE → Probably NO

---

## 🛡️ Framework Benefits

### Before Framework

**Risks**:
- Feature creep: "Let's also add..."
- Scope drift: Losing focus on core mission
- Resource waste: Building features users don't need
- Brand confusion: "What does this app do?"

### After Framework

**Protection**:
- ✅ Clear decision criteria prevent scope creep
- ✅ Objective scoring reduces subjective bias
- ✅ Vision alignment mandatory, not optional
- ✅ Documentation of decision rationale
- ✅ Product focus maintained over time

### Real Example Impact

**Without Framework**:
- "Hotdog detection? Sure, why not!"
- 10 days of development
- Zero user value
- Confused brand identity
- Maintenance burden forever

**With Framework**:
- Hotdog detection scores 8/100
- Immediate rejection with clear reasoning
- 10 days saved for Golden Ratio instead
- Product focus maintained
- Happy users learning composition

---

## 📋 Using the Framework

### For Agent/AI Development

**Before implementing ANY feature**:

1. **Check**: Does it teach composition?
   - NO → Stop immediately, reject
   - YES → Continue to step 2

2. **Evaluate**: Complete scoring framework
   - < 70 → Reject with reasoning
   - 70-84 → Needs strong justification
   - 85+ → Strong candidate, proceed

3. **Verify**: Check technical fit
   - Breaks patterns → Reject
   - Extends patterns → Approve

4. **Document**: Record decision and score
   - Update feature catalog
   - Note reasoning for future reference

### For Product Planning

**When considering roadmap**:
- Run all features through framework
- Prioritize high-scoring items (90+)
- Reject low-scoring items (<70)
- Re-evaluate conditional items quarterly

### For Stakeholder Requests

**When feature is requested**:
- Apply framework transparently
- Share scoring with stakeholder
- Explain rejection criteria
- Suggest on-mission alternatives

---

## 🎓 Lessons Learned

### Product Discipline

> "The art of product management is knowing what NOT to build."

**Key Lesson**: Saying "no" to 95% of ideas lets you say "yes" to the right 5%.

### Focus as Strategy

> "Klick teaches composition. Period."

**Key Lesson**: Every "yes" to off-mission feature is a "no" to better on-mission feature.

### The "Hotdog Test"

> "If we can't explain why a composition camera detects hotdogs, we shouldn't build it."

**Key Lesson**: If feature requires gymnastics to justify, it doesn't fit.

---

## 🚀 Next Steps

### Framework Implementation

1. ✅ Create governance rule (`.cursor/rules/feature-governance.mdc`)
2. ✅ Update index to reference governance (`.cursor/rules/oIndex.mdc`)
3. ✅ Document examples and preview (this file)
4. ⏳ Apply to future feature requests
5. ⏳ Review quarterly for effectiveness

### Recommended Process

**For each new feature proposal**:
1. Read governance rule
2. Complete evaluation framework
3. Document scoring and reasoning
4. Make decision based on threshold
5. Update feature catalog

### Success Metrics

**Healthy Product**:
- 90%+ features score >85
- Zero features <70 implemented
- Clear roadmap alignment
- Focused brand identity

---

## 📚 References

- **Governance Rule**: `.cursor/rules/feature-governance.mdc`
- **Product Vision**: `Documentation/1_Product/PRODUCT_OVERVIEW.md`
- **Feature Catalog**: `Documentation/1_Product/FEATURE_CATALOG.md`
- **Architecture**: `Documentation/2_Architecture/ARCHITECTURE_OVERVIEW.md`

---

**Last Updated**: October 30, 2025  
**Status**: Framework Active  
**Enforcement**: Mandatory for all features

---

## 💡 Remember

> "A good product does one thing exceptionally well. A bad product does many things adequately."

**Klick's one thing**: Teaching composition through real-time feedback.

**Everything else**: Distraction or future opportunity.

**Default answer to new features**: NO

**Right question**: "Does this teach composition?"

