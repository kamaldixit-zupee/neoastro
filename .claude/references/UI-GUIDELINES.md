# NeoAstro iOS – UI Guidelines (Liquid Glass)

The app's visual language is **Liquid Glass** — Apple's iOS 26 material that refracts and shifts based on what is behind it. Every new surface (chrome, controls, sheets, banners) must be built with it. Flat opaque chrome and plain rounded-rect "card" surfaces are not acceptable.

> Companion: [ARCHITECTURE.md](../../ARCHITECTURE.md) for app structure, [FEATURES.md](../../FEATURES.md) for what's being built.

---

## 1. Why Liquid Glass for this app

- **Cosmic theme has texture.** The app already paints a `CosmicBackground` (gradient + animated stars). Glass surfaces refract that texture — opaque cards waste it.
- **iOS 26-only deployment target.** We do not need fallbacks. Use first-party glass APIs directly.
- **Brand alignment.** Astrology / divination UI works best when the chrome feels light and ethereal rather than physical.

If you find yourself reaching for an opaque rounded rectangle, stop. The right answer is glass over the cosmic background, not glass over flat color.

---

## 2. When to use Liquid Glass

| Surface | Material |
|---------|----------|
| Tab bar | System (`TabView` provides it on iOS 26 automatically) |
| Navigation bar | System (`NavigationStack` provides it on iOS 26 automatically) |
| Toolbars / pinned headers | `.glassEffect()` |
| Floating action buttons / icon controls | `.glassEffect(.regular, in: Circle())` |
| **Sheets / bottom sheets / modals** | **`.sheet { … }` — Liquid Glass is the default on iOS 26. Never override the background with an opaque fill. See § 4a.** |
| **Full-screen modal takeovers** | **`.fullScreenCover { … }` wrapped over `CosmicBackground`; chrome inside is `.glassEffect()`** |
| **Confirmation / action sheets** | **`.confirmationDialog` — system glass automatically** |
| **Alerts** | **`.alert` — system glass automatically** |
| Banners (top notification, update prompt, astrologer-online) | `.glassEffect()` over the cosmic backdrop |
| Search field | System (`searchable` ships glass on iOS 26) |
| Cards on the home feed | `.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))` |
| In-call / in-chat overlays (mute, hangup pill) | `.glassEffect(.regular, in: Capsule())` |
| Mini audio player | `.glassEffect()` capsule |

## 3. When NOT to use it

- **Full-screen backgrounds.** Glass needs something to refract; layering glass on flat color makes it look like translucent plastic. Use `CosmicBackground` or a brand gradient instead.
- **Body text containers.** Long-form reading (horoscope details, terms, helpdesk articles) needs WCAG-compliant contrast. Use solid `AppTheme.surface` color with elevation.
- **Glass on glass.** Do not stack multiple glass layers. Group inner controls in a `GlassEffectContainer` so they share a single glass plane.
- **Tiny labels and chips.** Glass needs surface area to read as a material. For chips < 44 pt height use a tinted solid pill instead.
- **Anything behind sensitive content.** Payment forms, KYC fields, OTP inputs — keep the field opaque so blurred-screen recordings can't reveal partial values.

---

## 4. SwiftUI APIs (iOS 26)

```swift
// Default glass over a shape
view.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))

// Tinted glass (use brand accent sparingly)
view.glassEffect(.regular.tint(AppTheme.pinkAccent.opacity(0.4)),
                 in: Capsule())

// Group multiple glass surfaces so they share a refraction plane
GlassEffectContainer(spacing: 12) {
    ButtonA().glassEffect()
    ButtonB().glassEffect()
}

// Animation continuity between two glass elements
.glassEffectID("hero-cta", in: namespace)

// Disable on platforms where it's unsupported (we don't need to today —
// deployment target is iOS 26 — but follow the API rather than fighting it)
```

### 4a. Modals and sheets — the rule

**Every modal in this app uses a Liquid Glass sheet.** Use SwiftUI's native presentations — `.sheet`, `.fullScreenCover`, `.confirmationDialog`, `.alert`, `.popover` — and let iOS 26 paint the Liquid Glass material. Do not roll your own modal `ZStack` with an opaque background.

```swift
// ✅ Bottom sheet — Liquid Glass is automatic
.sheet(isPresented: $showChatConfirmation) {
    ChatConfirmationSheet(astrologer: astro)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        // No background modifier — system Liquid Glass wins.
}

// ✅ If you must customise the sheet background, keep it glass
.sheet(isPresented: $showFilters) {
    FilterSheet()
        .presentationDetents([.fraction(0.4)])
        .presentationBackground(.regularMaterial)   // stays Liquid Glass on iOS 26
}

// ✅ Full-screen takeover (e.g. incoming call) — cosmic substrate, glass chrome
.fullScreenCover(isPresented: $showIncomingCall) {
    ZStack {
        CosmicBackground()
        IncomingCallView()
    }
}

// ✅ Confirmation
.confirmationDialog("End chat?", isPresented: $confirmEnd) {
    Button("End", role: .destructive) { vm.endChat() }
}

// ✅ Alert
.alert("Low balance", isPresented: $showLowBalance) {
    Button("Recharge") { vm.openRecharge() }
    Button("Cancel", role: .cancel) {}
}

// ❌ Hand-rolled modal with opaque background — never
.overlay {
    if showSheet {
        VStack { … }
            .background(Color.black.opacity(0.95))
            .cornerRadius(24)
    }
}

// ❌ Killing the system glass with an opaque presentationBackground
.sheet(isPresented: $show) {
    ContentView()
        .presentationBackground(Color.black)  // breaks the design language
}
```

**Detents.** Use `.medium` and `.large` defaults. Custom `.fraction` or `.height` detents are fine; just remember the drag indicator should stay visible (`.presentationDragIndicator(.visible)`) so users discover the gesture.

**Inside the sheet.** Content is opaque-where-it-needs-to-be (forms, payment fields, body text) but section headers, close buttons, and primary CTAs remain glass. Don't fill the whole sheet with one solid color — the Liquid Glass refraction is what frames the content visually.

---

### 4b. General SwiftUI APIs

Material variants on `.glassEffect(_:)`:
- `.regular` — default, daily use
- `.thin` — for compact pills, tight chrome where strong refraction would dominate
- `.thick` — reserved for emphatic panels (e.g., "low balance" recharge sheet)
- `.tint(Color)` — adds a subtle hue; keep opacity ≤ 0.4 to preserve glassiness

Avoid the older `.background(.ultraThinMaterial)` family unless you have a specific reason. Liquid Glass is the iOS 26 successor and looks different.

---

## 5. Composition with the cosmic theme

```swift
ZStack {
    CosmicBackground()                // gradient + StarsView
    VStack {
        HeaderBar()
            .glassEffect()             // refracts the gradient
        AstrologerCard(...)
            .glassEffect(.regular,
                         in: RoundedRectangle(cornerRadius: 24))
        Spacer()
        BottomActionPill()
            .glassEffect(.regular, in: Capsule())
    }
}
```

Rules of thumb:
- **CosmicBackground is the substrate.** It is what the glass refracts. Don't paint a solid color over it before adding glass — you've just made plastic.
- **Stars need to read through the glass.** If `StarsView` is invisible behind a card, increase the card's tint or move stars closer to the surface.
- **Pink accent for emphasis only.** `AppTheme.pinkAccent` is the brand tint; use it for tab indicators and the primary CTA, not for every chip.

---

## 6. Light & dark mode

Both modes are now supported (see [AGENTS.md](../../AGENTS.md)). Liquid Glass adapts automatically — but you must verify:

- `AppTheme` colors must define both light and dark values. Use `Color("…")` from the asset catalog, not hex literals scattered through the codebase.
- Brand gradients (cosmic, gold, pink) must look correct on both backgrounds. If they don't, define `light`/`dark` color sets, not separate gradient definitions.
- Custom-tinted glass needs a manual sanity check in light mode. A tint that looks subtle on dark gradient can be garish on a light one.
- Test every screen in both modes before marking the row in `FEATURES.md` as ✅.

---

## 7. Accessibility

- **Reduce Transparency.** When the user has `accessibilityReduceTransparency` on, the system replaces glass with solid materials automatically. Do not override this. If your design assumes the refraction (e.g., for hierarchy), provide an opaque equivalent — don't just hope it looks fine.
- **Contrast.** Text over glass must hit WCAG AA at minimum. Liquid Glass *adapts* to underlying content, but if the underlying content is high-contrast you may still fail. Validate with the Accessibility Inspector.
- **Reduce Motion.** Star animation and any glass cross-dissolve must respect `accessibilityReduceMotion`. Replace with cross-fade or a static state.
- **Hit targets.** Glass pill buttons must still hit the 44 × 44 minimum tap area, no matter how compact they look.
- **Dynamic Type.** Card content must reflow at large text sizes; do not pin glass containers to fixed heights.

---

## 8. Motion & state

- **Spring presets first.** Use system springs (`.smooth`, `.snappy`, `.bouncy`) before reaching for custom curves.
- **Glass surfaces fade, they don't slide.** When dismissing a sheet, prefer the system's drag-down — don't custom-translate a glass card off-screen, the refraction breaks at the edge.
- **State transitions on the same glass.** Use `.glassEffectID(_:in:)` to animate a primary button from one state to another (loading → done) so the material itself does the morph.
- **No drop shadows on glass.** Glass already implies depth via refraction. Adding a `.shadow()` makes it look like a sticker.

---

## 9. Tokens

These are the existing app tokens — keep them centralised in `AppTheme`, don't sprinkle hex values:

| Token | Use |
|-------|-----|
| `AppTheme.cosmicGradient` | App-level background |
| `AppTheme.goldGradient` | Premium / paid surfaces (consultation, wallet recharge) |
| `AppTheme.pinkAccent` | Primary CTA tint, tab indicator |
| `AppTheme.cardCorner` (24 pt) | Standard card / sheet corner radius |
| `AppTheme.tightCorner` (12 pt) | Chip / inline-control corner radius |
| `AppTheme.sectionSpacing` (18 pt) | Vertical rhythm between sections |
| `AppTheme.cardPadding` (14–24 pt) | Inside cards |

If you need a new token, add it to `AppTheme.swift`. Do not introduce a one-off literal in a feature file.

Typography uses system fonts. Headings use semibold weight; body uses regular; numbers (countdowns, balances) use `.monospacedDigit()` to prevent jitter.

---

## 10. Component checklist

Before merging a new screen, verify:

- [ ] Background is `CosmicBackground` or a brand gradient — never flat color
- [ ] Tab bar / nav bar use system glass (no opaque overlay)
- [ ] Cards use `.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))`
- [ ] Floating controls use `.glassEffect(.regular, in: Circle())` or `Capsule()`
- [ ] Modals use `.sheet` / `.fullScreenCover` / `.confirmationDialog` / `.alert` (system Liquid Glass) — no hand-rolled overlay modals
- [ ] No `.presentationBackground(Color.…)` overriding the system glass on a sheet
- [ ] No glass-on-glass stacking (verify with Reduce Transparency on)
- [ ] Long-form text containers are opaque, not glass
- [ ] Reduce Transparency / Reduce Motion fallbacks are visible and acceptable
- [ ] Both light and dark mode tested
- [ ] Dynamic Type up to AX5 doesn't clip the layout
- [ ] No drop shadows on glass surfaces
- [ ] No custom hex colors — all routed through `AppTheme`
- [ ] No `.ultraThinMaterial` / `.thickMaterial` slipping back in (use `.glassEffect`)
- [ ] No `print` debug calls on visual changes — use `AppLog`

---

## 11. Anti-patterns (don't do these)

```swift
// ❌ Plastic-on-color: glass over flat fill is not glass
ZStack {
    Color.black
    Card().glassEffect()
}

// ✅ Glass over textured background
ZStack {
    CosmicBackground()
    Card().glassEffect()
}
```

```swift
// ❌ Glass-on-glass
Card1().glassEffect()
    .overlay(Card2().glassEffect())

// ✅ Group surfaces share one glass plane
GlassEffectContainer { Card1(); Card2() }
```

```swift
// ❌ Drop shadow on glass
ButtonView().glassEffect().shadow(radius: 8)

// ✅ Refraction itself conveys depth
ButtonView().glassEffect()
```

```swift
// ❌ Long body text directly on glass
ScrollView { Text(longHoroscope) }.glassEffect()

// ✅ Opaque content surface, glass for chrome
ScrollView { Text(longHoroscope).background(AppTheme.surface) }
    .toolbar { ToolbarBar().glassEffect() }
```

```swift
// ❌ Hex literals
.foregroundStyle(Color(hex: "#FF66AA"))

// ✅ Token
.foregroundStyle(AppTheme.pinkAccent)
```

```swift
// ❌ Hand-rolled modal with an opaque scrim — kills Liquid Glass
ZStack {
    Color.black.opacity(0.6).ignoresSafeArea()
    VStack { … }
        .background(Color.black)
        .cornerRadius(24)
}

// ✅ System sheet — Liquid Glass for free
.sheet(isPresented: $show) {
    ContentView()
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
}
```

---

## 12. Existing screens — Liquid Glass status

The codebase already adopts `.glassEffect(...)` widely (cards, nav, tabs, banners). Status as of Batch 1:

| Screen | Status | Notes |
|--------|:------:|-------|
| `HomeView` | ✅ | Cards + hero banner glass; sheet presentation now uses system Liquid Glass + visible drag indicator (no `.presentationBackground(.clear)`) |
| `LoginView` / `OTPView` | ✅ | Phone / OTP boxes glass; `OTPBox` uses `GlassEffectContainer`; CTA pill is `.buttonStyle(.glass)` tinted pink |
| `WalletView` | ✅ | Balance hero → `AppTheme.balanceCardGradient` + glass; sheet presentation cleaned; transaction rows glass-on-row |
| `HoroscopeView` | ✅ | Type-picker pills, hero card, lucky chips, sentiment cards — all glass |
| `PanchangView` | ✅ | All widget tiles glass; long readings sit on opaque content |
| `AccountView` / `MoreView` | ✅ | Profile header glass; settings rows in clubbed glass box with hairline dividers |
| `SearchOverlayView` | ✅ | System search bar; category buttons `.buttonStyle(.glass)`; result rows glass |
| `ChatConfirmationSheet` | ✅ | System sheet glass; custom drag handle removed; uses `AppTheme.avatarPalette(for:)` |
| `JuspayPaymentSheet` | ✅ | System sheet glass; outer hand-rolled `.glassEffect` wrapper removed |
| `EditProfileView` | ⏳ | Verify in Batch 2 |
| `ConsultChatView` | 🟦 | Stub today — full glass build will land with the chat-flow batch |

**What was done in Batch 1:**

- Added `AppTheme.surface`, `AppTheme.tightCorner`, `AppTheme.sectionSpacing`, `AppTheme.cardPadding`, `AppTheme.balanceCardGradient`, `AppTheme.primaryAvatarPalette`, and `AppTheme.avatarPalette(for:)`.
- Removed `.presentationBackground(.clear)` from the two sheets that were killing system Liquid Glass.
- Removed custom drag-handle `Capsule()` shapes in favor of `.presentationDragIndicator(.visible)`.
- Removed the `ZStack { CosmicBackground(); ... }` wrapper inside sheet bodies — system glass refracts the parent view's cosmic background; the inner cosmic was redundant.
- Removed the outer `.glassEffect()` wrap around `JuspayPaymentSheet` content (system sheet provides Liquid Glass).
- Centralized avatar palettes into `AppTheme.avatarPalette(for:)` and `AppTheme.primaryAvatarPalette`; removed duplicated hex-string arrays from `AstrologerCard`, `ChatConfirmationSheet`, `AccountView`, `MoreView`.
- Replaced the wallet balance card's hex-literal gradient with `AppTheme.balanceCardGradient`.

Track ongoing migration in [FEATURES.md](../../FEATURES.md). A screen is not "✅ Done" until it complies with this doc.

---

## 13. Reference materials

- Apple HIG, "Materials" – the Liquid Glass section in the iOS 26 update.
- WWDC 2025 sessions on Liquid Glass and SwiftUI updates.
- The current `AppTheme.swift` — the single source of truth for tokens. If a designer hands you a new color, it lands in there before it lands anywhere else.
