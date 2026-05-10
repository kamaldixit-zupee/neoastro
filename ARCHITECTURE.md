# NeoAstro iOS – Architecture & Context

## Project Overview

NeoAstro iOS is the **user-facing native iPhone client** for the NeoAstro astrology consultation platform (Zupee superapp / NeoAstro line of business). It is a single-target SwiftUI app written in Swift 5.10, structured around the iOS 17+ `@Observable` macro with no third-party dependencies.

The app talks to the same Zupee backend that powers the React Native user app (`zupee-rn-astro`). It is the iOS counterpart, intentionally mirroring the Android user app's API contract (note the spoofed `com.neoastro.android` package name in `DeviceInfo`).

---

## High-Level Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                         NeoAstro iOS App                          │
├──────────────────────────────────────────────────────────────────┤
│                                                                    │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │                      App / Entry                             │  │
│  │   NeoAstroApp (@main) → RootView → MainTabView (5 tabs)     │  │
│  └────────────────────────────────────────────────────────────┘  │
│                              │                                     │
│         ┌────────────────────┼────────────────────┐               │
│         ▼                    ▼                    ▼                │
│  ┌────────────┐      ┌────────────┐       ┌────────────┐         │
│  │  Features  │      │ Components │       │ Navigation │         │
│  │  (MVVM)    │      │  (shared)  │       │ (Root+Tab) │         │
│  └────────────┘      └────────────┘       └────────────┘         │
│         │                                                          │
│         ▼                                                          │
│  ┌────────────┐      ┌────────────┐       ┌────────────┐         │
│  │  Services  │ ───▶ │ Networking │ ───▶  │   Models   │         │
│  │ (facades)  │      │ (URLSession│       │   (DTOs)   │         │
│  │            │      │  + auth)   │       │            │         │
│  └────────────┘      └────────────┘       └────────────┘         │
│         │                    │                                     │
│         ▼                    ▼                                     │
│  ┌────────────┐      ┌────────────┐                              │
│  │   AppLog   │      │ TokenStore │                              │
│  │ (os.Logger)│      │ (Keychain) │                              │
│  └────────────┘      └────────────┘                              │
│                                                                    │
├──────────────────────────────────────────────────────────────────┤
│              Backend (Zupee superapp infrastructure)               │
│   stage: cse-sna-superapp-service.neoastrojoy.com                 │
│   prod : api.neoastro.com                                         │
└──────────────────────────────────────────────────────────────────┘
```

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Language | Swift 5.10 |
| UI | SwiftUI (no UIKit screens, no storyboards) |
| State | `@Observable` macro + `@MainActor` (Observation framework, **not** Combine) |
| Concurrency | Swift Structured Concurrency (`async`/`await`, actors) |
| Networking | `URLSession` wrapped in a singleton actor |
| Realtime | `socket.io-client-swift` wrapped in a `NeoAstroSocket` actor (Batch 4) |
| Audio | `AVFoundation` (`AVAudioRecorder`, `AVAudioPlayer`); `AVKit` for video stories |
| Photos | `PhotosUI.PhotosPicker` for chat images + profile picture |
| Push | APNs via `UIApplicationDelegateAdaptor` + `UNUserNotificationCenter` |
| Persistence | Keychain (tokens, language, onboarding flag); **no** Core Data, SwiftData, or UserDefaults |
| Logging | `os.Logger` via `AppLog` wrapper |
| Project gen | XcodeGen (`project.yml` is the source of truth) |
| Min iOS | iOS 26.0 (year-numbered) |
| Device | iPhone only, portrait-locked, dark and light mode both |
| Dependencies | `socket.io-client-swift` (16.1+) — first and currently only third-party SPM dep. Adding more requires a discussion. |
| Tests | None yet |

---

## Source Tree

```
NeoAstro/
├── NeoAstro/                        # All app source
│   ├── App/
│   │   ├── NeoAstroApp.swift        # @main; injects auth/config/realtime/deepLinks via .environment
│   │   ├── AppDelegate.swift        # UIApplicationDelegate for APNs + notification taps
│   │   ├── AppTheme.swift           # Tokens (gradients, palettes, surface, corners, spacing)
│   │   ├── AppConfigStore.swift     # @Observable bootstrap store — pre/post signup config + user details
│   │   └── DeepLinkRouter.swift     # @Observable router for `neoastro://…` URLs + notification taps
│   ├── Components/                  # Reusable SwiftUI bits (no business logic)
│   │   ├── AvatarView.swift
│   │   ├── HexColor.swift           # Color(hex:) extension
│   │   └── KeyboardDismiss.swift
│   ├── Features/                    # One folder per screen/flow (MVVM)
│   │   ├── Auth/                    # LoginView, OTPView, AuthViewModel (stage machine)
│   │   ├── Splash/                  # SplashView (cold-start config + routing)
│   │   ├── Onboarding/              # LanguageSelectionView, OnboardingView (4-step birth-details wizard)
│   │   ├── Home/                    # HomeView + AstrologerCard + AstrologerProfile(+VM) + StoriesView + ChatConfirmationSheet
│   │   ├── Horoscope/               # HoroscopeView + ViewModel
│   │   ├── Panchang/                # PanchangView + ViewModel
│   │   ├── Wallet/                  # WalletView + ViewModel + JuspayPaymentSheet + Tx detail/TDS/Cashback/Invoices/FilterSheet
│   │   ├── Account/                 # AccountView, EditProfileView (PhotosPicker), ViewModel
│   │   ├── More/                    # MoreView + ViewModel (settings hub)
│   │   ├── Search/                  # SearchOverlayView
│   │   ├── Chat/                    # ChatView + ViewModel + MessageBubble (text/audio/image) + ChatInputBar + VoiceRecorderOverlay
│   │   ├── Conversations/           # ConversationsView + ChatHistoryView (read-only viewer)
│   │   ├── FreeAsk/                 # SelectFreeQuestion → Compose → Waiting → Answers (+ Flow wrapper)
│   │   ├── FreeChat/                # FreeChatWaitingView + FreeChatFlow
│   │   ├── Calls/                   # IncomingCallView (full-screen Liquid Glass)
│   │   └── Notifications/           # NotificationCenterView + reusable NudgeBanner
│   ├── Models/
│   │   └── API/                     # All wire-format DTOs (Codable)
│   │       ├── AuthAPI.swift
│   │       ├── AstrologerAPI.swift     # + Story / Education / Review / Popup / Metadata
│   │       ├── ProfileAPI.swift
│   │       ├── HoroscopeAPI.swift
│   │       ├── PanchangAPI.swift
│   │       ├── WalletAPI.swift         # + TDS / Cashback / Invoice / TxFilter
│   │       ├── UserSettingsAPI.swift
│   │       ├── ConfigAPI.swift         # pre/post signup + onboarding submission
│   │       ├── NotificationAPI.swift   # push token + notification list + nudges
│   │       ├── ChatHistoryAPI.swift    # conversation + historical-message DTOs
│   │       └── FreeAskAPI.swift        # categories + REST body
│   ├── Navigation/
│   │   ├── RootView.swift           # Switches on auth.stage (splash/lang/login/otp/onboarding/auth) + IncomingCallView fullScreenCover
│   │   └── MainTabView.swift        # 5-tab TabView + HomeSearchCoordinator + DeepLinkRouter tab switching
│   ├── Networking/
│   │   ├── APIClient.swift          # actor; send<T>, refresh on 401, envelope detection
│   │   ├── APIEnvironment.swift     # .stage / .prod base URLs
│   │   ├── APIError.swift           # LocalizedError enum
│   │   ├── ZupeeEnvelope.swift      # Three response envelope shapes
│   │   ├── TokenStore.swift         # Keychain — tokens, language, onboardingCompleted
│   │   ├── DeviceInfo.swift         # Spoofed Android headers for API parity
│   │   └── AppLog.swift             # os.Logger categories
│   ├── Realtime/                    # Batch 4 — Socket.IO realtime stack
│   │   ├── SocketEvent.swift        # String-typed enum of every event in the protocol
│   │   ├── SocketEnvelope.swift     # `{ en, data }` codec on req/res channels
│   │   ├── SocketManager.swift      # `NeoAstroSocket` actor — handshake, reconnect, emit, AsyncStream
│   │   ├── ReconnectionPolicy.swift # Linear / exponential backoff helper
│   │   ├── EventValidation.swift    # EVENTS_REQUIRING_* / SKIP_IF_* guards (ported from RN)
│   │   ├── RealtimeStore.swift      # @Observable bridge — activeChat, presence, unread, incomingCall, free ask state
│   │   ├── Models/
│   │   │   └── RealtimeEvents.swift # Typed payload structs per domain
│   │   ├── Audio/
│   │   │   ├── AudioRecorder.swift  # AVAudioRecorder wrapper for voice notes
│   │   │   └── AudioPlayer.swift    # AVAudioPlayer singleton for in-chat playback
│   │   └── handlers/                # Per-domain event handlers
│   │       ├── ConnectionEventHandler.swift
│   │       ├── ChatEventHandler.swift
│   │       ├── CallEventHandler.swift
│   │       ├── PresenceEventHandler.swift
│   │       ├── NotificationEventHandler.swift
│   │       └── FreeAskEventHandler.swift
│   ├── Services/                    # Stateless `enum` API facades
│   │   ├── AuthService.swift
│   │   ├── ProfileService.swift
│   │   ├── AstrologerService.swift  # list / getProfile / reviews / notifyMe / popup / metadata
│   │   ├── HoroscopeService.swift
│   │   ├── PanchangService.swift
│   │   ├── WalletService.swift      # screen / passbook / TDS / cashback / invoices / filters / convert / checkout
│   │   ├── UserSettingsService.swift
│   │   ├── ConfigService.swift
│   │   ├── OnboardingService.swift
│   │   ├── NotificationService.swift
│   │   ├── ChatHistoryService.swift # conversations + per-astro history + delete
│   │   ├── ChatMediaService.swift   # voice/image presigned upload
│   │   └── FreeAskService.swift     # REST submit fallback + free-chat match
│   └── Resources/
│       ├── Info.plist               # CFBundleURLTypes (`neoastro` scheme), mic + photo usage strings
│       └── Assets.xcassets/
├── NeoAstro.xcodeproj/              # Generated by XcodeGen; do NOT hand-edit
└── project.yml                      # XcodeGen spec (source of truth for build settings + SPM packages)
```

---

## Architecture Pattern – MVVM with `@Observable`

Every feature folder follows the same shape:

```
Features/<FeatureName>/
├── <FeatureName>View.swift          # SwiftUI View; @State private var vm = ...VM()
├── <FeatureName>ViewModel.swift     # @Observable @MainActor final class
└── <Supporting views>.swift         # Cards, sheets, sections specific to the feature
```

The ViewModel:

- Is annotated `@Observable @MainActor final class`.
- Holds raw state (e.g. `var allAstrologers: [AstrologerAPI] = []`) and computed view state (e.g. `var astrologers: [AstrologerAPI]` filtered by search).
- Exposes `async` methods (`loadInitial()`, `refresh()`); never returns `Combine.Publisher`.
- Calls into `Services` and translates errors into `errorMessage: String?`.

The View:

- Owns the VM with `@State private var vm = FeatureViewModel()` (local instantiation).
- Reads state directly (`vm.isLoading`, `vm.astrologers`); SwiftUI re-renders automatically thanks to `@Observable`.
- Pushes child views via `NavigationStack` + `.navigationDestination(item:)`.

There is no global DI container. Cross-screen coordination is done via `.environment(value)` for shared `@Observable` objects (the only one today is `AuthViewModel` from `NeoAstroApp`, plus `HomeSearchCoordinator` inside `MainTabView`).

---

## Networking Layer

### `APIClient` (`Networking/APIClient.swift`)

- Singleton `actor` wrapping a single `URLSession` (30 s request / 60 s resource timeout).
- `send<T: Decodable>(_ request: Request, as: T.Type) async throws -> T` is the only entry point.
- Builds requests with `buildURLRequest(_:)` which always attaches:
  - `authorization` (raw token, **no** `Bearer` prefix) when `requiresAuth`
  - `ludoUserId` from `TokenStore.userId`
  - Device headers from `DeviceInfo` (`Platform`, `appversion`, `appname`, `packageName`, `language`, `deviceId`, `x-zupee-env`)
- On HTTP `401` it triggers a single de-duplicated refresh call to `/v1.0/refreshToken`, updates `TokenStore`, and replays the original request once. Failed refresh → `TokenStore.clear()` + throw `unauthorized`.

### Envelope detection

The Zupee backend returns at least three envelope shapes. `APIClient.send` tries them in order:

1. `ZupeeEnvelope<T>` – `{ success, response: { data: T } }`
2. `ResponseOnlyEnvelope<T>` – `{ success, response: T }`
3. Direct `T` – payload at the root

If `success == false` the client throws `APIError.businessFailure(message)` so the ViewModel can show the server message.

### `APIError`

```swift
enum APIError: LocalizedError {
    case invalidResponse
    case unauthorized
    case server(status: Int, message: String?)
    case decoding(Error)
    case transport(Error)
    case businessFailure(String?)
}
```

### `TokenStore` (Keychain)

- `service = "com.neoastro.tokens"`, `kSecAttrAccessibleAfterFirstUnlock`.
- Stores: `accessToken`, `refreshToken`, `userId`, `zupeeUserId`, `zodiacName`, `mobileNumber`.
- `isAuthenticated` is a derived computed property (both tokens present).
- Failures are silent – callers must check `isAuthenticated` before assuming a token exists.

### `DeviceInfo`

Static struct with the Android-app-equivalent headers the backend expects:

| Header | Value |
|--------|-------|
| `appname` / `zupeeAppName` | `com.neoastro.android` |
| `appversion` / `buildVersionCode` | `512` |
| `appVersionName` | `1.2512.07_ASTRO_IOS` |
| `Platform` | `ios` |
| `language` | from `Locale.current` |
| `deviceId` | `prefixedSerialNumber` |

The `com.neoastro.android` value is intentional: Zupee's superapp gateways gate on package name and the Android value is the one allow-listed for this LOB. **Do not "fix" it to `com.neoastro.ios`** without a corresponding backend change.

---

## Authentication Flow

```
LoginView ──phone──▶ AuthService.requestOTP
                          │
                          ▼
OTPView ──otp──▶ AuthService.authenticate
                          │
              writes tokens + zupeeUserId to TokenStore
                          │
                          ▼
              AuthViewModel.stage = .authenticated
                          │
                          ▼
                   MainTabView (5 tabs)
```

`AuthViewModel` is the single source of truth for `stage` (`.login | .otp | .authenticated`). `RootView` switches on it. On launch, `NeoAstroApp.init()` reads `TokenStore.isAuthenticated` and sets the initial stage.

---

## Tab Structure

`MainTabView` owns 5 tabs (`AppTab` enum) tinted with `AppTheme.pinkAccent`:

| Tab | Screen | Notes |
|-----|--------|-------|
| Home | `HomeView` | Astrologer list, hero banner, search bar, profile/chat navigation |
| Horoscope | `HoroscopeView` | Daily / weekly / monthly type picker; up to 7 retries on `pending` |
| Panchang | `PanchangView` | Tagged-union widgets: hero, sunMoon, kaal, chaughadiya, nakshatra |
| More | `MoreView` | Settings widgets, account, wallet, logout, delete |
| Search | (focuses Home search) | Routes back to Home via `HomeSearchCoordinator.requestFocusToken` |

---

## Service / Endpoint Map

| Service | Method | Endpoint | Notes |
|---------|--------|----------|-------|
| `AuthService` | `requestOTP` | `/v1.0/user/requestSignupOtp` | builds 23-field body |
| `AuthService` | `authenticate` | `/v1.0/auth/authenticateUser` | persists tokens on success |
| `AuthService` | (refresh) | `/v1.0/refreshToken` | invoked by `APIClient`, not callers |
| `ProfileService` | `viewProfile` | `/v1.0/profile/viewProfile` | |
| `ProfileService` | `getUserDetails` | `/v1.0/user/getUserDetails` | |
| `ProfileService` | `submit` | `/v1.0/profile/submit` | optional fields only |
| `ProfileService` | `deleteAccount` | `/v1.0/user/deleteUserAccount` | |
| `AstrologerService` | `listAll` / `listBest` / `search` | `/v1.0/astrologer/listAstrologers` | one endpoint, three shapes |
| `HoroscopeService` | `fetch` | `/v1.0/chat/getHoroscope` | 7 retries × 5 s on `pending` |
| `PanchangService` | `today` | `/v1.0/user/getPanchangDetails` | body carries `zuid` |
| `WalletService` | `screenData` | `/v1.0/wallet/getWalletScreenData` | |
| `WalletService` | `transactionHistory` | `/v1.0/wallet/transactionHistory/passbook` | paginated |
| `WalletService` | `createCheckoutOrder` | `/v1.0/payment/v2/checkoutOrder/create` | feeds Juspay sheet |
| `UserSettingsService` | `fetch` | `/v1.0/user/getUserSettings` | returns widget array |

---

## State Management Rules

- **`@Observable @MainActor final class`** is the only ViewModel shape used. Do not introduce `ObservableObject` / `@Published` / `@StateObject` / `EnvironmentObject` – they coexist poorly with `@Observable` and split the codebase.
- **No Combine.** Use `async`/`await` and `Task { }`. Do not `import Combine`.
- ViewModels are owned locally with `@State private var vm = FooViewModel()`. Pass them down with `.environment(vm)` only when a child needs to mutate parent state.
- All UI mutations must happen on `MainActor`. Network calls run on `URLSession`'s actor and hop back automatically – do **not** wrap with `DispatchQueue.main.async`.

---

## Build & Tooling

### `project.yml` (XcodeGen)

- Bundle ID: `varasol.MarathiCalendarPanchangam` (legacy; see "Known oddities").
- Deployment target: iOS 26.0.
- Team: `H5YRX72888`, automatic signing, `Apple Development` identity.
- iPhone-only (`TARGETED_DEVICE_FAMILY: "1"`), Mac Catalyst disabled.

### Regenerating the Xcode project

```bash
brew install xcodegen   # one-time
xcodegen generate       # rewrites NeoAstro.xcodeproj from project.yml
```

`NeoAstro.xcodeproj/project.pbxproj` is **generated**. Do not hand-edit it; change `project.yml` and re-run XcodeGen.

### Building from CLI

```bash
xcodebuild -project NeoAstro.xcodeproj \
           -scheme NeoAstro \
           -destination 'generic/platform=iOS Simulator' \
           build
```

---

## Logging

`AppLog` (`Networking/AppLog.swift`) is the only allowed logger. Categories:
`api`, `auth`, `home`, `search`, `account`, `wallet`, `horoscope`, `panchang`, `chat`.

Each call emits both a console line (with emoji prefix `ℹ️🔍⚠️❌`) and an `os.Logger` entry. Do not use `print()` or `NSLog` in app code; if you need a new category, add it to `AppLog.swift` rather than reusing one that doesn't fit.

---

## Persistence Surface

The only persistent storage is the Keychain via `TokenStore`. Everything else is fetched per-launch. There is **no offline cache, no Core Data, no SwiftData, no UserDefaults**. If you need to add caching, prefer in-memory state on the ViewModel until a real product requirement appears.

---

## Known Oddities (read before contributing)

1. **Bundle ID is legacy.** `varasol.MarathiCalendarPanchangam` is left over from a different app and is what App Store Connect / provisioning profiles are tied to. Don't change it casually – it requires coordinated provisioning + backend allow-list updates.
2. **`DeviceInfo.zupeeAppName == "com.neoastro.android"`** is intentional. Zupee's gateway only allow-lists certain package names per LOB; the iOS app reuses the Android one. Do not "correct" it.
3. **Build version string is hand-maintained:** `1.2512.07_ASTRO_IOS` and `512` in `DeviceInfo`. They feed analytics and gating. Keep them in sync with releases.
4. **iOS 26.0 deployment target** is intentional (year-numbered iOS). The app uses iOS 18+/26 features (`Tab` syntax, `@Observable`, `searchable` polish). Do not lower it without an audit.
5. **Three response envelope shapes** must all stay supported in `APIClient.send`. New endpoints will pick one of the three; do not drop the fall-throughs.
6. **`JuspayPaymentSheet.swift`** is a stub today – Juspay is *not* integrated as a real SDK. The wallet flow currently only fetches `clientAuthToken`; presenting the actual sheet is TODO.
7. **No tests, no CI, no lint config** committed yet. If you add SwiftLint/SwiftFormat, also add them to `project.yml` so XcodeGen wires them in.
8. **No localization.** All user-facing strings are hardcoded English. The `language` header is filled from `Locale.current` but the UI doesn't respect it.

---

## What This App Is Not

- **Not the astrologer/partner app.** That role is filled by `zupee-rn-astro-partner` in the parent monorepo.
- **Not a web client.** That is `neoastro` (Next.js) in the parent monorepo.
- **Not a backend.** It only consumes the Zupee superapp + NeoAstro APIs.

For backend / RN context (chat session id semantics, per-minute vs fixed-price flows, etc.), see the parent monorepo at `/Users/kamal.dixit/Desktop/neoastro-root`.
